defmodule TwoFactorInACan.MixProject do
  use Mix.Project

  def project do
    [
      app: :two_factor_in_a_can,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "TwoFactorInACan",
      source_url: "https://github.com/mbramson/two_factor_in_a_can",
      homepage_url: "http://github.com/mbramson/two_factor_in_a_can",
      docs: [main: "getting-started",
        extras: [
          "docs/Getting Started.md",
          "docs/Roadmap.md",
        ]
      ]
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
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false},
      {:pot, "~> 0.9.7", only: :test},
      {:stream_data, "~> 0.1", only: :test},
    ]
  end
end
