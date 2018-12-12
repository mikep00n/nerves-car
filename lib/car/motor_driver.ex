defmodule Car.MotorDriver do
  use GenServer

  require Logger

  alias ElixirALE.GPIO
  alias Car.MotorDriver

  @type start_config :: %{side: atom, pin_pids: {pid, pid}}
  @type direction :: :forward | :reverse | :off
  @type side :: :left | :right
  @type state :: %{
    side: atom,
    pin_pids: {pid, pid},
    direction: direction,
    speed: 10
  }

  @voltage_high 1
  @voltage_low 0

  @spec start_link(side, {pid, pid}) :: {:ok, pid}
  def start_link(side, pin_pids) do
    Logger.warn("Starting #{side} MotorDriver")

    GenServer.start_link(
      MotorDriver,
      %{side: side, pin_pids: pin_pids},
      name: motor_driver_name(side)
    )
  end

  @spec motor_driver_name(atom) :: String.t
  def motor_driver_name(side), do: String.to_atom("motor_driver_#{side}")

  def init(config) do
    state = Map.merge(config, %{direction: :off, speed: 10})

    Logger.warn("Started #{config.side} MotorDriver")

    # Process.send_after(self(), :test, :timer.seconds(5))

    {:ok, state}
  end

  # API

  @spec switch_voltage_off(atom) :: {:ok, state}
  def switch_voltage_off(side) do
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

  def handle_call(:switch_voltage_off, _from, state) do
    Logger.warn "Turning off #{state.side} motor"

    reply_with_voltage_change(state, :off)
  end

  def handle_call({:change_speed, speed}, _from, state) do
    Logger.warn "Changing #{state.side} motor speed from #{state.speed} to #{speed}"


  end

  # def handle_info(:test, state) do
  #   direction = case state.direction do
  #     :off -> :forward
  #     :forward -> :reverse
  #     :reverse -> :forward
  #   end
  #   Logger.warn("TEST CALLED: OLD_DIRECTION: #{state.direction}\nNEW_DIRECTION: #{direction}")

  #   {:ok, new_state} = set_current_voltage(state, direction)

  #   Logger.warn("SET VOLTAGE NEW STATE #{inspect new_state}")

  #   Process.send_after(self(), :test, :timer.seconds(2))

  #   {:noreply, new_state}
  # end

  defp reply_with_voltage_change(state, direction) do
    with {:ok, new_state} <- set_current_voltage(state, direction) do
      {:reply, :ok, new_state}
    else
      e -> {:reply, e, state}
    end
  end

  defp set_current_voltage(
    %{
      pin_pids: {gpio_1, gpio_2},
      direction: old_direction
    } = state,
    new_direction
  ) do
    cond do
      old_direction === new_direction -> {:error, %{
        code: :same_voltage,
        message: "voltage is already set for #{new_direction}"
      }}

      new_direction === :off ->
        GPIO.write(gpio_1, @voltage_low)
        GPIO.write(gpio_2, @voltage_low)

      new_direction === :forward ->
        GPIO.write(gpio_1, @voltage_high)
        GPIO.write(gpio_2, @voltage_low)


      new_direction === :reverse ->
        GPIO.write(gpio_2, @voltage_high)
        GPIO.write(gpio_1, @voltage_low)
    end

    Logger.warn "Changed #{state.side} Motor Direction to #{new_direction}"

    {:ok, %{state | direction: new_direction}}
  end
end
