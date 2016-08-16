defmodule RS.PersistorTest do
  use ExUnit.Case, async: false

  setup context do
    table = context.test
    File.rm(table |> to_string)
    on_exit fn -> File.rm(table |> to_string) end

    {:ok, %{table: table}}
  end

  test "Persistor persists some data", %{table: table} do
    RS.Persistor.init(table)

    assert RS.Persistor.get(table, :foo) == nil

    RS.Persistor.set(table, :foo, "bar")
    assert RS.Persistor.get(table, :foo) == "bar"

    RS.Persistor.set(table, :foo, "booo")
    assert RS.Persistor.get(table, :foo) == "booo"

    RS.Persistor.delete(table, :foo)
    assert RS.Persistor.get(table, :foo) == nil
  end

  test "Persistor persists some data on disk", %{table: table} do
    Application.put_env(:rs, :persist_on_disk, true)

    RS.Persistor.init(table)

    assert RS.Persistor.get(table, :foo) == nil

    RS.Persistor.set(table, :foo, "bar")
    assert RS.Persistor.get(table, :foo) == "bar"

    RS.Persistor.set(table, :foo, "booo")
    assert RS.Persistor.get(table, :foo) == "booo"

    RS.Persistor.delete(table, :foo)
    assert RS.Persistor.get(table, :foo) == nil

    RS.Persistor.set(table, :foo, "bar")

    RS.Persistor.close(table)

    RS.Persistor.init(table)
    assert RS.Persistor.get(table, :foo) == "bar"

    Application.put_env(:rs, :persist_on_disk, Mix.env != :test)
  end
end
