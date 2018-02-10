defmodule Ve.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ve,
      version: "0.1.7",
      description: "Yet another Elixir data validation engine library.",
      elixir: "~> 1.5",
      package: package(),
      source_url: "https://github.com/WhitePeaksMobileSoftware/Ve",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Nicola Fiorillo"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/WhitePeaksMobileSoftware/Ve"}    ]
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
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
