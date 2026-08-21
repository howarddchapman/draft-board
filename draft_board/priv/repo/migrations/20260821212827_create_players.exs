defmodule DraftBoard.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name,                  :string,  null: false
      add :position,              :string,  null: false
      add :team,                  :string
      add :bye_week,              :integer
      add :depth_chart_pos,       :string
      add :snap_pct,              :float
      add :games_played,          :integer
      add :games_missed_2yr,      :integer, default: 0
      add :touches_per_game,      :float
      add :yards_per_game,        :float
      add :receptions_per_game,   :float
      add :tds_per_game,          :float
      add :target_share,          :float
      add :red_zone_targets,      :float
      add :interceptions_per_game,:float
      add :points_allowed_per_game,:float
      add :sacks_per_game,        :float
      add :turnovers_per_game,    :float
      add :field_goal_pct,        :float
      add :fg_long,               :integer
      add :kick_attempts_per_game,:float
      add :team_offense_rank,     :integer
      add :is_rookie,             :boolean, default: false
      add :rookie_tier,           :string
      add :fantasy_score,         :float
      add :grade_label,           :string
      add :injury_modifier,       :float,   default: 1.0

      timestamps()
    end
  end
end
