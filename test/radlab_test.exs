defmodule RadlabTest do
  use ExUnit.Case
  doctest Radlab

  test "greets the world" do
    assert Radlab.hello() == :world
  end
end
