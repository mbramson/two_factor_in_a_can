defmodule TwoFactorInACan.MixProject do
  use Mix.Project

  def project do
    [
      app: :two_factor_in_a_can,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false},
      {:pot, "~> 0.9.7"},
      {:stream_data, "~> 0.1", only: :test},
    ]
  end
end
