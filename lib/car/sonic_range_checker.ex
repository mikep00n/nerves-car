defmodule Car.SonicRangeChecker do
  use Task

  require Logger

  alias ElixirALE.GPIO

  @voltage_high 1
  @voltage_low 0

  def start_link([trigger_pin_name, reader_pin_direction_gpio_pids]) do
    Logger.warn("Starting SonicRangeChecker...")

    Task.start_link(Car.SonicRangeChecker, :find_range, [
      trigger_pin_name,
      reader_pin_direction_gpio_pids
    ])
  end

  def find_range(trigger_pin_pid, reader_pin_direction_gpio_pids) do
    directions = find_echo_range(trigger_pin_pid, reader_pin_direction_gpio_pids)

    Logger.warn("Range Result: #{inspect directions}")

    :timer.sleep(:timer.seconds(5))

    find_range(trigger_pin_pid, reader_pin_direction_gpio_pids)
  end

  def find_echo_range(trigger_pin_pid, reader_pin_direction_gpio_pids) do
    trigger(trigger_pin_pid)

    reader_pin_direction_gpio_pids
      |> Task.async_stream(fn {direction, reader_pin_pid} ->
        {
          direction,
          Car.SonicRangeControl.find_echo_range(direction, reader_pin_pid)
        }
      end)
      |> Enum.into(%{}, fn {:ok, {direction, range}} ->
        {direction, range}
      end)
  end

  def trigger(trigger_pin_pid) do
    GPIO.write(trigger_pin_pid, @voltage_high)
    GPIO.write(trigger_pin_pid, @voltage_low)
  end
end
