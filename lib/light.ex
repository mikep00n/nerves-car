defmodule Light do
  use Application

  alias ElixirALE.GPIO
  require Logger

  @echo_input_pins [left: 15, right: 13, up: 23, down: 24]
  @echo_trigger_pin 18

  @voltage_high 1
  @voltage_low 0

  def start(_type, _args) do
    RingLogger.attach()

    reader_pin_directions = Enum.map(@echo_input_pins, fn {direction, pin} ->
      {:ok, reader_pin_pid} = GPIO.start_link(pin, :input)

      {direction, reader_pin_pid}
    end)

    {:ok, trigger_pin_pid} = GPIO.start_link(@echo_trigger_pin, :output)

    find_range(trigger_pin_pid, reader_pin_directions)

    {:ok, self()}
  end

  def find_range(trigger_pin_pid, reader_pin_directions) do
    directions = find_echo_range(trigger_pin_pid, reader_pin_directions)

    Logger.info("Range Result: #{inspect directions}")

    :timer.sleep(:timer.seconds(5))

    find_range(trigger_pin_pid, reader_pin_directions)
  end

  def find_echo_range(trigger_pin_pid, reader_pin_directions) do
    trigger(trigger_pin_pid)

    reader_pin_directions
      |> Task.async_stream(fn {direction, reader_pin_pid} ->
        {
          direction,
          Light.SonicRangeControl.find_echo_range(direction, reader_pin_pid)
        }
      end)
      |> Enum.reduce(fn {:ok, {direction, range}} ->
        {direction, range}
      end)
  end

  def trigger(trigger_pin_pid) do
    GPIO.write(trigger_pin_pid, @voltage_high)
    GPIO.write(trigger_pin_pid, @voltage_low)
  end
end

