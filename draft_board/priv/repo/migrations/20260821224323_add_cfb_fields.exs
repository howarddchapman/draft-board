defmodule DraftBoard.Repo.Migrations.AddCfbFields do
  use Ecto.Migration

  def change do
  alter table(:players) do
    add :league_type,  :string, default: "NFL"
    add :school,       :string
    add :conference,   :string
  end
  end
end
