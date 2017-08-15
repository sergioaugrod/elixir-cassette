defmodule Cassette.Client.UrlEncodedHeaders do
  @moduledoc """
  Macros for adding functions that process form/url-encoded requests
  """

  defmacro __using__(_opts) do
    quote do
      @doc """
      Append required headers for form/url-encoded requests
      """
      @spec process_request_headers(Keyword.t) :: Keyword.t
      def process_request_headers(headers) do
        Keyword.merge(["Content-Type": "application/x-www-form-urlencoded"],
                      headers)
      end
    end
  end
end
