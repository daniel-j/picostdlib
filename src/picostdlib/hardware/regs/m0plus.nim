import ../../helpers
{.localPassC: "-I" & picoSdkPath & "/src/" & picoPlatform & "/hardware_regs/include".}
{.push header: "hardware/regs/m0plus.h".}

let
  M0PLUS_SCR_SLEEPDEEP_BITS* {.importc: "M0PLUS_SCR_SLEEPDEEP_BITS".}: uint32

{.pop.}
