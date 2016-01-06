defmodule Cassette.Client do
  @moduledoc """
  Cas Client wrapper functions

  Generates Ticket Granting Tickets and Service Tickets
  Also provides helpers for the default options for the client
  """

  @spec tgt(Cassette.Config.t) :: Cassette.Client.GenerateTgt.response
  @doc """
  Generates a ticket granting ticket given the config

  Checkout `Cassette.Client.GenerateTgt.perform/1` for details on responses
  """
  def tgt(config) do
    Cassette.Client.GenerateTgt.perform(config)
  end

  @spec st(Cassette.Config.t, String.t, String.t) :: Cassette.Client.GenerateSt.response
  @doc """
  Generates a service ticket ticket given the config, a valid tgt and the target service

  Checkout `Cassette.Client.GenerateSt.perform/3` for details on responses
  """
  def st(config, tgt, service) do
    Cassette.Client.GenerateSt.perform(config, tgt, service)
  end

  @spec options(Cassette.Config.t) :: []
  @doc false
  def options(config) do
    if config.insecure do
      [hackney: [:insecure]]
    else
      []
    end
  end
end
