defmodule Radlab.MixProject do
  use Mix.Project

  def project do
    [
      app: :radlab,
      escript: escript(),
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets]
    ]
  end

  defp escript do
    [main_module: Radlab.CLI]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mox, "~> 0.5.1", only: :test}
    ]
  end
end
