defmodule Mix.Tasks.MobMishka.GenTest do
  # Wrapper-only smoke test. The task delegates every real decision to
  # `MobMishka.Gen`, which owns its own comprehensive test coverage — this
  # module is here to prove the task exists, accepts the expected argv
  # shapes, and produces the expected errors when misused.
  #
  # `Mix.Project.push/2` cannot swap the running project underneath us
  # (mob_mishka is already on top), so we don't attempt a full end-to-end
  # eject through the wrapper — that path is exercised by the "end-to-end
  # eject through the pure helpers" test in `test/mob_mishka/gen_test.exs`.
  use ExUnit.Case, async: false

  describe "mix mob_mishka.gen" do
    test "raises on missing arguments" do
      assert_raise Mix.Error, ~r/Usage: mix mob_mishka.gen/, fn ->
        Mix.Tasks.MobMishka.Gen.run([])
      end
    end

    test "raises when run inside the mob_mishka repo itself" do
      # The task refuses to write to lib/ of the plugin it ships. This
      # test IS running inside mob_mishka, so any run without `--all` or a
      # different Mix.Project should hit that guard.
      assert_raise Mix.Error, ~r/must be run from inside a Mix project/, fn ->
        Mix.Tasks.MobMishka.Gen.run(["visually_hidden"])
      end
    end
  end
end
