defmodule FluentTest do
  use ExUnit.Case, async: true

  describe "put_locale" do
    test "it puts locale in current process store" do
      Fluent.put_locale("en-US")
      assert "en-US" = Process.get(Fluent)
    end

     test "it rises if the locale is not binary" do
       assert_raise ArgumentError, fn ->
        Fluent.put_locale(1234)
       end
     end
  end

  describe "get_locale" do
    test "it gets default's Fluent Assembly default locale" do
      assert Fluent.get_locale(Assembly.Empty) == "en"
    end

    test "it get overrided Floent Assembly default locale" do
      assert Fluent.get_locale(Assembly.DefaultLanguageChanged) == "es"
    end

    test "it get global Fluent locale if defined" do
      Fluent.put_locale("jp")
      assert Fluent.get_locale(Assembly.Empty) == "jp"
    end

    test "it get defined for current process assembly locale" do
      Fluent.put_locale(Assembly.Empty, "fr")
      Fluent.put_locale(Assembly.DefaultLanguageChanged, "ru")
      assert Fluent.get_locale(Assembly.Empty) == "fr"
      assert Fluent.get_locale(Assembly.DefaultLanguageChanged) == "ru"
    end
  end
end
