defmodule Cassette.Authentication do
  @moduledoc """
  ST validation functions
  """

  alias Cassette.User

  @doc """
  Extracts the authenticated user from validation response

  Returns a tuple with:

  * `{:ok, Cassette.User.t}` on success
  * `{:error, String.t}` on error where the string is the failure reason
    returned by the cas server
  """
  @spec handle_response(String.t) :: {:ok, User.t} | {:error, String.t}
  def handle_response(body) do
    import SweetXml

    xml = SweetXml.parse(body)

    failure = {
      to_string(SweetXml.xpath(xml, ~x"//cas:authenticationFailure/text()"o)),
      to_string(SweetXml.xpath(xml, ~x"//cas:authenticationFailure/@code"o))
    }

    case failure do
      {"", ""} ->
        extract_user(xml)

      {reason, code} when is_binary(reason) ->
        {:error, "#{code}: #{String.strip(reason)}"}
    end
  end

  @spec extract_user(any) :: {:ok, User.t} | {:error}
  defp extract_user(xml) do
    import SweetXml

    login = xpath(xml, ~x"//cas:authenticationSuccess/cas:user/text()"os)

    if login && login != "" do
      attributes_path = "//cas:authenticationSuccess/cas:attributes"
      mapping = [name: ~x"local-name()"s, value: ~x"text()"s]

      all_attributes =
        xml
        |> xpath(~x"#{attributes_path}/*"l, mapping)
        |> Enum.map(fn attr -> {attr.name, attr.value} end)
        |> Enum.into(%{})

      {special, attributes} = Map.split(all_attributes, ["authorities", "type"])

      authorities =
        special
        |> Map.get("authorities", "")
        |> String.lstrip(?[)
        |> String.strip(?])
        |> String.split(~r(,\s*))

      {:ok, User.new(login, special["type"] || "", authorities, attributes)}
    else
      {:error, "invalid response from cas server"}
    end
  end
end
