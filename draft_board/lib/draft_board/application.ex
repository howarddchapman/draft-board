defmodule DraftBoard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DraftBoard.Repo,
      {Plug.Cowboy, scheme: :http, plug: DraftBoard.Server, options: [port: String.to_integer(System.get_env("PORT") || "4000"), ip: {0, 0, 0, 0}]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DraftBoard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
