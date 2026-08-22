defmodule DraftBoard.Player do
  defstruct [
    :player_id,
    :name,
    :position,
    :team,
    :bye_week,
    :depth_chart_pos,
    :snap_pct,
    :games_played,
    :games_missed_2yr,
    :touches_per_game,
    :yards_per_game,
    :receptions_per_game,
    :tds_per_game,
    :target_share,
    :red_zone_targets,
    :is_rookie,
    :rookie_tier,
    :fantasy_score,
    :grade_label,
    :injury_modifier,
    :interceptions_per_game,
    :points_allowed_per_game,
    :sacks_per_game,
    :turnovers_per_game,
    :field_goal_pct,
    :fg_long,
    :kick_attempts_per_game,
    :team_offense_rank,
    :league_type,
    :school,
    :conference
  ]

  def injury_modifier(games_missed) do
    cond do
      games_missed == 0 -> 1.0
      games_missed == 4 -> 0.9
      games_missed == 8 -> 0.8
      true -> 0.7
    end
  end
end
