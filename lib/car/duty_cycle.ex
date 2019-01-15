defmodule Car.DutyCycle do
  @duty_cycle_max 255
  @duty_cycle_min 50

  @spec for_speed(integer, integer) :: integer
  def for_speed(current_speed, speed_max) do
    (current_speed / speed_max * (@duty_cycle_max - @duty_cycle_min))
      |> float_to_integer
      |> clamp_to_min
  end

  defp clamp_to_min(number) when number < @duty_cycle_min, do: @duty_cycle_min
  defp clamp_to_min(number), do: number

  defp float_to_integer(float) do
    {integer, _rem} = float
      |> Float.round
      |> Float.to_string
      |> Integer.parse

    integer
  end
end
