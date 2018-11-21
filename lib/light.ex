defmodule Light do
  use Application

  alias ElixirALE.GPIO
  require Logger

  @on 1
  @off 2

  def start(_type, _args) do
    RingLogger.attach()
    Logger.info("Application is starting")
    {:ok, pid} = GPIO.start_link(18, :output)

    spawn(fn -> blink_list_forever(pid) end)

    {:ok, self()}
  end

  def blink_list_forever(pid) do
    GPIO.write(pid, @on)
    :timer.sleep(:timer.second(5))
    GPIO.write(pid, @off)
    :timer.sleep(:timer.second(5))
    blink_list_forever()
  end
end
