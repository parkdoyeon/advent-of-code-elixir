defmodule AdventOfCodeElixir.DaySeven.Dashboard do
  use GenServer
  require Logger

  alias AdventOfCodeElixir.DaySeven.Elf

  # == server ==

  def start(elf_count) do
    {:ok, pid} = GenServer.start_link(__MODULE__, nil, name: :dashboard)
    GenServer.call(pid, {:start_work, elf_count})
  end

  def report_done(job, time, elf) do
    GenServer.whereis(:dashboard)
    |> GenServer.cast({:done, job, time, elf})
  end

  def current_elves(job, elf) do
    :dashboard
    |> GenServer.whereis()
    |> GenServer.cast({:done, job, elf})
  end

  # == client ==

  defp parse(sentence, acc) do
    [[_original, before, next]] =
      Regex.scan(~r/Step (.*) must be finished before step (.*) can begin./, sentence)

    Map.update(acc, next, MapSet.new(), &MapSet.put(&1, before))
  end

  @spec set_dashboard :: %{done: [], jobs: map, todos: MapSet.t(), elves: [], idle_elves: [], latest: 0}
  defp set_dashboard() do
    jobs_init =
      Enum.to_list(?A..?Z)
      |> Enum.map(fn n -> <<n>> end)
      |> Map.new(fn a -> {a, MapSet.new()} end)

    jobs =
      Path.expand("inputs/day7.txt")
      |> File.read!()
      |> String.split("\n")
      |> Enum.reduce(jobs_init, &parse(&1, &2))

    %{
      todos:
        jobs
        |> Map.filter(fn {_k, v} -> MapSet.size(v) == 0 end)
        |> Map.keys()
        |> MapSet.new(),
      jobs: Map.reject(jobs, fn {_k, v} -> MapSet.size(v) == 0 end),
      elves: [],
      done: [],
      idle_elves: [],
      latest: 0
    }
  end

  @impl true
  @spec init(any) :: {:ok, any}
  def init(_initial_state) do
    {:ok, set_dashboard()}
  end

  defp distribute_work([], _todos, _latest), do: {[], [], []}
  defp distribute_work(idle_elves, [], _latest), do: {[], [], idle_elves}

  defp distribute_work(idle_elves, todos, latest) do
    able_todos = Enum.take(Enum.sort(todos), length(idle_elves))
    Logger.info("distribute work", able_todos: able_todos, idle_elves: idle_elves)

    {started, able_todos} =
      Enum.reduce(idle_elves, {[], able_todos}, fn elf, {started, todos} ->
        Logger.info(started: started, todos: todos)
        {able_todo, todos} = List.pop_at(todos, 0)

        if able_todo != nil do
          :ok = Elf.work(elf, able_todo, latest)
          {[able_todo | started], todos}
        else
          {started, todos}
        end
      end)

    {started, able_todos, Enum.slice(idle_elves, length(started)..length(idle_elves))}
  end

  @impl true
  def handle_call({:start_work, elf_count}, _from, %{todos: todos} = dashboard) do
    Logger.info("Let #{elf_count} elves work!")

    elves =
      Enum.map(1..elf_count, fn _ ->
        {:ok, pid} = Elf.start_work()
        pid
      end)

    {started, _able_todos, idle_elves} = distribute_work(elves, todos, dashboard.latest)

    {:reply, elves,
     dashboard
     |> Map.put(:elves, elves)
     |> Map.put(:todos, MapSet.difference(todos, MapSet.new(started)))
     |> Map.put(:idle_elves, idle_elves)}
  end

  @impl true
  def handle_cast({:done, done_job, time, done_elf}, dashboard) do
    latest = if dashboard.latest > time do dashboard.latest else time end
    Logger.info("Elf finished a job #{done_job}, time #{latest}")

    updated_dashboard =
      dashboard
      |> Map.update(:done, [], fn val ->
        [done_job | val]
      end)
      |> Map.update(:jobs, %{}, fn jobs ->
        Enum.into(jobs, %{}, fn {k, v} ->
          if done_job in v do
            {k, MapSet.delete(v, done_job)}
          else
            {k, v}
          end
        end)
      end)

    new_todo =
      updated_dashboard.jobs
      |> Map.filter(fn {_k, v} -> MapSet.size(v) == 0 end)
      |> Map.keys()
      |> Enum.concat(updated_dashboard.todos)
      |> MapSet.new()

    Logger.info(idle_elves: dashboard.idle_elves)

    {started, _able_todos, idle_elves} =
      distribute_work([done_elf | dashboard.idle_elves], new_todo, latest)

    updated_dashboard =
      updated_dashboard
      |> Map.put(:todos, MapSet.difference(new_todo, MapSet.new(started)))
      |> Map.put(:idle_elves, idle_elves)
      |> Map.put(:latest, latest)
      |> Map.update(:jobs, %{}, &Map.filter(&1, fn {_k, v} -> MapSet.size(v) != 0 end))
      |> IO.inspect()

    {:noreply, updated_dashboard}
  end
end
