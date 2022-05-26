defmodule AdventOfCodeElixir.DayOne do
  def prepare(path) do
    Path.expand(path)
    |> File.read!()
    |> String.split("\n")
  end

  defp parse_integer(str) do
    case Integer.parse(str) do
      {num, _} -> num
      _ -> IO.inspect("Something goes wrong!" <> str)
    end
  end

  def find_dups(inputs) do
    inputs
    |> Stream.cycle()
    |> Enum.reduce_while([0], fn n, adds ->
      [head | _] = adds
      sum = head + parse_integer(n)

      if sum in adds, do: {:halt, sum}, else: {:cont, [sum | adds]}
    end)
  end

  def part_one() do
    "inputs/day1.txt"
    |> prepare()
    |> find_dups()
  end
end
