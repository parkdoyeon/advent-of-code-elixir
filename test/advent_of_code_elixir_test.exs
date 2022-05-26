defmodule AdventOfCodeElixirTest do
  use ExUnit.Case
  doctest AdventOfCodeElixir

  test "greets the world" do
    assert AdventOfCodeElixir.hello() == :world
  end
end
