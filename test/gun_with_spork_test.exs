defmodule GunWithSporkTest do
  use ExUnit.Case
  doctest GunWithSpork

  alias GunWithSpork.HttpClient

  setup_all do
    :bookish_spork.start_server()

    :ok
  end

  setup do
    :bookish_spork.stub_request(200, "1")
    :bookish_spork.stub_request(200, "2")

    :ok
  end

  test "hackney multi" do
    {:ok, response_1} = HTTPoison.get("localhost:32002")
    assert response_1.body == "1"

    {:ok, response_2} = HTTPoison.get("localhost:32002")
    assert response_2.body == "2"
  end

  test "gun multi single conn" do
    {:ok, conn_pid} = HttpClient.connection("localhost", 32002)

    {:ok, response_1, _headers} = HttpClient.get(conn_pid, "/")
    assert response_1 == "1"

    {:ok, response_2, _headers} = HttpClient.get(conn_pid, "/")
    assert response_2 == "2"
  end

  test "gun multi with new conn for every request" do
    {:ok, conn_pid} = HttpClient.connection("localhost", 32002)

    {:ok, response_1, _headers} = HttpClient.get(conn_pid, "/")
    assert response_1 == "1"

    {:ok, conn_pid} = HttpClient.connection("localhost", 32002)
    {:ok, response_2, _headers} = HttpClient.get(conn_pid, "/")
    assert response_2 == "2"
  end
end
