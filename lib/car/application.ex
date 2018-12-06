defmodule Car.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @trigger_pin_name :trigger_pin
  @trigger_pin_num 18
  @input_pins [right: 23, left: 24, up: 17, down: 27]
  @output_pins [{@trigger_pin_name, @trigger_pin_num}]
  @left_motor {6, 13}
  # @right_motor {5, 26}

  use Application

  require Logger

  alias Car.{MotorDriver, SonicRangeControl, SonicRangeChecker}
  alias ElixirALE.GPIO

  def start(_type, _args) do
    Logger.warn("Starting Application...")

    opts = [strategy: :one_for_all, name: Car.Supervisor]

    Supervisor.start_link(motor_children(@left_motor), opts)
  end

  def motor_children({pin_1, pin_2}) do
    {:ok, pin_1_pid} = GPIO.start_link(
      pin_1,
      :output,
      name: gpio_pin_name(:left_motor, pin_1)
    )

    {:ok, pin_2_pid} = GPIO.start_link(
      pin_2,
      :output,
      name: gpio_pin_name(:right_motor, pin_2)
    )

    [
      {MotorDriver, %{side: :left, pin_pids: {pin_1_pid, pin_2_pid}}}
      # {MotorDriver, %{side: :right, pin_pid: pin_right_pid}}
    ]
  end

  def children do
    {input_pin_gpio_names, input_pin_gpio_specs} = input_pin_gpios()
    {output_pin_gpio_names, output_pin_gpio_specs} = output_pin_gpios()

    {
      sonic_range_control_names,
      sonic_range_control_specs
    } = sonic_range_controls()

    Logger.warn("Starting range controls: #{inspect sonic_range_control_names}...")
    Logger.warn("Starting gpio input pins: #{inspect input_pin_gpio_names}...")
    Logger.warn("Starting gpio output pins: #{inspect output_pin_gpio_names}...")

    sonic_range_control_specs ++
    input_pin_gpio_specs ++
    output_pin_gpio_specs ++
    [sonic_range_checker_spec()]
  end

  def sonic_range_checker_spec do
    args = [
      gpio_pin_name(@trigger_pin_name, @trigger_pin_num),
      Enum.map(@input_pins, fn {id, pin} -> {id, gpio_pin_name(id, pin)} end)
    ]

    Supervisor.child_spec(
      {SonicRangeChecker, args},
      id: :sonic_range_checker
    )
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

  def output_pin_gpios, do: create_pin_gpios(@output_pins, :output)
  def input_pin_gpios, do: create_pin_gpios(@input_pins, :input)

  defp create_pin_gpios(direction_pins, type) do
    Enum.reduce(direction_pins, {[], []}, fn ({id, pin}, {names, specs}) ->
      id = gpio_pin_name(id, pin)
      spec = %{
        id: id,
        start: {GPIO, :start_link, [pin, type, [name: id]]}
      }

      {[id | names], [spec | specs]}
    end)
  end

  def gpio_pin_name(id, pin), do: String.to_atom("gpio_#{pin}_#{id}")
end
