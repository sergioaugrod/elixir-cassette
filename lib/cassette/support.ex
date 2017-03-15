defmodule Cassette.Support do
  @moduledoc """
  This macro module allows you to create your own Cassette service with custom configurations

  You can customize the (otp) application name with the `:process_name` key and provide your
  configuration in the `:config` key.

  ```elixir
  defmodule MyCas do
    use Cassette.Support, process_name: :EmployeesCas,
      config: %{ Cassette.Config.default | base_url: "https://employees-cas.example.org" }
  end
  ```

  Please refer to `Cassette` for usage

  """

  alias Cassette.Config
  alias Cassette.Server
  alias Cassette.User

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      use Application

      @name opts[:process_name] || :CassetteServer
      @config opts[:config]

      @doc false
      @spec start(term, term) :: GenServer.on_start
      def start(_, _), do: start()

      @doc false
      @spec start() :: GenServer.on_start
      def start do
        import Supervisor.Spec

        children = [
          worker(Server, [@name, @config])
        ]

        options = [strategy: :one_for_one, name: :"#{@name}.Supervisor"]

        case Supervisor.start_link(children, options) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          other -> other
        end
      end

      @doc false
      @spec child_spec() :: Supervisor.Spec.spec
      def child_spec do
        {__MODULE__, {__MODULE__, :start, []}, :permanent, 5000, :worker, [__MODULE__]}
      end

      @doc """
      Returns the configuration used by this Cassette server

      Will return the default configuration if not provided.

      Please refer to `Cassette.Config.t` for details
      """
      @spec config :: Config.t
      def config do
        Server.config(@name)
      end

      @doc """
      Generates a Ticket Granting Ticket
      """
      @spec tgt :: {:ok, String.t} | {:error, term}
      def tgt do
        Server.tgt(@name)
      end

      @doc """
      Generates a Service Ticket for the given `service`

      This function retries once when the TGT is expired on the server side.
      """
      @spec st(String.t) :: {:ok, String.t} | {:error, term}
      def st(service) do
        {:ok, current_tgt} = tgt()
        case Server.st(@name, current_tgt, service) do
          {:error, :tgt_expired} ->
            {:ok, new_tgt} = tgt()
            Server.st(@name, new_tgt, service)

          reply ->
            reply
        end
      end

      @doc """
      Validates a given `ticket` against the given `service` or the service set in the configuration
      """
      @spec validate(String.t, String.t) :: {:ok, User.t} | {:error, term}
      def validate(ticket, service \\ config().service) do
        Server.validate(@name, ticket, service)
      end

      @doc false
      @spec reload(Config.t) :: term
      def reload(cfg \\ Config.default) do
        Server.reload(@name, cfg)
      end
    end
  end
end
