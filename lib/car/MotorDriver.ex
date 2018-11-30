defmodule MotorDriver do
  use Genserver

  :left = [left: 5]

  start_link do
    GenServer.start_link(MotorDriver, :left , name: MotorDriver)
  end

  def init(:left) do
    {:ok, %{current_direction: :left}}
  end

  def switch_voltage_left do
    GenServer.cast(:switch_voltage_right)
  end

  def switch_voltage_right do
    Genserver.cast(:switch_voltage_left)
  end

  def handle_cast(:switch_voltage_right, state)
    new_state = @left
    cond
      state == @right ->
        {:noreply, new_state}
      state == @left ->
        {:stop, IO.puts("The state is still right, needs to be left"), state}
    end
  end

  def handle_cast(:switch_voltage_left, state)
    new_state = @right
    cond
      state == @right ->
        {:noreply, new_state}
      state == @left ->
        {:stop, IO.puts("The state is still left, needs to be right"), state}
  end

end
