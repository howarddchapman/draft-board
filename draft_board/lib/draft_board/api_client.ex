defmodule DraftBoard.ApiClient do

  @cfb_base_url "https://api.collegefootballdata.com"
  @api_key Application.compile_env(:draft_board, :cfb_api_key)

  defp headers do
    [
      {"Authorization", "Bearer #{@api_key}"},
      {"Accept", "application/json"}
    ]
  end

  def get_cfb_stats(year \\ 2025, conference \\ nil) do
    url = case conference do
      nil  -> "#{@cfb_base_url}/stats/player/season?year=#{year}"
      conf -> "#{@cfb_base_url}/stats/player/season?year=#{year}&conference=#{conf}"
    end

    case HTTPoison.get(url, headers(), timeout: 15000, recv_timeout: 15000) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}
      {:ok, %{status_code: status, body: body}} ->
        {:error, "Status #{status}: #{body}"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_player(name) do
    url = "#{@cfb_base_url}/player/search?searchTerm=#{URI.encode(name)}"

    case HTTPoison.get(url, headers(), timeout: 15000, recv_timeout: 15000) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}
      {:ok, %{status_code: status, body: body}} ->
        {:error, "Status #{status}: #{body}"}
      {:error, reason} ->
        {:error, reason}
    end
  end


  @nfl_team_ids [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 33, 34]

def get_nfl_roster_names do
  @nfl_team_ids
  |> Enum.flat_map(fn team_id ->
    url = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/#{team_id}/roster"
    case HTTPoison.get(url, [], timeout: 10000, recv_timeout: 10000) do
      {:ok, %{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> get_in(["athletes"])
        |> case do
          nil -> []
          athletes ->
            athletes
            |> Enum.flat_map(fn group ->
              Map.get(group, "items", [])
            end)
            |> Enum.map(fn player -> player["fullName"] end)
            |> Enum.filter(&(&1 != nil))
        end
      _ -> []
    end
  end)
  |> Enum.uniq()
  end

  def flag_nfl_departures do
    alias DraftBoard.{Repo, PlayerSchema}
    import Ecto.Query

    nfl_names = get_nfl_roster_names()
    IO.puts("Fetched #{length(nfl_names)} NFL players")

    cfb_players = Repo.all(from p in PlayerSchema, where: p.league_type == "CFB")
    IO.puts("Checking #{length(cfb_players)} CFB players")

    flagged = Enum.reduce(cfb_players, 0, fn player, count ->
      if Enum.member?(nfl_names, player.name) do
        player
        |> Ecto.Changeset.change(left_for_nfl: true)
        |> Repo.update!()
        count + 1
      else
        count
      end
  end)

  IO.puts("Flagged #{flagged} players as NFL departures")
  {:ok, flagged}
  end
end
