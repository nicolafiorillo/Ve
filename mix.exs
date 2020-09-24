defmodule Ve.Mixfile do
  use Mix.Project

  @url "https://github.com/nicolafiorillo/Ve"

  def project do
    [
      app: :ve,
      version: "0.1.11",
      description: "Yet another Elixir data validation engine library.",
      elixir: "~> 1.5",
      package: package(),
      source_url: @url,
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        coveralls: :test
      ],
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Nicola Fiorillo"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.12", only: :test},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false}
    ]
  end
end
