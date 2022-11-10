defmodule Tic.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TicWeb.Telemetry,
      # Start the Ecto repository
      Tic.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Tic.PubSub},
      # Start Finch
      {Finch, name: Tic.Finch},
      # Start the Endpoint (http/https)
      TicWeb.Endpoint
      # Start a worker by calling: Tic.Worker.start_link(arg)
      # {Tic.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tic.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TicWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
