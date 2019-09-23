defmodule Radlab.Firware.UpdaterTest do
  use ExUnit.Case
  import Mox

  setup :verify_on_exit!

  describe "update_firmware/1" do
    test "sends chunks in configured size" do
      assert 1 == 2
    end
  end
end
