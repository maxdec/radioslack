defmodule RS.Persistor do

  def on_disk?, do: Application.fetch_env!(:rs, :persist_on_disk)

  def init(table) do
    case on_disk? do
      true -> :dets.open_file(table, [type: :set])
      false -> :ets.new(table, [:set, :protected, :named_table])
    end
  end

  def set(table, key, val) do
    case on_disk? do
      true -> :dets.insert(table, {key, val})
      false -> :ets.insert(table, {key, val})
    end
  end

  def get(table, key) do
    res = case on_disk? do
      true -> :dets.lookup(table, key)
      false -> :ets.lookup(table, key)
    end

    case res do
      [] -> nil
      [{^key, val}] -> val
    end
  end

  def delete(table, key) do
    case on_disk? do
      true -> :dets.delete(table, key)
      false -> :ets.delete(table, key)
    end
  end

  def close(table) do
    if on_disk?, do: :dets.close(table)
  end
end
