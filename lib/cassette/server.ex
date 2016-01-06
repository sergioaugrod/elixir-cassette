defmodule Cassette.Server do
  @moduledoc """
  The GenServer that maintains the CAS cache in its state
  """

  use GenServer

  alias Cassette.Server.State

  @spec start_link(term, Cassette.Config.t) :: GenServer.on_start
  @doc false
  def start_link(name, config) do
    GenServer.start_link(__MODULE__, {:ok, config}, name: name)
  end

  @spec validate(pid, String.t, String.t) :: {:ok, Cassette.User.t} | {:error, term}
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
  def st(server, tgt, service) do
    GenServer.call(server, {:st, tgt, service, time_now()})
  end

  @spec init({:ok, Cassette.Config.t}) :: {:ok, State.t}
  @doc """
  Initializes the server with the given configuration
  """
  def init({:ok, config}) do
    {:ok, %State{config: config}}
  end

  @doc false
  def reload(server, config) do
    GenServer.call(server, {:reload, config})
  end

  @spec handle_call({:validate, String.t, String.t, non_neg_integer()}, GenServer.from, State.t) :: {:reply, {:ok, Cassette.User.t} | {:error, term}, State.t}
  @doc false
  def handle_call({:validate, ticket, service, now}, _from, state = %State{validations: validations, config: config}) do
    case evaluate_validation(config, service, ticket, Map.get(validations, {service, ticket}), now) do
      {:ok, user, expires_at} -> {:reply, {:ok, user}, State.put_validation(state, {service, ticket}, {user, expires_at})}
      reply -> {:reply, reply, state}
    end
  end

  @spec handle_call({:st, String.t, String.t, non_neg_integer()}, GenServer.from, State.t) :: {:reply, {:ok, String.t} | {:error, term}, State.t}
  @doc false
  def handle_call({:st, current_tgt, service, now}, _from, state = %State{config: config, tgt: {:tgt, _, current_tgt}, sts: sts}) do
    case evaluate_st(config, current_tgt, service, Map.get(sts, service), now) do
      {:ok, new_st, expires_at} ->
        {:reply, {:ok, new_st}, State.put_st(state, service, {new_st, expires_at})}
      reply ->
        {:reply, reply, state}
    end
  end

  @spec handle_call({:tgt, non_neg_integer()}, GenServer.from, State.t) :: {:reply, {:ok, String.t} | {:error, term}, State.t}
  @doc false
  def handle_call({:tgt, now}, _from, state = %State{config: config, tgt: tgt}) when now > elem(tgt, 1) do
    case Cassette.Client.tgt(config) do
      {:ok, tgt} -> {:reply, {:ok, tgt}, State.put_tgt(state, tgt, time_now() + config.tgt_ttl)}
      {:error, :bad_credentials} -> {:reply, {:error, "Bad credentials"}, state}
      {:fail, :unknown} -> {:reply, {:error, "Failed for unknown reason"}, state}
      {:fail, status_code} -> {:reply, {:error, "Failed with status #{status_code}"}, state}
    end
  end

  @spec handle_call({:tgt, non_neg_integer()}, GenServer.from, State.t) :: {:reply, {:ok, String.t} | {:error, term}, State.t}
  @doc false
  def handle_call({:tgt, _}, _from, state = %State{tgt: {:tgt, _, current_tgt}}) do
    {:reply, {:ok, current_tgt}, state}
  end

  @doc false
  def handle_call({:reload, config = %Cassette.Config{}}, _from, _state) do
    {:reply, :ok, %State{config: config}}
  end

  @spec evaluate_validation(Cassette.Config.t, String.t, String.t, State.st, non_neg_integer()) :: {:ok, Cassette.User.t, non_neg_integer()}
  @doc false
  defp evaluate_validation(_, _, _, {user, expires_at}, now) when now < expires_at do
    {:ok, user, expires_at}
  end

  @spec evaluate_validation(Cassette.Config.t, String.t, String.t, State.st, non_neg_integer()) :: {:ok, Cassette.User.t, non_neg_integer()} | {:error, term}
  @doc false
  defp evaluate_validation(config, service, ticket, _, _) do
    reply = case Cassette.Client.ValidateTicket.perform(config, ticket, service) do
      {:ok, body} -> Cassette.Authentication.handle_response(body)
      {:fail, reason} -> {:error, reason}
    end

    case reply do
      {:ok, user} -> {:ok, user, time_now() + config.validation_ttl}
      reply -> reply
    end
  end

  @spec evaluate_st(Cassette.Config.t, String.t, String.t, State.st, non_neg_integer()) :: {:ok, String.t, non_neg_integer()}
  @doc false
  defp evaluate_st(_, _, _, {st, expires_at}, now) when now < expires_at do
    {:ok, st, expires_at}
  end

  @spec evaluate_st(Cassette.Config.t, String.t, String.t, State.st, non_neg_integer()) :: {:ok, String.t, non_neg_integer()} | {:error, term}
  @doc false
  defp evaluate_st(config, tgt, service, _, _) do
    reply = case Cassette.Client.st(config, tgt, service) do
      {:ok, st} -> {:ok, st, time_now() + config.st_ttl}
      {:error, :bad_tgt} -> {:error, "TGT expired"}
      {:fail, status_code, body} -> {:error, "Failed with status #{status_code}: #{body}"}
      {:fail, :unknown} -> {:error, "Failed for unknown reason"}
    end

    reply
  end

  @spec time_now :: non_neg_integer()
  @doc false
  defp time_now do
    :calendar.datetime_to_gregorian_seconds(:calendar.local_time)
  end
end
