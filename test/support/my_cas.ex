defmodule MyCas do
  @moduledoc false

  use Cassette.Support, process_name: :MyCasServer, config:
    %{ Cassette.Config.default | base_authority: "ME",
      password: {:system, "CASSETTE_TEST_PASSWORD"} }
end
