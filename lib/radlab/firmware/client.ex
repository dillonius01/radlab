defmodule Radlab.Firmware.Client do
  @callback get_checksum() :: {:ok, integer()} | {:error, {atom(), map()}}
  @callback send_chunk(binary()) :: {:ok, :received} | {:error, {atom(), map()}}
end
