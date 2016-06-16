defmodule Cassette.Client.ValidateTicket do
  @moduledoc """
  Validates a CAS Service Ticket
  """

  use HTTPoison.Base

  alias Cassette.Config
  alias Cassette.Client

  @type response :: {:ok, String.t} | {:fail, :unknown}

  @doc """
  Do request to cas service to validate a service ticket
  """
  @spec perform(Config.t, String.t, String.t) :: response
  def perform(config = %Config{base_url: base_url}, ticket, service) do
    case get("#{base_url}/serviceValidate", [], options([params: [service: service, ticket: ticket]], config)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
      _ -> {:fail, :unknown}
    end
  end

  defp options(base, config) do
    Keyword.merge(base, Client.options(config))
  end
end
