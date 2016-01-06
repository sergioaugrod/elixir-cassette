defmodule Cassette.ServerIntegrationTest do
  use ExUnit.Case, async: false

  alias Cassette.Server

  setup do
    config = FakeCas.Support.config
    invalid_config = %{config | username: "x"}

    {:ok, pid} = Cassette.Server.start_link(:CassetteIntegrationTest, config)
    {:ok, invalid_pid} = Cassette.Server.start_link(:CassetteIntegrationTestWithInvalidConfig, invalid_config)
    {:ok, [pid: pid, config: config, invalid_pid: invalid_pid]}
  end

  test "generates a correct tgt", %{pid: pid} do
    tgt = FakeCas.valid_tgt
    assert {:ok, ^tgt} = Server.tgt(pid)
  end

  test "fails with {:error, _} when username/password is invalid", %{invalid_pid: pid} do
    assert {:error, "Bad credentials"} = Server.tgt(pid)
  end

  test "generates a st from the tgt", %{pid: pid} do
    st = FakeCas.valid_st
    {:ok, tgt} = Server.tgt(pid)
    ^tgt = FakeCas.valid_tgt
    assert {:ok, ^st} = Server.st(pid, FakeCas.valid_tgt, "service")
  end

  test "validates a st", %{pid: pid, config: config} do
    {:ok, _} = Server.tgt(pid)
    assert {:ok, %Cassette.User{login: "example"}} = Server.validate(pid, FakeCas.valid_st, config.service)
  end

  test "return an {:error, _} for an invalid ticket", %{pid: pid, config: config} do
    assert {:error, _} = Server.validate(pid, "some-invalid-ticket", config.service)
  end
end
