defmodule Car.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @trigger_pin_name :trigger_pin
  @trigger_pin_num 19
  @input_pins [down: 24] # , left: 15, right: 13, up: 23]
  @pins [{@trigger_pin_name, @trigger_pin_num} | @input_pins]

  use Application

  require Logger

  alias Car.{SonicRangeControl, SonicRangeChecker}
  alias ElixirALE.GPIO

  def start(_type, _args) do
    Logger.warn("Starting Application...")

    opts = [strategy: :one_for_all, name: Car.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  def children do
    {pin_gpio_names, pin_gpio_specs} = pin_gpios()
    {
      sonic_range_control_names,
      sonic_range_control_specs
    } = sonic_range_controls()

    Logger.warn("Starting range controls: #{inspect sonic_range_control_names}...")
    Logger.warn("Starting gpio pins: #{inspect pin_gpio_names}...")

    sonic_range_control_specs ++ pin_gpio_specs ++ [sonic_range_checker_spec()]
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
      name = SonicRangeControl.name(direction)
      spec = Supervisor.child_spec(
        {SonicRangeControl, direction},
        id: SonicRangeControl.name(direction)
      )

      {[name | names], [spec | specs]}
    end)
  end

  def pin_gpios do
    Enum.reduce(@pins, {[], []}, fn ({id, pin}, {names, specs}) ->
      id = gpio_pin_name(id, pin)
      spec = Supervisor.child_spec(
        {GPIO, [pin, :input, [name: id]]},
        id: id
      )


      {[id | names], [spec | specs]}
    end)
  end

  def gpio_pin_name(id, pin), do: String.to_atom("gpio_#{pin}_#{id}")
end
