defmodule Cassette.Authentication do
  @moduledoc """
  ST validation functions
  """

  alias Cassette.User

  @spec handle_response(String.t) :: {:ok, Cassette.User.t} | {:error, String.t}
  @doc """
  Extracts the authenticated user from validation response

  Returns a tuple with:

  * `{:ok, Cassette.User.t}` on success
  * `{:error, String.t}` on error where the string is the failure reason returned by the cas server
  """
  def handle_response(body) do
    xml = Exml.parse(body)
    failure = {Exml.get(xml, "//cas:authenticationFailure"), Exml.get(xml, "//cas:authenticationFailure/@code")}

    case failure do
      {nil, nil} -> extract_user(xml)
      {reason, code} when is_binary(reason) -> {:error, "#{code}: #{String.strip(reason)}"}
      {reason, code} when is_list(reason) -> {:error, "#{code}: #{String.strip(Enum.join(reason, ""))}"}
    end
  end

  @spec extract_user(any) :: {:ok, Cassette.User.t} | {:error}
  defp extract_user(xml) do
    login = Exml.get(xml, "//cas:authenticationSuccess/cas:user")
    authorities  = Exml.get(xml, "//cas:authenticationSuccess/cas:attributes/cas:authorities")
    |> String.lstrip(?[)
    |> String.strip(?])
    |> String.split(", ")

    if login do
      {:ok, User.new(login, authorities)}
    else
      {:error}
    end
  end
end
