defmodule Cassette.Version do
  @moduledoc """
  Elixir version conditional see `version/2`.
  """

  @doc """
  Receives a condition just like `Version.requirement()`, tests if the current
  elixir version matches that condition and executes the `do` block or the
  `else` block otherwise.

  The else block is optional and defaults to doing nothing.
  """
  defmacro version(condition, do: do_fun, else: else_fun) do
    if(
      System.version() |> Version.parse!() |> Version.match?(condition),
      do: do_fun,
      else: else_fun
    )
  end

  defmacro version(condition, do: do_fun) do
    quote do
      version(unquote(condition), do: unquote(do_fun), else: nil)
    end
  end
end
