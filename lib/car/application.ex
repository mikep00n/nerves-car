defmodule Car.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @trigger_pin_num 18
  @input_pins [right: 24, left: 23, up: 17, down: 27]
  @left_motor {5, 6}
  @right_motor {13, 26}

  use Application

  require Logger

  alias Car.{MotorDriver, SonicRangeControl, SonicRangeChecker, PinControl}

  def start(_type, _args) do
    Logger.warn("Starting Application...")

    opts = [strategy: :one_for_all, name: Car.Supervisor]

    Supervisor.start_link(range_finder_children(), opts)
  end

  def motor_children do
    [
      motor_child(:left, @left_motor),
      motor_child(:right, @right_motor)
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
        @trigger_pin_num,
        @input_pins
      ]}
    } | sonic_range_control_specs]
  end

  def sonic_range_controls do
    Enum.reduce(@input_pins, {[], []}, fn ({direction, _}, {names, specs}) ->
      server_name = SonicRangeControl.server_name(direction)

      spec = %{
        id: server_name,
        start: {
          SonicRangeControl,
          :start_link,
          [direction, [name: server_name]]
        }
      }

      {[server_name | names], [spec | specs]}
    end)
  end
end
