defmodule DraftBoard.Rookie do

  alias DraftBoard.Player

  def flag(%Player{is_rookie: true} = player, draft_pick) do
    tier = determine_tier(draft_pick)
    %{player | rookie_tier: tier, grade_label: "Rookie - #{tier} Prospect"}
  end

  def flag(%Player{is_rookie: false} = player, _draft_pick) do
    player
  end

  defp determine_tier(pick) do
    cond do
      pick <= 15 -> "High"
      pick <= 50 -> "Medium"
      pick <= 100 -> "Low"
      true -> "Undrafted"
    end
  end
end
