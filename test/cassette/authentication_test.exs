defmodule Cassette.AuthenticationTest do
  use ExUnit.Case, async: true
  alias Cassette.Authentication
  alias Cassette.User

  setup context do
    {:ok, content} = File.read("test/fixtures/cas/#{context[:file_name]}")
    {:ok, file_content: content}
  end

  @tag file_name: "failure.xml"
  test "handle_response/1 fails when authentication fail", %{file_content: file_content} do
    assert {:error, "INVALID_SERVICE: ticket 'X' is invalid"} =  Authentication.handle_response(file_content)
  end

  @tag file_name: "failure_no_special_chars.xml"
  test "handle_response/1 fails when authentication fail with no special chars in body", %{file_content: file_content} do
    assert {:error, "INVALID_SERVICE: ticket is invalid"} = Authentication.handle_response(file_content)
  end

  @tag file_name: "success.xml"
  test "handle_response/1 returns {:ok, User} with the user type", %{file_content: file_content} do
    expected = User.new("example", "employee", ["ACME_ADMIN"])
    assert {:ok, ^expected} = Authentication.handle_response(file_content)
  end

  @tag file_name: "systems_success.xml"
  test "handle_response/1 returns {:ok, User} with empty user type", %{file_content: file_content} do
    expected = User.new("example", "", ["ACME_ADMIN"])
    assert {:ok, ^expected} = Authentication.handle_response(file_content)
  end
end
