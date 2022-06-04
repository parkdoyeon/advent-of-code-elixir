defmodule AdventOfCodeElixir.DaySeven.Elf do
  use GenServer

  alias AdventOfCodeElixir.DaySeven.Dashboard

  def start_work() do
    IO.inspect("Elf start a job")
    GenServer.start_link(__MODULE__, nil)
  end

  def now(pid) do
    GenServer.call(pid, :now)
  end

  def work(pid, job, time) do
    GenServer.cast(pid, {:work, job, time})
  end

  @impl true
  @spec init(any) :: {:ok, any}
  def init(nil), do: {:ok, {:idle, 0}}
  def init(job), do: {:ok, {job, 0}}

  defp time_taken(job) do
    :binary.first(job) - 4
  end

  @impl true
  def handle_call(:now, _from, state) do
    IO.inspect(message: "Asked status", pid: self())
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:work, job, latest}, {_, from_time}) do
    latest = if latest > from_time do latest else from_time end
    IO.inspect("Elf starts a job " <> job)
    job_time = time_taken(job)
    :timer.sleep(job_time * 100)
    Dashboard.report_done(job, latest + job_time, self())
    {:noreply, {:idle, latest + job_time}}
  end
end
