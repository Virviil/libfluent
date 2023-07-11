defmodule Fluent.NativeTest do
  use ExUnit.Case, async: true

  describe "Fluent Native init" do
    test "it initializes bundle with valid locale" do
      assert {:ok, _} = Fluent.Native.init("en")
    end

    test "it fails with init for invalid locale" do
      assert {:error, {:bad_locale, "this-is-wrong-locale"}} =
               Fluent.Native.init("this-is-wrong-locale")
    end
  end

  describe "with_resource" do
    setup do
      case Fluent.Native.init("en") do
        {:ok, reference} -> %{bundle: reference}
        _ -> :error
      end
    end

    test "it adds valid resource", %{bundle: bundle} do
      assert :ok = Fluent.Native.with_resource(bundle, "a = A")
    end

    test "it fails with bad resource", %{bundle: bundle} do
      assert {:error, :bad_resource} = Fluent.Native.with_resource(bundle, "bad resource")
    end

    test "it adds message to the bundle", %{bundle: bundle} do
      assert {:error, :bad_msg} = Fluent.Native.format_pattern(bundle, "a", [])
      Fluent.Native.with_resource(bundle, "a = A")
      assert {:ok, "A"} = Fluent.Native.format_pattern(bundle, "a", [])
    end

    test "it uses isolation by default", %{bundle: bundle} do
      assert {:error, :bad_msg} = Fluent.Native.format_pattern(bundle, "a", [])
      Fluent.Native.with_resource(bundle, "hello-user = Hello, {$userName}!")

      assert {:ok, "Hello, \u2068Test User\u2069!"} =
               Fluent.Native.format_pattern(bundle, "hello-user", userName: "Test User")
    end
  end

  describe "without isolation" do
    setup do
      case Fluent.Native.init("en", use_isolating: false) do
        {:ok, reference} -> %{bundle: reference}
        _ -> :error
      end
    end

    test "it uses no isolation", %{bundle: bundle} do
      assert {:error, :bad_msg} = Fluent.Native.format_pattern(bundle, "a", [])
      Fluent.Native.with_resource(bundle, "hello-user = Hello, {$userName}!")

      assert {:ok, "Hello, Test User!"} =
               Fluent.Native.format_pattern(bundle, "hello-user", userName: "Test User")
    end
  end
end
