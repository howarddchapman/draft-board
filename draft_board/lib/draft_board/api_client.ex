defmodule DraftBoard.ApiClient do

  @cfb_base_url "https://api.collegefootballdata.com"
  @api_key System.get_env("CFB_API_KEY")

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
@nfl_players_csv "https://github.com/nflverse/nflverse-data/releases/download/players/players.csv"
@nfl_api_base "https://api.bigballsdata.com"
@nfl_api_key System.get_env("NFL_API_KEY")

def get_nfl_player_ids do
  case HTTPoison.get(@nfl_players_csv, [], timeout: 30000, recv_timeout: 30000, follow_redirect: true) do
    {:ok, %{status_code: 200, body: body}} ->
      players = body
      |> String.split("\n")
      |> Enum.drop(1)
      |> Enum.filter(fn row -> row != "" end)
      |> Enum.map(fn row ->
        cols = String.split(row, ",")
        %{
          last_season: Enum.at(cols, 27),
          gsis_id:  Enum.at(cols, 0),
          name:     Enum.at(cols, 1),
          position: Enum.at(cols, 17),
          team:     Enum.at(cols, 29),
          status:   Enum.at(cols, 30),
          espn_id:  Enum.at(cols, 13)
        }
      end)
      |> Enum.filter(fn p ->
        p.position in ["QB", "RB", "WR", "TE", "K"] and
        p.last_season in ["2025", "2026"] and
        p.gsis_id != ""
        String.starts_with?(p.gsis_id, "00-")
      end)
      {:ok, players}
    {:error, reason} ->
      {:error, reason}
  end
end

def get_nfl_player_stats(gsis_id, season \\ 2025) do
  url = "#{@nfl_api_base}/v1/nfl/players/#{gsis_id}/stats?season=#{season}"
  headers = [{"Authorization", "Bearer #{@nfl_api_key}"}]

  case HTTPoison.get(url, headers, timeout: 15000, recv_timeout: 15000) do
    {:ok, %{status_code: 200, body: body}} ->
      {:ok, Jason.decode!(body)}
    {:ok, %{status_code: status}} ->
      {:error, "Status #{status}"}
    {:error, reason} ->
      {:error, reason}
  end
end

end
