defmodule Cassette.User do
  @moduledoc """
  This is the struct that represents the user returned by a Validation request
  """

  alias Cassette.User
  alias Cassette.Config

  defstruct login: "", type: "", authorities: MapSet.new([])

  @type t :: %__MODULE__{login: String.t}

  @doc """
  Initializes a `Cassette.User` struct, mapping the list of authorities to it's internal representation
  """
  @spec new(String.t, [String.t]) :: User.t
  def new(login, authorities) do
    new(login, "", authorities)
  end

  @doc """
  Initializes a `Cassette.User` struct, with a `type` attribute and mapping the list of authorities to it's internal representation
  """
  @spec new(String.t, String.t, [String.t]) :: User.t
  def new(login, type, authorities) do
    %User{login: login, type: String.downcase(type), authorities: MapSet.new(authorities)}
  end

  @doc """
  Tests if the user has the given `role` respecting the `base_authority` set in the default configuration

  If your `base_authority` is `ACME` and the user has the `ACME_ADMIN` authority, then the following is true:

  ```elixir
  iex> Cassette.User.has_role?(some_user, "ADMIN")
  true
  ```

  This function returns false when user is not a Cassette.User.t

  """
  @spec has_role?(User.t | any, String.t | any) :: boolean
  def has_role?(user = %User{}, role) do
    User.has_role?(user, Config.default, role)
  end

  def has_role?(_, _), do: false

  @doc """
  Tests if the user has the given `role` using the `base_authority` set in the default configuration

  If you are using custom a `Cassette.Support` server you can use this function to respect it's `base_authority`

  This function returns false when user is not a Cassette.User.t

  """
  @spec has_role?(User.t | any, Config.t | any, String.t | any) :: boolean
  def has_role?(user = %User{}, %Config{base_authority: base}, role) do
    User.has_raw_role?(user, to_raw_role(base, role))
  end

  def has_role?(_, _, _), do: false

  @doc """
  Tests if the user has the given `role`.
  This function does not alter the role when checking against the list of authorities.

  If your user has the `ACME_ADMIN` authority the following is true:

  ```elixir
  iex> Cassette.User.has_role?(some_user, "ACME_ADMIN")
  true
  ```

  This function returns false when user is not a Cassette.User.t

  """
  @spec has_raw_role?(User.t | any, String.t | any) :: boolean
  def has_raw_role?(%User{authorities: authorities}, raw_role) do
    MapSet.member?(authorities, String.upcase("#{raw_role}"))
  end

  def has_raw_role?(_, _), do: false

  @spec to_raw_role(String.t | nil, String.t) :: String.t
  defp to_raw_role(base, role) do
    [base, role]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("_")
  end
end
