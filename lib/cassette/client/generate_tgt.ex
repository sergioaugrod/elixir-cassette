defmodule Cassette.Client.GenerateTgt do
  @moduledoc """
  Generates CAS Ticket Granting Tickets
  """

  use HTTPotion.Base
  use Cassette.Client.UrlEncodedHeaders

  alias Cassette.Config
  alias Cassette.Client

  @type response :: {:error, :bad_credentials}
                  | {:ok, String.t}
                  | {:fail, pos_integer()}
                  | {:fail, :unknown}

  @doc """
  Do request to cas service to get a ticket granting tickets from user
  """
  @spec perform(Config.t) :: response
  def perform(config = %Config{username: username, password: password, base_url: base_url}) do
    form_data = "username=#{URI.encode_www_form(username)}&password=#{URI.encode_www_form(password)}"

    case post("#{base_url}/v1/tickets", Keyword.merge(Client.options(config), body: form_data, headers: [Accept: "*/*"])) do
      %HTTPotion.Response{status_code: 400} -> {:error, :bad_credentials}
      %HTTPotion.Response{status_code: 201, headers: headers} -> {:ok, extract_tgt(base_url, headers[:location])}
      %HTTPotion.Response{status_code: status_code} -> {:fail, status_code}
      _ -> {:fail, :unknown}
    end
  end

  @spec extract_tgt(String.t, String.t) :: String.t
  defp extract_tgt(base_url, location) when is_binary(location) do
    String.replace_leading(location, "#{base_url}/v1/tickets/", "")
  end
end
