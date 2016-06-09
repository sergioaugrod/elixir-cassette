defmodule Cassette.Server do
  @moduledoc """
  The GenServer that maintains the CAS cache in its state
  """

  use GenServer

  alias Cassette.Authentication
  alias Cassette.Client
  alias Cassette.Client.ValidateTicket
  alias Cassette.Config
  alias Cassette.Server.State
  alias Cassette.User

  @type tgt_request :: {:tgt, non_neg_integer()}
  @type tgt_reply :: {:ok, String.t} | {:error, term}

  @type st_request :: {:st, String.t, String.t, non_neg_integer()}
  @type st_reply :: {:ok, String.t} | {:error, term}

  @type validate_request :: {:validate, String.t, String.t, non_neg_integer()}
  @type validate_reply :: {:ok, User.t} | {:error, term}

  @type reload_request :: {:reload, Config.t}
  @type reload_reply :: :ok

  @type config_request :: {:config}
  @type config_reply :: Config.t

  @spec start_link(term, Config.t) :: GenServer.on_start

  @doc false

  def start_link(name, config) do
    GenServer.start_link(__MODULE__, {:ok, config}, name: name)
  end

  @spec validate(pid, String.t, String.t) :: {:ok, User.t} | {:error, term}

  @doc """
  Validates a `ticket` for the given `service`
  """

  def validate(server, ticket, service) do
    GenServer.call(server, {:validate, ticket, service, time_now()})
  end

  @spec tgt(pid) :: {:ok, String.t} | {:error, term}

  @doc """
  Generates a Ticket Granting Ticket based on the configuration of the `server`
  """

  def tgt(server) do
    GenServer.call(server, {:tgt, time_now()})
  end

  @spec st(pid, String.t, String.t) :: {:ok, String.t} | {:error, term}

  @doc """
  Generates Service Ticket based on the configuration of the `server` and the given `tgt`
  """

  def st(server, current_tgt, service) do
    GenServer.call(server, {:st, current_tgt, service, time_now()})
  end

  @doc """
  Returns this server's current configuration
  """

  @spec config(pid) :: Config.t

  def config(server) do
    GenServer.call(server, {:config})
  end

  @spec init({:ok, Config.t}) :: {:ok, State.t}

  @doc """
  Initializes the server with the given configuration
  """

  def init({:ok, config}) do
    {:ok, %State{config: Config.resolve(config)}}
  end

  @doc """
  Changes the internal state configuration to `config`
  """

  def reload(server, config) do
    GenServer.call(server, {:reload, config})
  end

  @spec handle_call(
    validate_request | st_request | tgt_request | reload_request | config_request,
    GenServer.from,
    State.t
  ) :: {:reply, validate_reply | tgt_reply | st_reply | reload_reply | config_reply, State.t}

  def handle_call({:validate, ticket, service, now}, _from, state = %State{validations: validations, config: config}) do
    case evaluate_validation(config, service, ticket, Map.get(validations, {service, ticket}), now) do
      {:ok, user, expires_at} ->
        {:reply, {:ok, user}, State.put_validation(state, {service, ticket}, {user, expires_at})}

      reply ->
        {:reply, reply, state}
    end
  end

  def handle_call({:config}, _from, state = %State{config: config}) do
    {:reply, config, state}
  end

  def handle_call({:st, current_tgt, service, now}, _from, state = %State{config: config, tgt: {:tgt, _, current_tgt}, sts: sts}) do
    case evaluate_st(config, current_tgt, service, Map.get(sts, service), now) do
      {:ok, new_st, expires_at} ->
        {:reply, {:ok, new_st}, State.put_st(state, service, {new_st, expires_at})}
      reply ->
        {:reply, reply, state}
    end
  end

  def handle_call({:tgt, now}, _from, state = %State{config: config, tgt: current_tgt}) when now > elem(current_tgt, 1) do
    case Client.tgt(config) do
      {:ok, new_tgt} -> {:reply, {:ok, new_tgt}, State.put_tgt(state, new_tgt, time_now() + config.tgt_ttl)}
      {:error, :bad_credentials} -> {:reply, {:error, "Bad credentials"}, state}
      {:fail, :unknown} -> {:reply, {:error, "Failed for unknown reason"}, state}
      {:fail, status_code} -> {:reply, {:error, "Failed with status #{status_code}"}, state}
    end
  end

  def handle_call({:tgt, _}, _from, state = %State{tgt: {:tgt, _, current_tgt}}) do
    {:reply, {:ok, current_tgt}, state}
  end

  def handle_call({:reload, config = %Config{}}, _from, _state) do
    {:ok, state} = init({:ok, config})
    {:reply, :ok, state}
  end

  @spec evaluate_validation(Config.t, String.t, String.t, State.st, non_neg_integer()) ::
    {:ok, User.t, non_neg_integer()}

  defp evaluate_validation(_, _, _, {user, expires_at}, now) when now < expires_at do
    {:ok, user, expires_at}
  end

  @spec evaluate_validation(Config.t, String.t, String.t, State.st, non_neg_integer()) ::
    {:ok, User.t, non_neg_integer()} | {:error, term}

  defp evaluate_validation(config, service, ticket, _, _) do
    reply = case ValidateTicket.perform(config, ticket, service) do
      {:ok, body} -> Authentication.handle_response(body)
      {:fail, reason} -> {:error, reason}
    end

    case reply do
      {:ok, user} -> {:ok, user, time_now() + config.validation_ttl}
      reply -> reply
    end
  end

  @spec evaluate_st(Config.t, String.t, String.t, State.st, non_neg_integer()) :: {:ok, String.t, non_neg_integer()}

  defp evaluate_st(_, _, _, {current_st, expires_at}, now) when now < expires_at do
    {:ok, current_st, expires_at}
  end

  @spec evaluate_st(Config.t, String.t, String.t, State.st, non_neg_integer()) ::
    {:ok, String.t, non_neg_integer()} | {:error, term}

  defp evaluate_st(config, current_tgt, service, _, _) do
    reply = case Client.st(config, current_tgt, service) do
      {:ok, new_st} -> {:ok, new_st, time_now() + config.st_ttl}
      {:error, :bad_tgt} -> {:error, "TGT expired"}
      {:fail, status_code, body} -> {:error, "Failed with status #{status_code}: #{body}"}
      {:fail, :unknown} -> {:error, "Failed for unknown reason"}
    end

    reply
  end

  @spec time_now :: non_neg_integer()

  defp time_now do
    :calendar.datetime_to_gregorian_seconds(:calendar.local_time)
  end
end
