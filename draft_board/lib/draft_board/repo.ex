defmodule DraftBoard.Repo do
  use Ecto.Repo,
    otp_app: :draft_board,
    adapter: Ecto.Adapters.Postgres
end
