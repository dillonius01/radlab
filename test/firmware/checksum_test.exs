defmodule Radlab.Firware.ChecksumTest do
  use ExUnit.Case

  describe "calc_checksum/1" do
    test "calculates modulo-256 checksum of base64 encoded input" do
      encoded = "Zm9vYmFy"
      expected = 121
      actual = Radlab.Firmware.Checksum.calc_checksum(encoded)

      assert expected == actual
    end
  end
end
