defmodule Radlab.Firware.UpdaterTest do
  use ExUnit.Case
  import Mox
  alias Radlab.Firmware.MockClient
  alias Radlab.Firmware.Updater

  setup :verify_on_exit!

  describe "update_firmware/1" do
    test "sends chunks in configured size" do
      encoded_firmware = "Zm9vYmFyYmF6"
      expected_num_of_chunks = 6

      MockClient
      |> expect(:send_chunk, expected_num_of_chunks, fn _chunk ->
        {:ok, :received}
      end)

      actual = Updater.update_firmware(encoded_firmware)

      assert match?(:ok, actual)
    end

    test "re-tries chunk until it succeeds" do
      encoded_firmware = "Zm9vYmFyYmF6"

      MockClient
      |> stub(:send_chunk, fn _chunk ->
        case Enum.random([true, false]) do
          true ->
            {:ok, :received}

          false ->
            {:error, {:error_processing_contents, %{}}}
        end
      end)

      actual = Updater.update_firmware(encoded_firmware)

      assert match?(:ok, actual)
    end
  end

  describe "confirm_update_success/1" do
    test "returns :ok if checksum matches that from client" do
      encoded_firmware = "Zm9vYmFyYmF6"
      expected_checksum = 182

      MockClient
      |> expect(:get_checksum, 1, fn ->
        {:ok, expected_checksum}
      end)

      actual = Updater.confirm_update_success(encoded_firmware)

      assert match?(:ok, actual)
    end

    test "returns :error if checksums do not match" do
      encoded_firmware = "Zm9vYmFyYmF6"
      bad_checksum = 12

      MockClient
      |> expect(:get_checksum, 1, fn ->
        {:ok, bad_checksum}
      end)

      actual = Updater.confirm_update_success(encoded_firmware)

      assert match?(:error, actual)
    end

    test "returns :error if client encounters error" do
      encoded_firmware = "Zm9vYmFyYmF6"
      bad_checksum = 12

      MockClient
      |> stub(:get_checksum, fn ->
        {:error, :socket_connection_closed}
      end)

      actual = Updater.confirm_update_success(encoded_firmware)

      assert match?(:error, actual)
    end
  end
end
