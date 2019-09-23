defmodule Radlab.Firmware.Checksum do
  @doc """
  Received a base-64 encoded string.

  Calculates a checksum by iterating across the value of the bytes, adding the value
  of each byte to the checksum, and then modulo-ing the checksum by 256.
  """
  def calc_checksum(base64_string) do
    base64_string
    |> Base.decode64!()
    |> String.codepoints()
    |> Enum.reduce(0, &do_checksum/2)
  end

  defp do_checksum(<<v::utf8>>, acc) do
    new_acc = acc + v
    rem(new_acc, 256)
  end
end
