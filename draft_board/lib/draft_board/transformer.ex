defmodule DraftBoard.Transformer do

  alias DraftBoard.Player

  def transform_cfb_stats(raw_stats) do
    raw_stats
    |> Enum.group_by(fn stat -> stat["playerId"] end)
    |> Enum.map(fn {_id, stats} -> build_player(stats) end)
    |> Enum.filter(fn player -> player.position in ["QB", "RB", "WR", "TE", "K"] end)
  end

  defp build_player(stats) do
    first = List.first(stats)
    games = 12.0

    %Player{
      name:                first["player"],
      position:            normalize_position(first["position"]),
      team:                first["team"],
      conference:          first["conference"],
      school:              first["team"],
      league_type:         "CFB",
      is_rookie:           false,
      games_played:        round(games),
     games_missed_2yr:    0,
     injury_modifier:     1.0,
     yards_per_game:      safe_divide(get_stat(stats, "receiving", "YDS") + get_stat(stats, "rushing", "YDS"), games),
     tds_per_game:        safe_divide(get_stat(stats, "receiving", "TD") + get_stat(stats, "rushing", "TD"), games),
     receptions_per_game: safe_divide(get_stat(stats, "receiving", "REC"), games),
     touches_per_game:    safe_divide(get_stat(stats, "rushing", "CAR") + get_stat(stats, "receiving", "REC"), games),
     target_share:        0.0,
     snap_pct: estimate_snap_pct(stats),
     depth_chart_pos:     "Unknown",
     red_zone_targets:    0.0,
     interceptions_per_game: safe_divide(get_stat(stats, "passing", "INT"), games),
    }
  end

  defp get_stat(stats, category, stat_type) do
    stats
    |> Enum.find(fn s -> s["category"] == category && s["statType"] == stat_type end)
    |> case do
      nil  -> 0.0
      stat -> parse_float(stat["stat"])
    end
  end

  defp safe_divide(_num, 0.0), do: 0.0
  defp safe_divide(num, denom), do: num / denom

  defp parse_float(nil), do: 0.0
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val * 1.0
  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error  -> 0.0
    end
  end

  defp normalize_position("QB"), do: "QB"
  defp normalize_position("RB"), do: "RB"
  defp normalize_position("WR"), do: "WR"
  defp normalize_position("TE"), do: "TE"
  defp normalize_position("K"),  do: "K"
  defp normalize_position(_),    do: "Unknown"


  defp estimate_snap_pct(stats) do
    carries = get_stat(stats, "rushing", "CAR")
    receptions = get_stat(stats, "receiving", "REC")
    total_touches = carries + receptions

    cond do
      total_touches >= 15 -> 0.65
      total_touches >= 10 -> 0.50
      total_touches >= 5  -> 0.35
      total_touches >= 2  -> 0.20
      true                -> 0.05
    end
  end
end
