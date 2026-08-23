defmodule DraftBoard.PlayerSchema do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field :name,                  :string
    field :position,              :string
    field :team,                  :string
    field :bye_week,              :integer
    field :depth_chart_pos,       :string
    field :snap_pct,              :float
    field :games_played,          :integer
    field :games_missed_2yr,      :integer, default: 0
    field :touches_per_game,      :float
    field :yards_per_game,        :float
    field :receptions_per_game,   :float
    field :tds_per_game,          :float
    field :target_share,          :float
    field :red_zone_targets,      :float
    field :interceptions_per_game,:float
    field :points_allowed_per_game,:float
    field :sacks_per_game,        :float
    field :turnovers_per_game,    :float
    field :field_goal_pct,        :float
    field :fg_long,               :integer
    field :kick_attempts_per_game,:float
    field :team_offense_rank,     :integer
    field :is_rookie,             :boolean, default: false
    field :rookie_tier,           :string
    field :fantasy_score,         :float
    field :grade_label,           :string
    field :injury_modifier,       :float,   default: 1.0
    field :league_type,  :string, default: "NFL"
    field :school,       :string
    field :conference,   :string
    field :left_for_nfl, :boolean, default: false
    timestamps()
  end

  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :position, :team, :bye_week, :fantasy_score,
                    :grade_label, :injury_modifier, :is_rookie, :rookie_tier,
                    :yards_per_game, :tds_per_game, :receptions_per_game,
                    :touches_per_game, :target_share, :snap_pct,
                    :depth_chart_pos, :games_played, :games_missed_2yr,
                    :red_zone_targets, :interceptions_per_game,
                    :points_allowed_per_game, :sacks_per_game,
                    :turnovers_per_game, :field_goal_pct, :fg_long,
                    :kick_attempts_per_game, :team_offense_rank, :league_type, :school, :conference, :left_for_nfl])
    |> validate_required([:name, :position])
  end

end
