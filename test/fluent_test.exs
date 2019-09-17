defmodule FluentTest do
  use ExUnit.Case
  doctest Fluent

  test "greets the world" do
    assert Fluent.hello() == :world
  end
end
