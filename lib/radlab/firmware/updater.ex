defmodule Radlab.Firmware.Updater do
  require Logger
  alias Radlab.Firmware.Checksum

  @doc """
  Receives a base-64 encoded string representing the contents of the firmware update.

  Uploads the firmware via the client configured in `config.exs`
  Will auto-retry each chunk until it succeeds.

  Returns `:ok` on upload success or `:error`
  """
  def update_firmware(encoded_firmware) do
    encoded_firmware
    |> split_into_chunks()
    |> send_all_chunks()
  end

  defp split_into_chunks(base64_string) do
    chunk_size = Application.get_env(:radlab, :chunk_size)

    base64_string
    |> String.codepoints()
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(&Enum.join/1)
  end

  defp send_all_chunks([]) do
    :ok
  end

  defp send_all_chunks([chunk | _remaining] = chunks) do
    result = get_client().send_chunk(chunk)

    handle_chunk(result, chunks)
  end

  defp handle_chunk({:ok, _}, [chunk | remaining]) do
    Logger.info("success! uploaded: #{chunk}")
    send_all_chunks(remaining)
  end

  defp handle_chunk({:error, {:error_processing_contents, _}}, [chunk | _remaining] = chunks) do
    Logger.info("re-trying chunk: #{chunk}")
    send_all_chunks(chunks)
  end

  defp handle_chunk({:error, details}, _chunks) do
    Logger.error("unknown error: #{inspect(details)}")
    :error
  end

  @doc """
  Receives a base-64 encoded string representing the contents of the firmware update.

  Calculates the checksum of that data and compares it to the checksum available
  via the client configured in `config.exs`

  Returns `:ok` if the checksums match, or `:error` otherwise
  """
  def confirm_update_success(encoded_firmware) do
    expected = Checksum.calc_checksum(encoded_firmware)
    res = get_client().get_checksum()

    case res do
      {:ok, actual} ->
        check_same(expected, actual)

      _ ->
        :error
    end
  end

  defp check_same(expected, actual) when expected == actual, do: :ok

  defp check_same(_, _), do: :error

  defp get_client do
    Application.get_env(:radlab, :client)
  end
end
