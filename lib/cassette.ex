defmodule Cassette do
  @moduledoc """
  Library to generate and validate [CAS](http://jasig.github.io/cas/) TGTs/STs

  ## Client usage

  Generate a tgt and a st for some service:

  ```elixir

  iex> Cassette.tgt
  {:ok, "TGT-example-abcd"}

  iex> Cassette.st("http://some.authenticated/url")
  {:ok, "ST-example-1234"}

  ```

  ## Validation usage:

  ```elixir

  iex> st = FakeCas.valid_st
  iex> Cassette.validate(st, "http://some.authenticated/url")
  {:ok, Cassette.User.new("example", "customer", ["ACME_ADMIN"])}

  ```

  ## Customization and multiple configurations

  If you need multiple Cassette servers please refer to `Cassette.Support` for macros
  that allow to build your own services.

  ## Running on development without an actual CAS server

  The `FakeCas` module we use for testing is available on `:dev` as well.

  To set it up and configure the default `Cassette`, add to yor dependencies on `mix.exs`:

  ```elixir

  {:fake_cas, "~> 1.0"}

  ```

  Then initialize it with:

  ```elixir

  iex> FakeCas.Support.initialize
  :ok

  ```

  With the configuration set, `Cassette` will always return the TGT in `FakeCas.valid_tgt/0`:

  ```
  iex> tgt = FakeCas.valid_tgt
  iex> {:ok, ^tgt} = Cassette.tgt
  {:ok, "TGT-example-abcd"}

  ```

  Using the stored valid TGT, `Casette` will always generate the same ST:

  ```elixir

  iex> st = FakeCas.valid_st
  iex> {:ok, ^st} = Cassette.st("some-service")
  {:ok, "ST-example-1234"}

  ```

  Trying to validate the ST in `FakeCas.valid_st/0` will always succeed for any service:

  ```elixir

  iex> st = FakeCas.valid_st
  iex> {:ok, _} = Cassette.validate(st, "some-service")
  {:ok, Cassette.User.new("example", "customer", ["ACME_ADMIN"])}

  ```

  And trying to validate any other ST will always fail:

  ```elixir

  iex> Cassette.validate("any-other-st", "some-service")
  {:error, "INVALID_SERVICE: ticket 'X' is invalid"}

  ```

  """

  use Cassette.Support
  use Application
end
