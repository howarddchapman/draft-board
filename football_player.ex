# Week 3 - Modules, Functions, and Conditions
# FootballPlayer Module - foundation of capstone project
defmodule FootballPlayer do

    def greet(name) do
        IO.puts "Welcome to the draft board, #{name}!"
    end

    def grade(yards, touchdowns) do
        (yards + 0.1) + (touchdowns * 6)
    end

    def grade_label(score) do
        cond do
            score >= 100 -> "Elite"
            score >= 70 -> "Starter"
            score >= 40 -> "Flex"
            true -> "Drop"
        end
    end

   def handle_player({:ok, player_name, yards}) do
        IO.puts "#{player_name} loaded successfully - #{yards} yards"
    end

    def handle_player({:error, reason}) do
        IO.puts "Failed to load player: #{reason}"
    end

    def full_grade(player) do
        player.yards
        |> grade(player.touchdowns)
        |> grade_label()
        |> IO.puts()
    end
end
