defmodule DraftBoard.NflTransformer do

  alias DraftBoard.Player

  def transform_nfl_player(player_info, weekly_stats) do
    games = length(weekly_stats)
    games_safe = if games == 0, do: 1, else: games

    total_passing_yards  = sum_stat(weekly_stats, "passing_yards")
    total_rushing_yards  = sum_stat(weekly_stats, "rushing_yards")
    total_receiving_yards = sum_stat(weekly_stats, "receiving_yards")
    total_passing_tds    = sum_stat(weekly_stats, "passing_tds")
    total_rushing_tds    = sum_stat(weekly_stats, "rushing_tds")
    total_receiving_tds  = sum_stat(weekly_stats, "receiving_tds")
    total_receptions     = sum_stat(weekly_stats, "receptions")
    total_targets        = sum_stat(weekly_stats, "targets")
    total_carries        = sum_stat(weekly_stats, "carries")
    total_interceptions  = sum_stat(weekly_stats, "interceptions_thrown")
    total_attempts       = sum_stat(weekly_stats, "attempts")
    avg_target_share     = avg_stat(weekly_stats, "target_share")

    games_missed = max(0, 17 - games)

    position = player_info.position

    yards_per_game = case position do
      "QB" -> safe_div(total_passing_yards + total_rushing_yards, games_safe)
      "RB" -> safe_div(total_rushing_yards + total_receiving_yards, games_safe)
      _    -> safe_div(total_receiving_yards, games_safe)
    end

    tds_per_game = safe_div(total_passing_tds + total_rushing_tds + total_receiving_tds, games_safe)

    %Player{
      name:                   player_info.name,
      position:               position,
      team:                   player_info.team,
      league_type:            "NFL",
      is_rookie:              false,
      games_played:           games,
      games_missed_2yr:       games_missed,
      injury_modifier:        injury_modifier(games_missed),
      left_for_nfl:           false,
      yards_per_game:         Float.round(yards_per_game, 2),
      tds_per_game:           Float.round(tds_per_game, 2),
      receptions_per_game:    Float.round(safe_div(total_receptions, games_safe), 2),
      touches_per_game:       Float.round(safe_div(total_carries + total_receptions, games_safe), 2),
      target_share:           Float.round(avg_target_share, 3),
      snap_pct:               if(games > 0, do: 0.7, else: 0.0),
      depth_chart_pos:        "Unknown",
      red_zone_targets:       0.0,
      interceptions_per_game: Float.round(safe_div(total_interceptions, games_safe), 2),
      bye_week:               nil,
      school:                 nil,
      conference:             nil
    }
  end

  defp sum_stat(weeks, key) do
    Enum.sum(Enum.map(weeks, fn w -> parse_float(w[key]) end))
  end

  defp avg_stat(weeks, key) do
    total = Enum.sum(Enum.map(weeks, fn w -> parse_float(w[key]) end))
    if length(weeks) > 0, do: total / length(weeks), else: 0.0
  end

  defp safe_div(_, 0), do: 0.0
  defp safe_div(num, den), do: num / den

  defp parse_float(nil), do: 0.0
  defp parse_float(""), do: 0.0
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val * 1.0
  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error  -> 0.0
    end
  end

  defp injury_modifier(games_missed) do
    cond do
      games_missed == 0 -> 1.0
      games_missed <= 4 -> 0.9
      games_missed <= 8 -> 0.8
      true              -> 0.7
    end
  end

end
