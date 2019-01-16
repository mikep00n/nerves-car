defmodule Car.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  alias Car.{
    Config,
    MotorDriver, SonicRangeControl,
    SonicRangeChecker, PinControl
  }

  def start(_type, _args) do
    Logger.warn("Starting Application...")

    opts = [strategy: :one_for_all, name: Car.Supervisor]

    Supervisor.start_link(range_finder_children(), opts)
  end

  def motor_children do
    [
      motor_child(:left, Config.left_motor()),
      motor_child(:right, Config.right_motor())
    ]
  end

  def motor_child(side, {pin_1, pin_2}) do
    PinControl.turn_off_pin([pin_1, pin_2])

    %{
      id: String.to_atom("motor_driver_#{side}"),
      start: {MotorDriver, :start_link, [side, {pin_1, pin_2}]}
    }
  end

  def range_finder_children do
    {
      sonic_range_control_names,
      sonic_range_control_specs
    } = sonic_range_controls()

    Logger.warn("Starting range controls: #{inspect sonic_range_control_names}...")

    [%{
      id: :sonic_range_checker,
      start: {SonicRangeChecker, :start_link, [
        Config.trigger_pin_num(),
        Config.input_pins()
      ]}
    } | sonic_range_control_specs]
  end

  def sonic_range_controls do
    Enum.reduce(Config.input_pins(), {[], []}, fn (
      {direction, _},
      {names, specs}
    ) ->
      server_name = SonicRangeControl.server_name(direction)

      spec = %{
        id: server_name,
        start: {
          SonicRangeControl,
          :start_link,
          [direction]
        }
      }

      {[server_name | names], [spec | specs]}
    end)
  end
end
