defmodule Cassette.Client.GenerateTgtTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open
    base_url = "http://localhost:#{bypass.port}"
    config = %{Cassette.Config.default | base_url: base_url}

    {:ok, bypass: bypass, config: config}
  end

  test "perform returns :bad_credentials for a 400 response", %{bypass: bypass, config: config} do
    Bypass.expect bypass, fn conn ->
      Plug.Conn.resp(conn, 400, "bad bad bad")
    end

    assert {:error, :bad_credentials} = Cassette.Client.GenerateTgt.perform(config)
  end

  test "perform returns {:fail, status_code} for other error statuses", %{bypass: bypass, config: config} do
    Bypass.expect bypass, fn conn ->
      Plug.Conn.resp(conn, 404, "not found")
    end

    assert {:fail, 404} = Cassette.Client.GenerateTgt.perform(config)
  end

  test "perform generates a TGT", %{bypass: bypass, config: config} do
    tgt = "TGT-bla"
    location = "#{config.base_url}/v1/tickets/#{tgt}"

    Bypass.expect bypass, fn c ->
      conn = Plug.Parsers.call(c, [parsers: [Plug.Parsers.URLENCODED]])

      assert "/v1/tickets" == conn.request_path
      assert "POST" == conn.method
      assert conn.body_params["username"] == config.username
      assert conn.body_params["password"] == config.password

      conn
      |> Plug.Conn.put_resp_header("Location", location)
      |> Plug.Conn.resp(201, "")
    end

    assert {:ok, ^tgt} = Cassette.Client.GenerateTgt.perform(config)
  end
end
