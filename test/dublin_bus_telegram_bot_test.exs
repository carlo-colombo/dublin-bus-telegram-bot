defmodule DublinBusTelegramBotTest do
  use ExUnit.Case
  doctest DublinBusTelegramBot

  test "decorating a function" do
    defmeter a_func(arg1, arg2, arg3) do
      IO.puts("do nothing")
    end
  end
end
#
