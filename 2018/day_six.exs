defmodule DaySix do
  defp prepare_locs(path) do
    Path.expand(path)
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&parse(&1))
  end

  defp parse(str) do
    [x, y] = String.split(str, ", ")
    {String.to_integer(x), String.to_integer(y)}
  end

  defp prepare_coords(locs) do
    {{min_x, _}, {max_x, _}} = Enum.min_max_by(locs, &elem(&1, 0))
    {{_, min_y}, {_, max_y}} = Enum.min_max_by(locs, &elem(&1, 1))

    coords =
      Enum.flat_map(min_x..max_x, fn from_x ->
        Enum.map(min_y..max_y, fn from_y ->
          {from_x, from_y}
        end)
      end)

    {locs, coords, {min_x, max_x, min_y, max_y}}
  end

  defp distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  defp calculate_distance({locs, coords, _}) do
    Enum.map(coords, fn coord ->
      Enum.reduce(locs, 0, fn loc, acc -> acc + distance(loc, coord) end)
    end)
  end

  defp find_closest(coord, locs) do
    Enum.reduce(locs, {nil, nil}, fn loc, {min_loc, min_dist} ->
      dist = distance(loc, coord)

      cond do
        dist == min_dist -> {".", dist}
        dist < min_dist -> {loc, dist}
        true -> {min_loc, min_dist}
      end
    end)
  end

  defp mark_area(locs, coords, margins) do
    Enum.map(coords, fn coord ->
      {closest_loc, dist} = find_closest(coord, locs)

      if in_margin?(coord, margins) do
        {closest_loc, :inf}
      else
        {closest_loc, dist}
      end
    end)
  end

  defp reject_infinites(distances) do
    infinite_areas =
      distances
      |> Enum.filter(&(elem(&1, 1) == :inf))
      |> Enum.map(&elem(&1, 0))
      |> MapSet.new()

    distances
    |> Enum.reject(&MapSet.member?(infinite_areas, elem(&1, 0)))
  end

  defp in_margin?(coord, {min_x, max_x, min_y, max_y}) do
    case coord do
      {^min_x, _} -> true
      {^max_x, _} -> true
      {_, ^min_y} -> true
      {_, ^max_y} -> true
      _ -> falsex2
    end
  end

  def part1() do
    {locs, coords, margins} =
      "./inputs/day6.txt"
      |> prepare_locs()
      |> prepare_coords()

    mark_area(locs, coords, margins)
    |> reject_infinites()
    |> Enum.frequencies_by(&elem(&1, 0))
    |> Enum.max_by(&elem(&1, 1))
  end

  def part2() do
    "./inputs/day6.txt"
    |> prepare_locs()
    |> prepare_coords()
    |> calculate_distance()
    |> Enum.filter(&(&1 < 10000))
    |> length()
  end
end

DaySix.part1()
|> IO.inspect()
