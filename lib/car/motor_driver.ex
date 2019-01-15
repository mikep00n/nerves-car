#  in general, it’s easier to think of as either duty cycle increasing or frequency increases to increase the duty_cycle of the motor.
# (Pulse width is directly related to duty cycle, so if you decide to increase the width of a pulse, you are just altering the duty cycle.)

# in every case duty cycle is a comparison of “on” versus “off.”

# If you take the duty cycle and multiply it by the high voltage level (which is a
# digital “on” or “1” state as far as the MCU is concerned), you will get the average voltage level that the motor is seeing at that moment.


defmodule Car.MotorDriver do
  use GenServer

  require Logger

  alias Car.{MotorDriver, PinControl}

  @type start_config :: %{side: atom, pins: {integer, integer}}
  @type direction :: :forward | :reverse | :off
  @type side :: :left | :right
  @type state :: %{
    side: atom,
    pins: {integer, integer},
    direction: direction,
    speed: integer
  }

  @speed_range Enum.into(1..25, [])
  @speed_range_max Enum.max(@speed_range)
  @start_speed div(@speed_range_max, 2)

  @spec start_link(side, {pid, pid}) :: {:ok, pid}
  def start_link(side, pins) do
    Logger.warn("Starting #{side} MotorDriver")

    GenServer.start_link(
      MotorDriver,
      %{side: side, pins: pins},
      name: motor_driver_name(side)
    )
  end

  @spec motor_driver_name(atom) :: String.t
  def motor_driver_name(side), do: String.to_atom("motor_driver_#{side}")

  def init(config) do
    state = Map.merge(config, %{direction: :off, speed: @start_speed})

    Logger.warn("Started #{config.side} MotorDriver")

    # Process.send_after(self(), :test, :timer.seconds(5))

    {:ok, state}
  end

  # API

  @spec turn_off(atom) :: {:ok, state}
  def turn_off(side) do
    GenServer.call(motor_driver_name(side), :switch_voltage_off)
  end

  @spec change_direction(atom, direction) :: {:ok, state}
  def change_direction(side, direction) do
    GenServer.call(motor_driver_name(side), {:change_direction, direction})
  end

  @spec change_speed(atom, integer) :: {:ok, state}
  def change_speed(side, speed) do
    GenServer.call(motor_driver_name(side), {:change_speed, speed})
  end

  # Server
  def handle_call({:change_direction, direction}, _from, state) do
    Logger.warn "Changing #{state.side} motor direction to #{direction}"

    reply_with_voltage_change(state, direction)
  end

  def handle_call(:turn_off, _from, state) do
    Logger.warn "Turning off #{state.side} motor"

    reply_with_voltage_change(state, :off)
  end

  def handle_call({:change_speed, new_speed}, _from, state) do
    Logger.warn "Changing #{state.side} motor speed from #{state.speed} to #{new_speed}"

    with :ok <- verify_speed_range(new_speed),
         {:ok, new_state} <- change_pulse(state, new_speed) do
      {:reply, :ok, new_state}
    else
      e -> {:reply, e, state}
    end
  end

  defp verify_speed_range(speed) do
    if Enum.member?(@speed_range, speed) do
      :ok
    else
      {:error, %{
        code: :out_of_range,
        message: "speed is out of range",
        details: %{
          speed: speed,
          speed_range: @speed_range
        }
      }}
    end
  end

  defp reply_with_voltage_change(state, direction) do
    with {:ok, new_state} <- set_current_direction(state, direction) do
      {:reply, :ok, new_state}
    else
      e -> {:reply, e, state}
    end
  end

  defp set_current_direction(
    %{
      direction: old_direction,
      speed: speed
    } = state,
    new_direction
  ) do
    if old_direction === new_direction do
      {:error, %{
        code: :same_voltage,
        message: "voltage is already set for #{new_direction}",
        details: %{
          state: state,
          new_direction: new_direction
        }
      }}
    else
      Logger.warn "Changed #{state.side} Motor Direction to #{new_direction}"

      change_pulse(%{state | direction: new_direction}, speed)
    end
  end

  defp change_pulse(%{direction: direction, pins: {pin_1, pin_2}} = state, speed) do
    case direction do
      :forward -> toggle_pulse_width(state, pin_1, pin_2, speed)
      :reverse -> toggle_pulse_width(state, pin_2, pin_1, speed)
      :off -> toggle_pulse_width_off(state)
    end
  end

  @spec toggle_pulse_width(state, integer, integer, integer) :: {:ok, state}
  defp toggle_pulse_width(state, on_pin, off_pin, speed) do
    with :ok <- PinControl.pulse_width_pin(on_pin, speed, @speed_range_max),
         :ok <- PinControl.turn_off_pin(off_pin) do
      {:ok, %{state | speed: speed}}
    end
  end

  defp toggle_pulse_width_off(%{pins: {pin_1, pin_2}} = state) do
    with :ok <- PinControl.turn_off_pin(pin_1),
         :ok <- PinControl.turn_off_pin(pin_2) do
      {:ok, state}
    end
  end
end
