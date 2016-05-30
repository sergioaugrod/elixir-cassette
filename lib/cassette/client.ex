defmodule Cassette.Client do
  @moduledoc """
  Cas Client wrapper functions

  Generates Ticket Granting Tickets and Service Tickets
  Also provides helpers for the default options for the client
  """

  alias Cassette.Config
  alias Cassette.Client.GenerateSt
  alias Cassette.Client.GenerateTgt

  @spec tgt(Config.t) :: GenerateTgt.response
  @doc """
  Generates a ticket granting ticket given the config

  Checkout `Cassette.Client.GenerateTgt.perform/1` for details on responses
  """
  def tgt(config) do
    GenerateTgt.perform(config)
  end

  @spec st(Config.t, String.t, String.t) :: GenerateSt.response
  @doc """
  Generates a service ticket ticket given the config, a valid tgt and the target service

  Checkout `Cassette.Client.GenerateSt.perform/3` for details on responses
  """
  def st(config, current_tgt, service) do
    GenerateSt.perform(config, current_tgt, service)
  end

  @spec options(Config.t) :: []
  @doc false
  def options(config) do
    if config.insecure do
      [hackney: [:insecure]]
    else
      []
    end
  end
end
