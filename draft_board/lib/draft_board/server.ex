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
      order_by: [desc: p.fantasy_score],
      limit: 50
    )
    html = render_dashboard(players)
    send_resp(conn, 200, html)
  end

  get "/players" do
    position = conn.params["position"]
    conference = conn.params["conference"]
    grade = conn.params["grade"]

    query = from p in PlayerSchema, where: p.left_for_nfl == false, order_by: [desc: p.fantasy_score]
    query = if position && position != "", do: from(p in query, where: p.position == ^position), else: query
    query = if conference && conference != "", do: from(p in query, where: p.conference == ^conference), else: query
    query = if grade && grade != "", do: from(p in query, where: p.grade_label == ^grade), else: query
    nfl_departed = conn.params["nfl_departed"]
    query = if nfl_departed && nfl_departed != "", do: from(p in query, where: p.left_for_nfl == ^(nfl_departed == "true")), else: query

    players = Repo.all(query)
    html = render_dashboard(players)
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
        <td>#{Float.round(p.fantasy_score || 0.0, 1)}</td>
        <td>#{Float.round((p.yards_per_game || 0.0) * 1.0, 1)}</td>
        <td>#{Float.round((p.tds_per_game || 0.0) * 1.0, 2)}</td>
        <td>#{Float.round((p.receptions_per_game || 0.0) * 1.0, 2)}</td>
      </tr>
      """
    end)
    |> Enum.join("\n")

    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Draft Board</title>
      <style>
        body { font-family: Arial, sans-serif; background: #0f0f1a; color: #e0e0e0; padding: 20px; }
        h1 { color: #7B68EE; }
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
        <select name="nfl_departed">
          <option value="">All Players</option>
          <option value="false">Still in College</option>
          <option value="true">Left for NFL</option>
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

  defp grade_color("Elite"),     do: "#00ff88"
  defp grade_color("Workhorse"), do: "#00cc66"
  defp grade_color("WR1"),       do: "#00cc66"
  defp grade_color("Handcuff"),  do: "#ffcc00"
  defp grade_color("WR2"),       do: "#ffcc00"
  defp grade_color("Streamer"),  do: "#ff9900"
  defp grade_color("Stash"),     do: "#ff9900"
  defp grade_color("Depth"),     do: "#ff6600"
  defp grade_color("Dart"),      do: "#ff6600"
  defp grade_color(_),           do: "#ff4444"

end
