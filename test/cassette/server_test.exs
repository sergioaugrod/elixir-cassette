defmodule Cassette.ServerTest do
  use ExUnit.Case, async: true

  alias Cassette.Server

  setup do
    {:ok, [state: %Server.State{config: Cassette.Config.default}]}
  end

  test "handling a st message when st is not expired returns the cached value", %{state: state} do
    now = time_now()
    st = "SOME-ST"
    tgt = "SOME-TGT"
    service = "api.example.org"
    new_state =
      state
      |> Server.State.put_tgt(tgt, now + 60)
      |> Server.State.put_st(service, {st, now + 60})

    assert {:reply, {:ok, ^st}, ^new_state} = Server.handle_call({:st, tgt, service, now}, {self, :bla}, new_state)
  end

  test "handling a tgt message when tgt is not expired returns the cached value", %{state: state} do
    now = time_now()

    new_state = Server.State.put_tgt(state, "SOME-TGT", now + 60)

    assert {:reply, {:ok, "SOME-TGT"}, ^new_state} = Server.handle_call({:tgt, now}, {self, :bla}, new_state)
  end

  defp time_now do
    :calendar.datetime_to_gregorian_seconds(:calendar.local_time)
  end
end
