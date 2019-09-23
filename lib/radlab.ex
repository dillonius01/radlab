defmodule Radlab do
  require Logger
  alias Radlab.Firmware.Updater

  @doc """
  Receives options map and base64 encoded_firmware
  Runs the appropriate tasks based on the given options
  """
  def run_program(%{upload: false, checksum: true}, encoded_firmware) do
    run_and_log_checksum(encoded_firmware)
  end

  def run_program(%{upload: true, checksum: true}, encoded_firmware) do
    run_and_log_updater(encoded_firmware)
    run_and_log_checksum(encoded_firmware)
  end

  def run_program(%{upload: true, checksum: false}, encoded_firmware) do
    run_and_log_updater(encoded_firmware)
  end

  defp run_and_log_checksum(encoded_firmware) do
    checksum_res = Updater.confirm_update_success(encoded_firmware)
    Logger.info("Checksum response: #{checksum_res}")
    checksum_res
  end

  defp run_and_log_updater(encoded_firmware) do
    update_res = Updater.update_firmware(encoded_firmware)
    Logger.info("Update response: #{update_res}")
    update_res
  end
end
