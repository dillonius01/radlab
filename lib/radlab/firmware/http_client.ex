defmodule Radlab.Firmware.HttpClient do
  alias Radlab.Firmware.Client
  require Logger
  @behaviour Client

  @default_headers ['connection: keep-alive', 'keep-alive: timeout=5, max=5000']

  @impl Client
  @doc """
  Returns a tuple of :ok and the integer checksum from the endpoint configured in `config.exs`
  If there is an error, returns `{:error, {atom(), details}} `
  """
  def get_checksum() do
    endpoint = get_endpoint()

    :httpc.request(
      :post,
      {endpoint, @default_headers, 'application/text', 'CHECKSUM'},
      [],
      []
    )
    |> handle_checksum_response()
  end

  defp handle_checksum_response({:ok, {{'HTTP/1.1', status_code, _status}, _headers, body}}) do
    parse_checksum(status_code, body)
  end

  defp handle_checksum_response({:error, details}) do
    Logger.error("Encountered httpc error: #{inspect(details)}")
    {:error, {:httpc_error, details}}
  end

  defp parse_checksum(200 = status_code, 'Checksum: 0x' ++ checksum = body) do
    trimmed =
      checksum
      |> to_string
      |> String.trim()

    case Integer.parse(trimmed, 16) do
      {checksum_int, ""} ->
        {:ok, checksum_int}

      _ ->
        response_details = create_map_from_httpc_response(status_code, body)
        {:error, {:malformed_checksum, response_details}}
    end
  end

  defp parse_checksum(status_code, body) do
    response_details = create_map_from_httpc_response(status_code, body)
    {:error, {:other, response_details}}
  end

  @impl Client
  @doc """
  Returns `{:ok, :received}` if the chunk was uploaded successfully
  Returns `{:error, {:error_processing_contents, details}}` if a 200 was received but the
  body indicated that the chunk was not processed

  For other cases, returns `{:error, {atom(), details}}`
  """
  def send_chunk(chunk) do
    endpoint = get_endpoint()
    chunk_as_charlist = String.to_charlist(chunk)

    :httpc.request(
      :post,
      {endpoint, @default_headers, 'application/x-binary',
       'CHUNK: ' ++
         chunk_as_charlist},
      [],
      []
    )
    |> handle_chunk_response()
  end

  defp handle_chunk_response({:ok, {{'HTTP/1.1', status_code, _status}, _headers, body}}) do
    parse_chunk_success(status_code, body)
  end

  defp handle_chunk_response({:error, details}) do
    Logger.error("Encountered httpc error: #{inspect(details)}")
    {:error, {:httpc_error, details}}
  end

  defp parse_chunk_success(200 = status_code, 'ERROR PROCESSING CONTENTS\n' = body) do
    response_details = create_map_from_httpc_response(status_code, body)
    {:error, {:error_processing_contents, response_details}}
  end

  defp parse_chunk_success(200, 'OK\n') do
    {:ok, :received}
  end

  defp parse_chunk_success(status_code, body) do
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
