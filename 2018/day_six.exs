defmodule DaySix do
  def prepare_locs(path) do
    Path.expand(path)
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(& parse(&1))
  end

  defp parse(str) do
    [x, y] = String.split(str, ", ")
    {String.to_integer(x), String.to_integer(y)}
  end

  def prepare_coords(locs) do
    {min_x, _} = Enum.min_by(locs, & elem(&1, 0))
    {_, min_y} = Enum.min_by(locs, & elem(&1, 1))
    {max_x, _} = Enum.max_by(locs, & elem(&1, 0))
    {_, max_y} = Enum.max_by(locs, & elem(&1, 1))

    coords = Enum.flat_map(min_x..max_x, fn from_x ->
              Enum.map(min_y..max_y, fn from_y ->
                {from_x, from_y}
              end)
            end)

    {locs, coords}
  end

  defp distance({x1, y1}, {x2, y2}) do
    abs(x1-x2) + abs(y1-y2)
  end

  def calculate_distance({locs, coords}) do
    Enum.map(coords, fn coord ->
      locs
      |> Enum.map(& distance(&1, coord))
      |> Enum.sum()
    end)
  end
end

"./inputs/day6.txt"
|> DaySix.prepare_locs()
|> DaySix.prepare_coords()
|> DaySix.calculate_distance()
|> Enum.filter(& &1 < 10000)
|> length()
|> IO.inspect()
