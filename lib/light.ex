defmodule Light do
  use Application

  alias ElixirALE.GPIO
  require Logger

  @echo_input_pin 24
  @echo_trigger_pin 18

  @voltage_high 1
  @voltage_low 0
  @avg_count 7
  @retry_count 20

  @microsecond_divisor 58

  def start(_type, _args) do
    RingLogger.attach()
    {:ok, reader_pin_pid} = GPIO.start_link(@echo_input_pin, :input)
    {:ok, trigger_pin_pid} = GPIO.start_link(@echo_trigger_pin, :output)

    spawn(fn -> find_range(reader_pin_pid, trigger_pin_pid) end)

    {:ok, self()}
  end

  def find_range(reader_pin_pid, trigger_pin_pid) do
    Logger.info("Range over #{@avg_count} measures #{find_and_avg_range(trigger_pin_pid, reader_pin_pid)}cm")

    :timer.sleep(:timer.seconds(5))

    find_range(reader_pin_pid, trigger_pin_pid)
  end

  defp find_and_avg_range(trigger_pin_pid, reader_pin_pid) do
    avg_nums = 1..@avg_count
      |> Enum.map(fn _ ->
        GPIO.write(trigger_pin_pid, @voltage_high)
        GPIO.write(trigger_pin_pid, @voltage_low)

        case time_between_echo(reader_pin_pid) do
          0 -> 0
          microseconds -> microseconds / @microsecond_divisor / 2
        end
      end)
      |> Enum.reject(&(&1 === 0))
      # |> Enum.map(&(&1 / 2))

    Logger.info("Took #{@avg_count} measures: #{inspect avg_nums}")

    avg_nums
      |> Enum.sum
      |> Kernel./(safe_divisor(length(avg_nums)))
  end

  def safe_divisor(0), do: 1
  def safe_divisor(n), do: n

  def round_num(n) when is_float(n), do: trunc(Float.round(n))
  def round_num(n) when is_integer(n), do: n

  def time_between_echo(reader_pin_pid, start_time \\ NaiveDateTime.utc_now(), retry_count \\ 0) do
    if retry_count < @retry_count do
      case GPIO.read(reader_pin_pid) do
        0 -> time_between_echo(reader_pin_pid, start_time, retry_count + 1)
        1 -> save_when_returns_0(reader_pin_pid, start_time)
        _ -> raise RuntimeError, "Error reading pin"
      end
    else
      0
    end
  end

  def save_when_returns_0(reader_pin_pid, start_time, retry \\ 0) do
    cond do
      retry > @retry_count ->
        Logger.info("Unable to read echo return")

        0

      GPIO.read(reader_pin_pid) === 1 ->
        save_when_returns_0(reader_pin_pid, start_time, retry + 1)

      GPIO.read(reader_pin_pid) === 0 ->
        NaiveDateTime.diff(NaiveDateTime.utc_now(), start_time, :microseconds)
    end
  end
end
