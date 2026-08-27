defmodule DraftBoard.Server do
  use Plug.Router

  alias DraftBoard.Repo
  alias DraftBoard.PlayerSchema
  import Ecto.Query

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:urlencoded], pass: ["*/*"]
  plug :dispatch

  get "/" do
    players = Repo.all(
      from p in PlayerSchema,
      where: p.left_for_nfl == false,
      where: p.league_type == "CFB",
      order_by: [desc: p.fantasy_score],
      limit: 500
    )
    html = render_dashboard(players)
    send_resp(conn, 200, html)
  end

  get "/players" do
    position = conn.params["position"]
    conference = conn.params["conference"]
    grade = conn.params["grade"]
    nfl_departed = conn.params["nfl_departed"]

    query = from p in PlayerSchema,
      where: p.left_for_nfl == false,
      where: p.league_type == "CFB",
      order_by: [desc: p.fantasy_score]

    query = if position && position != "", do: from(p in query, where: p.position == ^position), else: query
    query = if conference && conference != "", do: from(p in query, where: p.conference == ^conference), else: query
    query = if grade && grade != "", do: from(p in query, where: p.grade_label == ^grade), else: query
    query = if nfl_departed && nfl_departed != "", do: from(p in query, where: p.left_for_nfl == ^(nfl_departed == "true")), else: query

    players = Repo.all(query)
    html = render_dashboard(players)
    send_resp(conn, 200, html)
  end

  get "/teams" do
    cfb_key = Application.get_env(:draft_board, :cfb_api_key)
    conferences = ["SEC", "B1G", "ACC", "B12"]

    all_stats = Enum.flat_map(conferences, fn conf ->
      case HTTPoison.get("https://api.collegefootballdata.com/stats/season?year=2025&conference=#{conf}", [{"Authorization", "Bearer #{cfb_key}"}], timeout: 15000, recv_timeout: 15000) do
        {:ok, %{status_code: 200, body: body}} -> Jason.decode!(body)
        _ -> []
      end
    end)

    get_stat = fn stats, team, stat_name ->
      case Enum.find(stats, fn s -> s["team"] == team && s["statName"] == stat_name end) do
        nil -> 0
        s -> s["statValue"]
      end
    end

    teams = all_stats |> Enum.map(fn s -> s["team"] end) |> Enum.uniq()

    graded_teams = Enum.map(teams, fn team ->
      games = get_stat.(all_stats, team, "games")
      total_yards = get_stat.(all_stats, team, "totalYards")
      passing_tds = get_stat.(all_stats, team, "passingTDs")
      rushing_tds = get_stat.(all_stats, team, "rushingTDs")
      turnovers = get_stat.(all_stats, team, "turnovers")
      conference = all_stats |> Enum.find(fn s -> s["team"] == team end) |> Map.get("conference")

      games_safe = if games == 0, do: 1, else: games
      yards_per_game = total_yards / games_safe
      tds_per_game = (passing_tds + rushing_tds) / games_safe
      turnovers_per_game = turnovers / games_safe

      yard_bonus = cond do
        yards_per_game >= 300 -> 1.5 + (Float.floor((yards_per_game - 300) / 50) * 0.25)
        true -> 0.0
      end

      score = Float.round((tds_per_game * 3) + yard_bonus - (turnovers_per_game * 2), 1)

      %{
        team: team,
        conference: conference,
        score: score,
        yards_per_game: Float.round(yards_per_game * 1.0, 1),
        tds_per_game: Float.round(tds_per_game * 1.0, 2),
        turnovers_per_game: Float.round(turnovers_per_game * 1.0, 2)
      }
    end) |> Enum.sort_by(fn t -> t.score end, :desc)

    html = render_teams(graded_teams)
    send_resp(conn, 200, html)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp render_dashboard(players) do
    rows = Enum.map(players, fn p ->
      grade_color = grade_color(p.grade_label)
      """
      <tr>
        <td>#{p.name}</td>
        <td>#{p.position}</td>
        <td>#{p.school}</td>
        <td>#{p.conference}</td>
        <td>#{p.league_type}</td>
        <td style="color: #{grade_color}; font-weight: bold;">#{p.grade_label}</td>
        <td>#{Float.round((p.fantasy_score || 0.0) * 1.0, 1)}</td>
        <td>#{Float.round((p.yards_per_game || 0.0) * 1.0, 1)}</td>
        <td>#{Float.round((p.tds_per_game || 0.0) * 1.0, 2)}</td>
        <td>#{Float.round((p.receptions_per_game || 0.0) * 1.0, 2)}</td>
      </tr>
      """
    end) |> Enum.join("\n")

    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Draft Board</title>
      <style>
        body { font-family: Arial, sans-serif; background: #0f0f1a; color: #e0e0e0; padding: 20px; }
        h1 { color: #7B68EE; }
        .nav { margin-bottom: 20px; }
        .nav a { color: #7B68EE; margin-right: 20px; text-decoration: none; font-size: 15px; }
        .nav a:hover { text-decoration: underline; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #1a1a2e; color: #7B68EE; padding: 10px; text-align: left; }
        td { padding: 8px 10px; border-bottom: 1px solid #2a2a3e; }
        tr:hover { background: #1a1a2e; }
        .filters { margin: 20px 0; display: flex; gap: 10px; flex-wrap: wrap; }
        select { background: #1a1a2e; color: #e0e0e0; border: 1px solid #7B68EE; padding: 8px 12px; border-radius: 4px; }
        button { background: #7B68EE; color: white; border: none; padding: 8px 20px; border-radius: 4px; cursor: pointer; }
      </style>
    </head>
    <body>
      <h1>Draft Board</h1>
      <div class="nav">
        <a href="/">Players</a>
        <a href="/teams">Teams</a>
      </div>
      <form class="filters" action="/players" method="get">
        <select name="position">
          <option value="">All Positions</option>
          <option value="QB">QB</option>
          <option value="RB">RB</option>
          <option value="WR">WR</option>
          <option value="TE">TE</option>
          <option value="K">K</option>
        </select>
        <select name="conference">
          <option value="">All Conferences</option>
          <option value="SEC">SEC</option>
          <option value="B1G">Big Ten</option>
          <option value="ACC">ACC</option>
          <option value="B12">Big 12</option>
        </select>
        <select name="grade">
          <option value="">All Grades</option>
          <option value="Elite">Elite</option>
          <option value="Workhorse">Workhorse</option>
          <option value="WR1">WR1</option>
          <option value="Handcuff">Handcuff</option>
          <option value="WR2">WR2</option>
          <option value="Streamer">Streamer</option>
          <option value="Stash">Stash</option>
          <option value="Depth">Depth</option>
          <option value="Dart">Dart</option>
          <option value="Drop">Drop</option>
        </select>
        <button type="submit">Filter</button>
      </form>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Position</th>
            <th>School</th>
            <th>Conference</th>
            <th>League</th>
            <th>Grade</th>
            <th>Score</th>
            <th>Yds/G</th>
            <th>TD/G</th>
            <th>Rec/G</th>
          </tr>
        </thead>
        <tbody>
          #{rows}
        </tbody>
      </table>
    </body>
    </html>
    """
  end

  defp render_teams(teams) do
    rows = Enum.with_index(teams, 1) |> Enum.map(fn {t, rank} ->
      score_color = cond do
        t.score >= 15 -> "#00ff88"
        t.score >= 12 -> "#ffcc00"
        t.score >= 9  -> "#ff9900"
        true          -> "#ff4444"
      end
      """
      <tr>
        <td>#{rank}</td>
        <td>#{t.team}</td>
        <td>#{t.conference}</td>
        <td style="color: #{score_color}; font-weight: bold;">#{t.score}</td>
        <td>#{t.tds_per_game}</td>
        <td>#{t.yards_per_game}</td>
        <td>#{t.turnovers_per_game}</td>
      </tr>
      """
    end) |> Enum.join("\n")

    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Draft Board - Teams</title>
      <style>
        body { font-family: Arial, sans-serif; background: #0f0f1a; color: #e0e0e0; padding: 20px; }
        h1 { color: #7B68EE; }
        .nav { margin-bottom: 20px; }
        .nav a { color: #7B68EE; margin-right: 20px; text-decoration: none; font-size: 15px; }
        .nav a:hover { text-decoration: underline; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #1a1a2e; color: #7B68EE; padding: 10px; text-align: left; }
        td { padding: 8px 10px; border-bottom: 1px solid #2a2a3e; }
        tr:hover { background: #1a1a2e; }
      </style>
    </head>
    <body>
      <h1>Draft Board — Team Offense Rankings</h1>
      <div class="nav">
        <a href="/">Players</a>
        <a href="/teams">Teams</a>
      </div>
      <table>
        <thead>
          <tr>
            <th>Rank</th>
            <th>School</th>
            <th>Conference</th>
            <th>Score</th>
            <th>TDs/G</th>
            <th>Yds/G</th>
            <th>TO/G</th>
          </tr>
        </thead>
        <tbody>
          #{rows}
        </tbody>
      </table>
    </body>
    </html>
    """
  end

  defp grade_color("Elite"),     do: "#00ff88"
  defp grade_color("Workhorse"), do: "#00cc66"
  defp grade_color("WR1"),       do: "#00cc66"
  defp grade_color("Franchise"), do: "#00cc66"
  defp grade_color("Handcuff"),  do: "#ffcc00"
  defp grade_color("WR2"),       do: "#ffcc00"
  defp grade_color("Starter"),   do: "#ffcc00"
  defp grade_color("Streamer"),  do: "#ff9900"
  defp grade_color("Stash"),     do: "#ff9900"
  defp grade_color("Depth"),     do: "#ff6600"
  defp grade_color("Dart"),      do: "#ff6600"
  defp grade_color(_),           do: "#ff4444"

end
