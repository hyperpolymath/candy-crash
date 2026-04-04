// SPDX-License-Identifier: PMPL-1.0-or-later
// candy_crash_test.gleam — trivial smoke test for candy_crash backend.
// Uses gleeunit as the test framework (declared in gleam.toml dev-dependencies).

import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// Verify the project compiles and basic equality holds.
pub fn smoke_test() {
  let result = True
  result |> should.equal(True)
}

// Verify string concatenation works (sanity check for the BEAM runtime).
pub fn string_concat_test() {
  let greeting = "Candy" <> " " <> "Crash"
  greeting |> should.equal("Candy Crash")
}
