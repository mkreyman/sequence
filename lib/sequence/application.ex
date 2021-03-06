defmodule Sequence.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  # def start(_type, _args) do
  #   import Supervisor.Spec, warn: false
  #   # List all child processes to be supervised
  #   children = [
  #     # Starts a worker by calling: Sequence.Worker.start_link(arg)
  #     # {Sequence.Worker, arg},
  #     worker(Sequence.Server, [123])
  #   ]

  #   # See https://hexdocs.pm/elixir/Supervisor.html
  #   # for other strategies and supported options
  #   opts = [strategy: :one_for_one, name: Sequence.Supervisor]
  #   {:ok, _pid} = Supervisor.start_link(children, opts)
  # end

  def start(_type, _args) do
    Sequence.Supervisor.start_link(Application.get_env(:sequence, :initial_number))
  end
end
