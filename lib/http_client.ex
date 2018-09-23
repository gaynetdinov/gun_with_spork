defmodule GunWithSpork.HttpClient do
  def connection(host, port) do
    host = to_charlist(host)

    with {:ok, conn_pid} <- :gun.open(host, port, %{connect_timeout: :timer.minutes(10)}),
         {:ok, _protocol} <- :gun.await_up(conn_pid) do
      {:ok, conn_pid}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get(conn_pid, query, headers \\ %{}) do
    headers =
      Enum.map headers, fn({name, value}) ->
        {name, to_charlist(value)}
      end

    monitor_ref = Process.monitor(conn_pid)
    stream_ref = :gun.get(conn_pid, to_charlist(query), headers)

    async_response(conn_pid, stream_ref, monitor_ref)
  end

  defp async_response(conn_pid, stream_ref, monitor_ref) do
    receive do
      {:gun_response, ^conn_pid, ^stream_ref, :fin, status, headers} when status < 300 ->
        {:ok, "", headers}

      {:gun_response, ^conn_pid, ^stream_ref, :fin, status, _headers} ->
        {:error, status}

      {:gun_response, ^conn_pid, ^stream_ref, :nofin, status, headers} when status < 300 ->
        case receive_data(conn_pid, stream_ref, monitor_ref, "") do
          {:ok, data} ->
            {:ok, data, headers}
          {:error, reason} ->
            {:error, reason}
        end

      {:gun_response, ^conn_pid, ^stream_ref, :nofin, _status, _headers} ->
        case receive_data(conn_pid, stream_ref, monitor_ref, "") do
          {:ok, data} ->
            {:error, data}
          {:error, reason} ->
            {:error, reason}
        end

      {:DOWN, ^monitor_ref, :process, ^conn_pid, reason} ->
        {:error, reason}
    after
      :timer.minutes(10) ->
        {:error, :recv_timeout}
    end
  end

  defp receive_data(conn_pid, stream_ref, monitor_ref, response_data) do
    receive do
      {:gun_data, ^conn_pid, ^stream_ref, :fin, data} ->
        {:ok, response_data <> data}
      {:gun_data, ^conn_pid, ^stream_ref, :nofin, data} ->
        receive_data(conn_pid, stream_ref, monitor_ref, response_data <> data)
      {:DOWN, ^monitor_ref, :process, ^conn_pid, reason} ->
        {:error, reason}
    after
      :timer.minutes(10) ->
        {:error, :recv_timeout}
    end
  end
end
