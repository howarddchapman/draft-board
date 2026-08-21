import Config

config :draft_board, DraftBoard.Repo,
  username: "postgres",
  password: "NightShift812934$",
  hostname: "localhost",
  database: "draft_board",
  port: 5432

config :draft_board, ecto_repos: [DraftBoard.Repo]
