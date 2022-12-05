# Package

version       = "0.3.2"
author        = "Jason"
description   = "Raspberry Pi Pico SDK bindings"
license       = "MIT"
srcDir        = "src"

bin           = @["picostdlib/private/piconim"]
installExt    = @["nim", "txt", "cmake"]
installDirs   = @["picostdlib/private/template"]

# Dependencies

requires "nim >= 1.6.0"
requires "https://github.com/casey-SK/commandant >= 0.15.1"
requires "https://github.com/beef331/micros"
