defmodule Car.SonicRangeControl do
  use GenServer

  require Logger

  alias Car.PinControl

  @type position :: :left | :right | :up | :down

  @retry_count 60
  @microsecond_divisor 0.0344

  # API
  @spec start_link(position) :: {:ok, pid}
  def start_link(position) do
    GenServer.start_link(Car.SonicRangeControl, position, [name: server_name(position)])
  end

  @spec start_link(position, Keyword.t) :: {:ok, pid}
  def start_link(position, opts) do
    GenServer.start_link(Car.SonicRangeControl, position, opts)
  end

  def server_name(position) do
    String.to_atom("control_server_#{position}")
  end

  def init(position) do
    Logger.warn("SonicRangeControl #{server_name(position)} started")

    {:ok, %{position: position}}
  end

  @spec find_echo_range(position, integer) :: integer
  def find_echo_range(position, reader_pin) do
    GenServer.call(server_name(position), {:find_range, reader_pin})
  end

  # Server

  def handle_call({:find_range, reader_pin}, _from, state) do
    {:reply, find_range(reader_pin), state}
  end

  defp find_range(reader_pin) do
    case time_between_echo(reader_pin) do
      0 -> 0
      microseconds -> (microseconds / 2) * @microsecond_divisor
    end
  end

  def time_between_echo(reader_pin, start_time \\ NaiveDateTime.utc_now(), retry_count \\ 0) do
    if retry_count < @retry_count do
      case PinControl.read_pin(reader_pin) do
        nil -> time_between_echo(reader_pin, start_time, retry_count + 1)
        {:ok, 0} -> time_between_echo(reader_pin, start_time, retry_count + 1)
        {:ok, 1} -> save_when_returns_0(reader_pin, start_time)
        e -> raise RuntimeError, "Error reading pin #{inspect e}"
      end
    else
      Logger.warn "Maxed out retries waiting for 0 #{reader_pin}"
      0
    end
  end

  def save_when_returns_0(reader_pin, start_time, retry \\ 0) do
    cond do
      retry > @retry_count ->
        Logger.warn "Maxed out retries waiting for 1 #{reader_pin}"

        0

      PinControl.read_pin(reader_pin) === {:ok, 1} ->
        save_when_returns_0(reader_pin, start_time, retry + 1)

      PinControl.read_pin(reader_pin) === {:ok, 0} ->
        NaiveDateTime.diff(NaiveDateTime.utc_now(), start_time, :microseconds)
    end
  end

end
