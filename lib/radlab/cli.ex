defmodule Radlab.CLI do
  alias Radlab.File.Loader
  require Logger

  @allowed_options [path: :string, checksum: :boolean, upload: :boolean]

  def main(args) do
    args
    |> parse_args()
    |> run()
  end

  defp run(%{path: path} = opts) do
    case Loader.read_file_and_encode_base64(path) do
      {:ok, encoded_firmware} ->
        Radlab.run_program(opts, encoded_firmware)

      error ->
        Logger.error(inspect(error))
    end
  end

  defp parse_args(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @allowed_options)

    default_path = Application.get_env(:radlab, :upload_file_path)

    opts
    |> Enum.into(%{upload: false, path: default_path, checksum: false})
  end
end
