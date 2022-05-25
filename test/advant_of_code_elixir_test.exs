defmodule AdvantOfCodeElixirTest do
  use ExUnit.Case
  doctest AdvantOfCodeElixir

  test "greets the world" do
    assert AdvantOfCodeElixir.hello() == :world
  end
end
