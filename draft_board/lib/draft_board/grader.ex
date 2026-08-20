defmodule DraftBoard.Grader do

  alias DraftBoard.Player

  def grade(%Player{position: "QB"} = player) do
    score =
      (player.yards_per_game * 0.15)
      + (player.tds_per_game * 8)
      + (player.touches_per_game * 0.1)
      - (player.interceptions_per_game)
      |>Kernel.*(player.injury_modifier)

    label = grade_label("QB", score)
    %{player | fantasy_score: score, grade_label: label}
  end

  def grade(%Player{position: "RB"} = player) do
    depth_multiplier = depth_chart_multiplier(player.depth_chart_pos)

    score =
      (player.tds_per_game * 10)
      + (player.touches_per_game * 2)
      + (player.receptions_per_game * 3)
      + (player.snap_pct *  30)
      |> Kernel.*(player.injury_modifier)
      |> Kernel.*(depth_multiplier)

    label = grade_label("RB", score)
    %{player | fantasy_score: score, grade_label: label}
    end

  def grade(%Player{position: "WR"} = player) do
    score =
      (player.receptions_per_game * 8)
      + (player.target_share * 40)
      + (player.yards_per_game * 0.1)
      + (player.tds_per_game * 6)
      |> Kernel.*(player.injury_modifier)

    label = grade_label("WR", score)
    %{player | fantasy_score: score, grade_label: label}
   end

 def grade(%Player{position: "TE"} = player) do
    score =
      (player.receptions_per_game * 10)
      + (player.target_share * 35)
      + (player.red_zone_targets *5)
      + (player.yards_per_game * 0.08)
      |> Kernel.*(player.injury_modifier)

    label = grade_label("TE", score)
    %{player | fantasy_score: score, grade_label: label}
  end

  def grade(%Player{position: "DST"} = player) do
    score =
      (player.sacks_per_game * 4)
      + (player.turnovers_per_game * 5)
      - (player.points_allowed_per_game * 0.3)
      |> Kernel.*(player.injury_modifier)
    label = grade_label("DST", score)
    %{player | fantasy_score: score, grade_label: label}
    end

  def grade(%Player{position: "K"} = player) do
    score =
      (player.field_goal_pct * 50)
      + (player.fg_long * 0.3)
      + (player.kick_attempts_per_game * 2)
      - (player.team_offense_rank * 0.2)

    label = grade_label("K", score)
    %{player | fantasy_score: score, grade_label: label}
    end



  defp depth_chart_multiplier(pos) do
    case pos do
      "RB1" -> 1.0
      "RB2" -> 0.6
      "RB3" -> 0.3
      _ -> 0.5
    end
  end

  defp grade_label("QB", score) do
    cond do
      score >= 80 -> "Elite"
      score >= 55 -> "Franchise"
      score >= 35 -> "Starter"
      score >= 20 -> "Backup"
      true -> "Drop"
    end
  end

  defp grade_label("RB", score) do
    cond do
      score >= 60 -> "Elite"
      score >= 40 -> "Workhorse"
      score >= 25 -> "Handcuff"
      score >= 12 -> "Stash"
      true -> "Drop"
    end
  end

  defp grade_label("WR", score) do
    cond do
      score >= 70-> "Elite"
      score >= 50 -> "WR1"
      score >= 30 -> "WR2"
      score >= 15 -> "Depth"
      true -> "Drop"
    end
  end

  defp grade_label("TE", score) do
    cond do
      score >= 55 -> "Elite"
      score >= 38 -> "Starter"
      score >= 22 -> "Streamer"
      score >= 10 -> "Dart"
      true -> "Drop"
    end
  end

  defp grade_label("DST", score) do
    cond do
      score >= 25 -> "Elite"
      score >= 15 -> "Start"
      score >= 8 -> "Stream"
      score >= 3 -> "Avoid"
      true -> "Drop"
    end
  end

  defp grade_label("K", score) do
    cond do
      score >= 40 -> "Elite"
      score >= 30 -> "Solid"
      score >= 20 -> "Alright"
      score >= 10 -> "Weak"
      true -> "Bust"
    end
  end
end
