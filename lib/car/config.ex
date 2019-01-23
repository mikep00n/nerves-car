  defmodule Car.Config do

  alias Car.DutyCycle

  def speed_range do
    Enum.into(1..25, [])
  end

  def speed_range_max do
    Enum.max(speed_range())
  end

  def speed_range_min do
    Enum.min(speed_range())
  end

  def speed_range_off do
    0
  end

  def start_speed do
    div(speed_range_max(), 2)
  end

  def duty_cycle_max do
    255
  end

  def duty_cycle_min do
    50
  end

  def trigger_pin_num do
    18
  end

  def input_pins do
    [right: 24, left: 23, up: 17, down: 27]
  end

  def left_motor do
    {5, 6}
  end

  def right_motor do
    {13, 26}
  end

end
