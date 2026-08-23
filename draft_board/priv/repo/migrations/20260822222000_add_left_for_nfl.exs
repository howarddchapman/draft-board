defmodule DraftBoard.Repo.Migrations.AddLeftForNfl do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :left_for_nfl, :boolean, default: false
    end
  end
end
