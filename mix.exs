defmodule MobMishka.MixProject do
  use Mix.Project

  @source_url "https://github.com/GenericJam/mob_mishka"
  @version "0.0.1"

  def project do
    [
      app: :mob_mishka,
      version: @version,
      elixir: "~> 1.17",
      deps: deps(),
      aliases: aliases(),
      description:
        "Mishka Chelekom composites for Mob apps — plugin-shipped, no vendoring into user code",
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp aliases do
    # `mix setup` after cloning: fetches deps and activates the shared git
    # hooks (.githooks): format / Credo --strict / compile run on every push
    # and the full suite when mix.exs changes — the same gate CI enforces.
    [setup: ["deps.get", "cmd git config core.hooksPath .githooks"]]
  end

  defp deps do
    [
      # mob 0.8.x supports `config :mob, :extra_tags` (the app-side escape
      # hatch this plugin ultimately replaces). Plugin-manifest tag discovery
      # (MOB-247, this plugin's headline mechanism) ships in the next mob
      # minor; bump the constraint when that lands.
      {:mob, "~> 0.8"},
      {:mob_dev, "~> 0.6", only: [:dev, :test], runtime: false},
      # MishkaJsonInput.parse/1 uses Jason.decode/1 — the composite ships
      # a JSON parser (surprising, but Chelekom's json-input is a real
      # validating editor, not just a textarea). Runtime dep, not a
      # dev-only one — a consumer app must have it linked.
      {:jason, "~> 1.4"},
      # Code quality — Credo + ex_slop (AI-pattern checks) + jump_credo_checks,
      # mirroring mob core's pre-commit gate.
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4.2", only: [:dev, :test], runtime: false},
      {:jump_credo_checks, "~> 0.1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      # Ship the manifest + priv/ (holds the plugin manifest .exs; will hold
      # native assets if any composite later needs them). No `src/` — this is
      # a pure-Elixir composite plugin.
      files: ~w(lib priv mix.exs README* CHANGELOG* LICENSE*)
    ]
  end
end
