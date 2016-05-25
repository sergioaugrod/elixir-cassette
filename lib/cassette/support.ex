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
  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @name opts[:process_name] || :CassetteServer
      @config Keyword.get(opts, :config)

      @spec start(term, term) :: GenServer.on_start

      def start(_, _), do: start

      @spec start() :: GenServer.on_start
      @doc false
      def start do
        import Supervisor.Spec

        children = [
          worker(Cassette.Server, [@name, config])
        ]

        options = [strategy: :one_for_one, name: :"#{@name}.Supervisor"]

        case Supervisor.start_link(children, options) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          other -> other
        end
      end

      @spec child_spec() :: Supervisor.Spec.spec

      def child_spec do
        {__MODULE__, {__MODULE__, :start, []}, :permanent, 5000, :worker, [__MODULE__]}
      end

      @spec config :: Cassette.Config.t
      @doc """
      Returns the configuration used by this Cassette server

      Will return the default configuration if not provided.

      Please refer to `Cassette.Config.t` for details
      """
      def config do
        @config || Cassette.Config.default
      end

      @spec tgt :: {:ok, String.t} | {:error, term}
      @doc """
      Generates a Ticket Granting Ticket
      """
      def tgt do
        Cassette.Server.tgt(@name)
      end

      @spec st(String.t) :: {:ok, String.t} | {:error, term}
      @doc """
      Generates a Service Ticket for the given `service`
      """
      def st(service) do
        {:ok, current_tgt} = tgt
        Cassette.Server.st(@name, current_tgt, service)
      end

      @spec validate(String.t, String.t) :: {:ok, Cassette.User.t} | {:error, term}
      @doc """
      Validates a given `ticket` against the given `service` or the service set in the configuration
      """
      def validate(ticket, service \\ config.service) do
        Cassette.Server.validate(@name, ticket, service)
      end

      @doc false
      def reload(cfg \\ config) do
        Cassette.Server.reload(@name, cfg)
      end
    end
  end
end
