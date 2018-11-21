defmodule LightTest do
  use ExUnit.Case
  doctest Light

  test "greets the world" do
    assert Light.hello() == :world
  end
end
