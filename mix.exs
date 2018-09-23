defmodule GunWithSpork.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gun_with_spork,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.13"},
      {:gun, "~> 1.1"},
      {:bookish_spork, "~> 0.2"}
    ]
  end
end
