defmodule Radlab.Firmware.HttpClient do
  alias Radlab.Firmware.Client
  @behaviour Client

  @default_headers ['connection: keep-alive', 'keep-alive: timeout=5, max=5000']

  @impl Client
  def get_checksum() do
    endpoint = get_endpoint()

    {:ok, {{'HTTP/1.1', status_code, _status}, _headers, body}} =
      :httpc.request(
        :post,
        {endpoint, @default_headers, 'application/text', 'CHECKSUM'},
        [],
        []
      )

    handle_checksum_response(status_code, body)
  end

  defp handle_checksum_response(200, 'Checksum: 0x' ++ checksum) do
    trimmed =
      checksum
      |> to_string
      |> String.trim()

    {checksum_int, _} = Integer.parse(trimmed, 16)

    {:ok, checksum_int}
  end

  defp handle_checksum_response(status_code, body) do
    response_details = create_map_from_httpc_response(status_code, body)
    {:error, {:other, response_details}}
  end

  @impl Client
  def send_chunk(chunk) do
    endpoint = get_endpoint()
    chunk_as_charlist = String.to_charlist(chunk)

    {:ok, {{'HTTP/1.1', status_code, _status}, _headers, body}} =
      :httpc.request(
        :post,
        {endpoint, @default_headers, 'application/x-binary',
         'CHUNK: ' ++
           chunk_as_charlist},
        [],
        []
      )

    handle_chunk_response(status_code, body)
  end

  defp handle_chunk_response(200 = status_code, 'ERROR PROCESSING CONTENTS\n' = body) do
    response_details = create_map_from_httpc_response(status_code, body)
    {:error, {:error_processing_contents, response_details}}
  end

  defp handle_chunk_response(200, 'OK\n') do
    {:ok, :received}
  end

  defp handle_chunk_response(status_code, body) do
    response_details = create_map_from_httpc_response(status_code, body)
    {:error, {:other, response_details}}
  end

  defp create_map_from_httpc_response(status_code, body) do
    body_string = to_string(body)

    %{
      status_code: status_code,
      body: body_string
    }
  end

  defp get_endpoint() do
    Application.get_env(:radlab, :http_endpoint) |> String.to_charlist()
  end
end
