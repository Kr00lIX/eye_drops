defmodule EyeDrops.EyeBall do
  use GenServer
  alias EyeDrops.Tasks

  # External api
  @spec open(map) :: {:ok, pid}
  def open(tasks) do
    GenServer.start_link(__MODULE__, tasks, name: __MODULE__)
  end

  @spec look(pid, atom) :: none
  def look(server, key) do
    GenServer.call(server, {:lookup, key})
  end

  @spec run_on_start(pid) :: none
  def run_on_start(server) do
    GenServer.call(server, :run_on_start)
  end

  # GenServer implementation
  @spec init(map) :: {:ok, map}
  def init(tasks) do
    :ok = :fs.subscribe
    include_list = Map.get(tasks, :include_tasks, [])
    
    eye_tasks = case include_list do
      list when list == [] -> Tasks.get
      list -> Tasks.get(list)
    end
    {:ok, %{tasks: eye_tasks}}
  end

  @spec handle_info({pid, tuple, tuple}, any) :: {:noreply, any}
  def handle_info({_pid, {:fs, :file_event}, {path, _event}}, state) do
    :ok = Tasks.to_run(state.tasks, to_string(path))
    |> Tasks.exec

    flush
    {:noreply, state}
  end

  @spec handle_call(tuple, any, any) :: {:reply, any, any}
  def handle_call({:lookup, name}, _from, state) do
    {:reply, Map.fetch(state, name), state}
  end

  @spec handle_call(atom, any, any) :: {:reply, any, any}
  def handle_call(:run_on_start, _from, state) do
    tasks = Tasks.run_on_start(state.tasks)
    :ok = Tasks.exec(tasks)
    {:reply, state, state}
  end

  @spec flush :: :ok
  defp flush do
    receive do
      _       -> flush()
      after 0 -> :ok
    end
  end
end