defmodule I18n.Translator do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [locale: 2]
      Module.register_attribute(__MODULE__, :locales, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :locales))
  end

  defmacro locale(name, mappings) do
    quote bind_quoted: [name: name, mappings: mappings] do
      IO.puts("============== #{inspect(mappings)}")
      @locales {name, mappings}
    end
  end

  def compile(translations) do
    translations_ast =
      for {locale, mappings} <- translations do
        deftranslations(locale, "", mappings)
      end

    final_ast =
      quote do
        def t(locale, path, bindings \\ [])
        unquote(translations_ast)
        def t(_locale, _path, _bindings), do: {:error, :no_translation}
      end

    IO.puts(Macro.to_string(final_ast))
    final_ast
  end

  def deftranslations(locale, current_path, opts) do
    for {key, val} <- opts do
      path = append_path(current_path, key)

      if Keyword.keyword?(val) do
        deftranslations(locale, path, val)
      else
        quote do
          def t(unquote(locale), unquote(path), bindings) do
            unquote(interpolate(val))
          end
        end
      end
    end
  end

  defp append_path("", path), do: to_string(path)
  defp append_path(current_path, key), do: "#{current_path}.#{key}"

  defp interpolate(string) do
    ~r/(?<head>)%{[^}]+}(?<tail>)/
    |> Regex.split(string, on: [:head, :tail])
    |> IO.inspect()
    |> Enum.reduce("", fn
      <<"%{" <> rest>>, acc ->
        key = String.to_atom(String.rstrip(rest, ?}))

        quote do
          unquote(acc) <> to_string(Dict.fetch!(bindings, unquote(key)))
        end

      segment, acc ->
        quote do: unquote(acc) <> unquote(segment)
    end)
  end
end

# defmodule I18n.TranslatorHelper do
#   def run()
# end
