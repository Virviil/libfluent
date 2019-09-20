defmodule Fluent.NativeTest do
  use ExUnit.Case, async: true

  describe "Fluent Native init" do
    test "it initializes bundle with valid locale" do
      assert {:ok, ref} = Fluent.Native.init("en")
    end

    test "it fails with init for invalid locale" do
      assert {:error, {:bad_locale, "this-is-wrong-locale"}} = Fluent.Native.init("this-is-wrong-locale")
    end
  end
end
