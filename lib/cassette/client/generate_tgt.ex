defmodule Cassette.Client.GenerateTgt do
  @moduledoc """
  Generates CAS Ticket Granting Tickets
  """

  use HTTPoison.Base

  @type response :: {:error, :bad_credentials} | {:ok, String.t} | {:fail, pos_integer()} | {:fail, :unknown}

  @spec process_headers([{String.t, String.t}]) :: %{String.t => String.t}
  defp process_headers(headers), do: Enum.into(headers, %{}, fn{k, v} -> {String.downcase(k), v} end)

  @doc """
  Do request to cas service to get a ticket granting tickets from user
  """
  @spec perform(Cassette.Config.t) :: response
  def perform(config = %Cassette.Config{username: username, password: password, base_url: base_url}) do
    case post("#{base_url}/v1/tickets", {:form, [username: username, password: password]}, %{accept: "*/*"}, Cassette.Client.options(config)) do
      {:ok, %HTTPoison.Response{status_code: 400}} -> {:error, :bad_credentials}
      {:ok, %HTTPoison.Response{status_code: 201, headers: %{"location" => location}}} -> {:ok, extract_tgt(base_url, location)}
      {:ok, %HTTPoison.Response{status_code: status_code}} -> {:fail, status_code}
      _ -> {:fail, :unknown}
    end
  end

  @spec extract_tgt(String.t, String.t) :: String.t
  defp extract_tgt(base_url, location) when is_binary(location) do
    String.replace_leading(location, "#{base_url}/v1/tickets/", "")
  end
end
