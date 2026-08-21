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

end
