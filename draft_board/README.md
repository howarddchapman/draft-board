# Draft Board

A fantasy football draft grading tool built with Elixir — covering both NFL and Power 4 college football (SEC, Big Ten, Big 12, ACC). Players are automatically graded using position-specific formulas, stored in PostgreSQL, and surfaced through a live filterable dashboard.

Built as a self-directed data engineering project to learn Elixir, functional programming, and real-world data pipeline design.

---

## What it does

- Pulls live player stats from the **College Football Data API** for all Power 4 conferences
- Grades every skill position player (QB, RB, WR, TE, K) using custom PPR-weighted formulas
- Automatically cross-references rosters against the **ESPN API** to flag players who have left for the NFL
- Stores all 1,300+ graded players in a **PostgreSQL** database via Ecto
- Serves a **live web dashboard** at localhost:4000 with filters for position, conference, and grade tier

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Elixir 1.20 |
| Database | PostgreSQL via Ecto |
| Web server | Plug + Cowboy |
| CFB data | College Football Data API |
| NFL roster data | ESPN unofficial API (no key required) |
| Project tooling | Mix |

---

## Architecture

```
CFB API (collegefootballdata.com)
    │
    ▼
ApiClient.get_cfb_stats/2        ← HTTPoison, Bearer token auth
    │
    ▼
Transformer.transform_cfb_stats/1  ← Groups stats by player, position-aware ETL
    │
    ▼
Grader.grade/1                   ← Position-specific PPR scoring formulas
    │
    ▼
PostgreSQL (players table)       ← Ecto schema, migrations, changesets
    │
    ▼
Server (Plug.Router)             ← Live dashboard at localhost:4000
```

**NFL Departure Detection:**
```
ESPN API (32 NFL team rosters, no key needed)
    │
    ▼
ApiClient.get_nfl_roster_names/0   ← ~3,000 active NFL player names
    │
    ▼
ApiClient.flag_nfl_departures/0    ← Cross-references CFB database, sets left_for_nfl: true
```

---

## Grading System

Grades are position-specific and PPR-weighted. Each position has its own formula and label tier:

**RB Formula:**
```
score = (tds_per_game × 10) + (touches_per_game × 2) + (receptions_per_game × 3) + (snap_pct × 30)
score = score × injury_modifier × depth_chart_multiplier
```

**WR Formula:**
```
score = (receptions_per_game × 8) + (target_share × 40) + (yards_per_game × 0.1) + (tds_per_game × 6)
score = score × injury_modifier
```

| Position | Tiers |
|---|---|
| QB | Elite / Franchise / Starter / Backup / Drop |
| RB | Elite / Workhorse / Handcuff / Stash / Drop |
| WR | Elite / WR1 / WR2 / Depth / Drop |
| TE | Elite / Starter / Streamer / Dart / Drop |
| DST | Elite / Start / Stream / Avoid / Drop |
| K | Elite / Solid / Alright / Weak / Bust |

**Injury modifier** scales from 1.0 (healthy) to 0.7 (9+ games missed over 2 seasons).

**Rookie flagging** uses NFL draft capital tiers instead of projecting college stats.

---

## Setup

### Prerequisites
- Elixir 1.20+
- PostgreSQL
- A free API key from [collegefootballdata.com](https://collegefootballdata.com)

### Installation

```bash
# Clone the repo
git clone https://github.com/howarddchapman-svg/draft-board.git
cd draft-board/draft_board

# Install dependencies
mix deps.get

# Set your CFB API key
export CFB_API_KEY=your_key_here   # Mac/Linux
$env:CFB_API_KEY = "your_key_here" # Windows PowerShell

# Create and migrate the database
mix ecto.create
mix ecto.migrate

# Start the app
iex -S mix
```

### Loading player data

```elixir
# Inside IEx — load all Power 4 conferences
alias DraftBoard.{Repo, PlayerSchema, Grader, Transformer, ApiClient}

conferences = ["SEC", "B1G", "ACC", "B12"]
Enum.each(conferences, fn conf ->
  {:ok, raw} = ApiClient.get_cfb_stats(2025, conf)
  raw |> Transformer.transform_cfb_stats() |> Enum.each(fn player ->
    graded = Grader.grade(player)
    attrs = Map.from_struct(graded)
    %PlayerSchema{} |> PlayerSchema.changeset(attrs) |> Repo.insert()
  end)
end)

# Flag NFL departures automatically
ApiClient.flag_nfl_departures()
```

Then open [http://localhost:4000](http://localhost:4000) in your browser.

---

## Key Design Decisions

**Why Elixir?** Elixir's concurrency model via the BEAM VM makes it well-suited for data pipelines — processing hundreds of player records simultaneously without blocking. The pipe operator `|>` makes ETL transformations readable and maintainable.

**Why position-specific formulas?** A QB's yards are passing yards. An RB's value comes from touchdowns and snap count, not just yardage. Generic formulas produce misleading grades — position-aware logic reflects how fantasy managers actually evaluate players.

**Why ESPN for NFL departure detection?** The ESPN unofficial API requires no authentication and provides live roster data for all 32 NFL teams. Cross-referencing ~3,000 NFL names against 1,300+ CFB players takes seconds and runs automatically.

**Why Ecto migrations?** Migrations create a version history for the database schema. Anyone cloning the repo can run `mix ecto.migrate` and get an identical database structure — no manual SQL required.

---

## Project Structure

```
draft_board/
├── lib/draft_board/
│   ├── player.ex          # Core player struct
│   ├── grader.ex          # Position-specific grading formulas
│   ├── transformer.ex     # ETL — raw API JSON → Player structs
│   ├── api_client.ex      # CFB API + ESPN API connections
│   ├── rookie.ex          # Rookie flagging by draft capital
│   ├── player_schema.ex   # Ecto schema + changeset validation
│   ├── repo.ex            # Database repository
│   ├── server.ex          # Plug web server + dashboard
│   └── application.ex    # OTP supervision tree
├── priv/repo/migrations/  # Database migrations
├── config/config.exs      # App + database configuration
└── mix.exs                # Dependencies + project config
```

---

## What's Next

- [ ] NFL player stats via SportsData.io API
- [ ] Weekly automated stat refresh scheduler
- [ ] Deploy to Fly.io for a live public URL
- [ ] ADP integration to surface undervalued players

---

*Built by Howard Chapman · Auburn University · Business Analytics & Information Systems Management*