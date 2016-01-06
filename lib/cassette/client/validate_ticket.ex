defmodule Cassette.Client.ValidateTicket do
  @moduledoc """
  Validates a CAS Service Ticket
  """

  use HTTPoison.Base

  @type response :: {:ok, String.t} | {:fail, :unknown}

  @doc """
  Do request to cas service to validate a service ticket
  """
  @spec perform(Cassette.Config.t, String.t, String.t) :: response
  def perform(config = %Cassette.Config{base_url: base_url}, ticket, service) do
    case post("#{base_url}/serviceValidate", {:form, [service: service, ticket: ticket]}, [], Cassette.Client.options(config)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
      _ -> {:fail, :unknown}
    end
  end
end
