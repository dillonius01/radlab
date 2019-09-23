defmodule Radlab.CLI do
  alias Radlab.File.Loader
  alias Radlab.Firmware.Updater
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
        run_program(opts, encoded_firmware)

      error ->
        Logger.error(inspect(error))
    end
  end

  defp run_program(%{upload: false, checksum: true}, encoded_firmware) do
    run_and_log_checksum(encoded_firmware)
  end

  defp run_program(%{upload: true, checksum: true}, encoded_firmware) do
    run_and_log_updater(encoded_firmware)
    run_and_log_checksum(encoded_firmware)
  end

  defp run_program(%{upload: true, checksum: false}, encoded_firmware) do
    run_and_log_updater(encoded_firmware)
  end

  defp run_and_log_checksum(encoded_firmware) do
    checksum_res = Updater.confirm_update_success(encoded_firmware)
    Logger.info("Checksum response: #{checksum_res}")
  end

  defp run_and_log_updater(encoded_firmware) do
    update_res = Updater.update_firmware(encoded_firmware)
    Logger.info("Update response: #{update_res}")
  end

  defp parse_args(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @allowed_options)

    default_path = Application.get_env(:radlab, :upload_file_path)

    opts
    |> Enum.into(%{upload: false, path: default_path, checksum: false})
  end
end
