defmodule Radlab.File.Loader do
  @doc """
  Receives a path to a file, reads the contents and encodes in base64.

  Returns a tuple of `:ok` and the encoded contents, or an error tuple.
  """
  def read_file_and_encode_base64(path) do
    path
    |> File.read()
    |> handle_file_read()
  end

  defp handle_file_read({:ok, file_contents}) do
    encoded = Base.encode64(file_contents)
    {:ok, encoded}
  end

  defp handle_file_read(error), do: error
end
