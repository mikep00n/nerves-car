defmodule Car.SonicRangeChecker do
  use Task

  require Logger

  def start_link(trigger_pin, direction_pin_map) do
    Logger.warn("Starting SonicRangeChecker...")

    Task.start_link(Car.SonicRangeChecker, :find_range, [
      trigger_pin,
      direction_pin_map
    ])
  end

  def find_range(trigger_pin, direction_pin_map) do
    directions = find_echo_range(trigger_pin, direction_pin_map)

    Logger.warn("Range Result: #{inspect directions}")

    Process.sleep(:timer.seconds(5))

    find_range(trigger_pin, direction_pin_map)
  end

  def find_echo_range(trigger_pin, direction_pin_map) do
    trigger(trigger_pin)

    direction_pin_map
      |> Task.async_stream(fn {direction, reader_pin} ->
        {
          direction,
          Car.SonicRangeControl.find_echo_range(direction, reader_pin)
        }
      end)
      |> Enum.into(%{}, fn {:ok, {direction, range}} ->
        {direction, range}
      end)
  end

  def trigger(trigger_pin) do
    Car.PinControl.pulse_pin(trigger_pin)
  end
end
