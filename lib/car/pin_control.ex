defmodule Car.PinControl do
  alias Car.DutyCycle
  alias Pigpiox.{GPIO, Pwm}

  @off 0
  @on 1

  def pulse_width_pin(pin_number, speed, speed_max) do
    Pwm.gpio_pwm(pin_number, DutyCycle.for_speed(speed, speed_max))
  end

  def pulse_pin(pin_number) do
    with :ok <- turn_on_pin(pin_number) do
      turn_off_pin(pin_number)
    end
  end

  def turn_on_pin(pin_numbers) when is_list(pin_numbers) do
    Enum.map(pin_numbers, &turn_on_pin/1)
  end

  def turn_on_pin(pin_number) do
    with :ok <- set_output(pin_number) do
      GPIO.write(pin_number, @on)
    end
  end

  def turn_off_pin(pin_numbers) when is_list(pin_numbers) do
    Enum.map(pin_numbers, &turn_off_pin/1)
  end

  def turn_off_pin(pin_number) do
    with :ok <- set_output(pin_number) do
      GPIO.write(pin_number, @off)
    end
  end

  def read_pin(pin_number) do
    with :ok <- set_input(pin_number) do
      GPIO.read(pin_number)
    end
  end

  defp set_output(pin_number) do
    if GPIO.get_mode(pin_number) === {:ok, :output} do
      :ok
    else
      GPIO.set_mode(pin_number, :output)
    end
  end

  defp set_input(pin_number) do
    if GPIO.get_mode(pin_number) === {:ok, :input} do
      :ok
    else
      GPIO.set_mode(pin_number, :input)
    end
  end
end
