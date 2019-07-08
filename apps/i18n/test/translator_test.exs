# =================================
# Below lines required only if tested using `elixir test/while_test.exs`
# If Tested using mix test its not required
ExUnit.start()
Code.require_file("../lib/i18n/translator.ex", __DIR__)
# ======================================

defmodule TranslatorTest do
  use ExUnit.Case

  defmodule I18nTest do
    use I18n.Translator

    locale("en",
      foo: "bar",
      flash: [
        notice: [
          alert: "Alert!",
          hello: "hello %{first} %{last}!"
        ]
      ],
      users: [
        title: "Users",
        profile: [title: "Profiles"]
      ]
    )

    locale("fr",
      flash: [
        notice: [
          hello: "salut %{first} %{last}!"
        ]
      ]
    )
  end

  test "it recursively walks translations tree" do
    assert I18nTest.t("en", "users.title") == "Users"
    assert I18nTest.t("en", "users.profile.title") == "Profiles"
  end

  test "it handles translations at root level" do
    assert I18nTest.t("en", "foo") == "bar"
  end

  test "it allows multiple locales to be registered" do
    assert I18n.t("fr", "flash.notice.hello", first: "Jaclyn", last: "M") ==
             "salut Jaclyn M!"
  end

  test "it iterpolates bindings" do
    assert I18n.t("en", "flash.notice.hello", first: "Jason", last: "S") ==
             "hello Jason S!"
  end

  test "t/3 raises KeyError when bindings not provided" do
    assert_raise KeyError, fn -> I18n.t("en", "flash.notice.hello") end
  end

  test "t/3 returns {:error, :no_translation} when translation is missing" do
    assert I18n.t("en", "flash.not_exists") == {:error, :no_translation}
  end

  test "converts interpolation values to string" do
    assert I18n.t("fr", "flash.notice.hello", first: 123, last: 456) ==
             "salut 123 456!"
  end
end
