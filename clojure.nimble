# Package

version       = "0.0.1"
author        = "Sacha De Vos"
description   = "Clojure CLI"
license       = "EPL"
srcDir        = "src"
bin           = @["clojure"]

# Dependencies

requires "nim >= 0.20.0"
requires "zip" # NEW LIB

task test, "Runs the test suite":
  exec "nim c -r tests/parseArgsTest"