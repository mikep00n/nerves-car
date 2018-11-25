defmodule Car.SonicRangeControl do
  use GenServer

  require Logger
  alias ElixirALE.GPIO

  @type position :: :left | :right | :up | :down

  @retry_count 20
  @microsecond_divisor 58

  # API

  @spec start_link(position) :: {:ok, pid}
  def start_link(position) do
    GenServer.start_link(Car.SonicRangeControl, position, name: name(position))
  end

  def name(position) do
    String.to_atom("control_server_#{position}")
  end

  def init(position) do
    Logger.warn("SonicRangeControl #{name(position)} started")

    {:ok, %{position: position}}
  end

  @spec find_echo_range(position, pid) :: integer
  def find_echo_range(position, reader_pin_pid) do
    GenServer.call(name(position), {:find_range, reader_pin_pid})
  end

  # Server

  def handle_call({:find_range, reader_pin_pid}, _from, state) do
    {:reply, find_range(reader_pin_pid), state}
  end

  defp find_range(reader_pin_pid) do

    case time_between_echo(reader_pin_pid) do
      0 -> 0
      microseconds -> microseconds / @microsecond_divisor / 2
    end

  end

  def time_between_echo(reader_pin_pid, start_time \\ NaiveDateTime.utc_now(), retry_count \\ 0) do
    if retry_count < @retry_count do
      case GPIO.read(reader_pin_pid) do
        0 -> time_between_echo(reader_pin_pid, start_time, retry_count + 1)
        1 -> save_when_returns_0(reader_pin_pid, start_time)
        _ -> raise RuntimeError, "Error reading pin"
      end
    else
      Logger.warn "Maxed out retries waiting for 0 #{reader_pin_pid}"
      0
    end
  end

  def save_when_returns_0(reader_pin_pid, start_time, retry \\ 0) do
    cond do
      retry > @retry_count ->
      Logger.warn "Maxed out retries waiting for 1 #{reader_pin_pid}"

        0

      GPIO.read(reader_pin_pid) === 1 ->
        save_when_returns_0(reader_pin_pid, start_time, retry + 1)

      GPIO.read(reader_pin_pid) === 0 ->
        NaiveDateTime.diff(NaiveDateTime.utc_now(), start_time, :microseconds)
    end
  end

end
