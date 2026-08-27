import Config

config :draft_board, DraftBoard.Repo,
  username: "postgres",
  password: "NightShift812934$",
  hostname: "localhost",
  database: "draft_board",
  port: 5432

config :draft_board, ecto_repos: [DraftBoard.Repo]

config :draft_board, :cfb_api_key, System.get_env("CFB_API_KEY")

if System.get_env("DATABASE_URL") do
  config :draft_board, DraftBoard.Repo,
    url: System.get_env("DATABASE_URL"),
    pool_size: 2

config :draft_board, :cfb_api_key, System.get_env("CFB_API_KEY") || "5lCFWFLsb4SjwEOvknH6EQsy1oI46oILnadAON56QjlItqk5qsrLk6twpVAzNAYt
"
end
