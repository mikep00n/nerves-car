defmodule Car.MotorController do
  use GenServer

  require Logger

  alias Car.{Config, PinControl, MotorDriver}

  @left :left
  @right :right
  @type state :: %{
    side: atom,
    speed: integer,
    degree: integer
  }

  # Genserver

  def start_link(speed \\ 0, direction \\ :forward, degree \\ 90) do
    Logger.warn("Starting MotorController")

    GenServer.start_link(
      MotorController,
      %{
        speed: speed,
        direction: direction,
        degree: degree,
        motor_controller_name:
        motor_controller_name
      },
      name: motor_controller_name(),
      motor_controller_name:
      motor_controller_name
    )
  end

  @spec motor_controller_name() :: String.t
  def motor_controller_name, do: :motor_controller

  def init(state) do
    {:ok, reset_motor_settings(state)}
  end

  # Turning functions
  def change_speed({:change_speed, speed}, state) do
    GenServer.call(motor_controller(), {:change_speed, speed}, state)
  end

   # Going straight

  def change_direction(direction) do
    GenServer.call(motor_controller(), {:change_direction, direction}, state)
  end

  def turn_degrees(degrees) do
    GenServer.call(motor_controller(), {:turn_degrees, degrees}, state)
  end

   # Server
  def handle_call({:change_direction, direction}, _from, state) do
    with :ok <- MotorDriver.change_direction(@right, direction),
         :ok <- MotorDriver.change_direction(@left, direction) do
      {:reply, :ok, %{state | direction: direction}}
    else
      {:error, _} = e -> {:reply, e, state}
    end
  end

  def handle_call({:change_speed, speed},  _from, state) do
    with :ok <- MotorDriver.change_speed(@left, speed),
         :ok <- MotorDriver.change_speed(@right, speed) do
      {:reply, :ok, %{state | speed: speed}}
    else
      {:error, _} = e -> {:reply, e, state}
    end
  end

  def handle_call({:turn_degrees, degrees},  _from, state) do
    with :ok <- turn_motors(degrees, state) do
      {:reply, :ok, %{state | degrees: degrees}}
    else
      {:error, _} = e -> {:reply, e, state}
    end
  end

  defp turn_motors(degrees, state) do
-    cond do
      degrees > 180 or degrees < 0 -> {:error, "Degree is out of range"}

      degrees === 90 ->
        reset_motor_settings()
        :ok

      degrees > 90 ->
        turn_direction(@right, @left, degrees - 90, state.speed)
        :ok

      degrees < 90 ->
        turn_direction(@left, @right, degrees, state.speed)
        :ok
    end
  end

  def turn_direction(turn_direction, opposite_direction, degrees, current_speed) do
    percentage_of_turn = div(degrees, 90)

    with :ok <- MotorDriver.change_speed(turn_direction, current_speed * percentage_of_turn) do
      MotorDriver.change_speed(opposite_direction, current_speed)
    end
  end

  defp reset_motor_settings(state) do
    Task.run(fn ->
      MotorDriver.change_speed(@left, state.speed)
      MotorDriver.change_speed(@right, state.speed)
      MotorDriver.change_direction(@left, state.direction)
      MotorDriver.change_direction(@right, state.direction)
    end)

    state
  end
end
