defmodule Light do

  require Logger

  alias Nerves.Leds

  def start(_type, _args) do
    [led] = Application.get_env(:light, :led_list)
    Logger.debug("list of leds to blink is #{inspect(led)}")
    spawn(fn -> blink_list_forever(led) end)
    {:ok, self()}
  end

  def blink_list_forever(led) do
    Leds.set([{led, true}])
    :timer.sleep(:timer.seconds(10))
    Leds.set([{led, false}])
    :timer.sleep(:timer.seconds(4))
    blink_list_forever(led)
  end

end
