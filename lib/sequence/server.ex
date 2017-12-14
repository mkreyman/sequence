defmodule Sequence.Server do
  use GenServer
  require Logger

  defmodule State, do: defstruct current_number: 0, stash_pid: nil, delta: 1

  @vsn "1"

  # External API

  def start_link(stash_pid) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, stash_pid, name: __MODULE__)
  end

  def next_number do
    GenServer.call __MODULE__, :next_number
  end

  def increment_number(delta) do
    GenServer.cast __MODULE__, {:increment_number, delta}
  end

  # GenServer implementation

  def init(stash_pid) do
    current_number = Sequence.Stash.get_value stash_pid
    { :ok, %State{current_number: current_number, stash_pid: stash_pid} }
  end

  def handle_call(:next_number, _from, state) do
    {
      :reply,
      state.current_number,
      %{ state | current_number: state.current_number + state.delta }
    }
  end

  def handle_call({:set_number, new_number}, _from, _current_number) do
    { :reply, new_number, new_number }
  end

  def handle_cast({:increment_number, delta}, state) do
    {
      :noreply,
      %{ state | current_number: state.current_number + delta, delta: delta }
    }
  end

  def terminate(_reason, state) do
    Sequence.Stash.save_value state.stash_pid, state.current_number
  end

  def code_change("0", old_state = { current_number, stash_pid }, _extra) do
    new_state = %State{current_number: current_number,
                       stash_pid: stash_pid,
                       delta: 1
                      }
    Logger.info "Changing code from 0 to 1"
    Logger.info inspect(old_state)
    Logger.info inspect(new_state)
    { :ok, new_state }
  end

  def format_status(_reason, [ _pdict, state ]) do
    [data: [{'State', "My current state is '#{inspect state}', and I'm happy"}]]
  end
end

# iex(8)> GenServer.call(pid, {:set_number, 999})
# 999
# iex(9)> GenServer.call(pid, :next_number)
# 999
# iex(10)> GenServer.call(pid, :next_number)
# 1000
# iex(11)> GenServer.call(pid, {:set_number, 1})
# 1
# iex(12)> GenServer.call(pid, :next_number)
# 1
# iex(13)> GenServer.call(pid, :next_number)
# 2

# iex(14)> r Sequence.Server
# warning: redefining module Sequence.Server (current version defined in memory)
#   lib/sequence/server.ex:1

# {:reloaded, Sequence.Server, [Sequence.Server]}
# iex(15)> { :ok, pid } = GenServer.start_link(Sequence.Server, 100)
# {:ok, #PID<0.184.0>}
# iex(16)> GenServer.call(pid, :next_number)
# 100
# iex(17)> GenServer.call(pid, :next_number)
# 101
# iex(18)>
# nil
# iex(19)> GenServer.call(pid, :next_number)
# 102
# iex(20)> GenServer.cast(pid, {:increment_number, 200})
# :ok
# iex(21)> GenServer.call(pid, :next_number)
# 303

# With trace ON
# iex(22)> {:ok,pid} = GenServer.start_link(Sequence.Server, 100, [debug: [:trace]])
# {:ok, #PID<0.192.0>}
# iex(23)> GenServer.call(pid, :next_number)
# *DBG* <0.192.0> got call next_number from <0.150.0>
# *DBG* <0.192.0> sent 100 to <0.150.0>, new state 101
# 100
# iex(24)> GenServer.call(pid, :next_number)
# *DBG* <0.192.0> got call next_number from <0.150.0>
# *DBG* <0.192.0> sent 101 to <0.150.0>, new state 102
# 101

# With stats
# iex(27)> {:ok,pid} = GenServer.start_link(Sequence.Server, 100, [debug: [:statistics]])
# {:ok, #PID<0.201.0>}
# iex(28)> GenServer.call(pid, :next_number)
# 100
# iex(29)> GenServer.call(pid, :next_number)
# 101
# iex(30)> :sys.statistics pid, :get
# {:ok,
#  [start_time: {{2017, 12, 13}, {14, 1, 3}},
#   current_time: {{2017, 12, 13}, {14, 1, 44}}, reductions: 84, messages_in: 2,
#   messages_out: 0]}

# Turning trace ON and OFF
# iex(31)> :sys.trace pid, true
# :ok
# iex(32)> GenServer.call(pid, :next_number)
# *DBG* <0.201.0> got call next_number from <0.150.0>
# *DBG* <0.201.0> sent 102 to <0.150.0>, new state 103
# 102
# iex(33)> :sys.trace pid, false
# :ok
# iex(34)> GenServer.call(pid, :next_number)
# 103

# Another useful function
# iex(35)> :sys.get_status pid
# {:status, #PID<0.201.0>, {:module, :gen_server},
#  [["$ancestors": [#PID<0.150.0>, #PID<0.63.0>],
#    "$initial_call": {Sequence.Server, :init, 1}], :running, #PID<0.150.0>,
#   [statistics: {{{2017, 12, 13}, {14, 1, 3}}, {:reductions, 21}, 4, 0}],
#   [header: 'Status for generic server <0.201.0>',
#    data: [{'Status', :running}, {'Parent', #PID<0.150.0>},
#     {'Logged events', []}], data: [{'State', 104}]]]}

# Upgrading server in real time
# iex(2)> Sequence.Server.next_number
# 456
# iex(3)> Sequence.Server.increment_number 10
# :ok
# iex(4)> Sequence.Server.next_number
# 467
# iex(5)> Sequence.Server.next_number
# 468
# iex(6)> :sys.suspend Sequence.Server
# :ok
# iex(7)> r Sequence.Server
# warning: redefining module Sequence.Server (current version loaded from _build/dev/lib/sequence/ebin/Elixir.Sequence.Server.beam)
#   lib/sequence/server.ex:1

# {:reloaded, Sequence.Server, [Sequence.Server.State, Sequence.Server]}
# iex(8)> :sys.change_code Sequence.Server, Sequence.Server, "0", []

# 11:03:19.941 [info]  Changing code from 0 to 1

# 11:03:19.941 [info]  {469, #PID<0.128.0>}

# 11:03:19.943 [info]  %Sequence.Server.State{current_number: 469, delta: 1, stash_pid: #PID<0.128.0>}
# :ok
# iex(9)> :sys.resume Sequence.Server
# :ok
# iex(10)> Sequence.Server.next_number
# 469
# iex(11)> Sequence.Server.increment_number 10
# :ok
# iex(12)> Sequence.Server.next_number
# 480
# iex(13)> Sequence.Server.next_number
# 490