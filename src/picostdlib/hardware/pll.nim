import ./base

type
  Pll* {.bycopy, importc: "pll_hw_t", header: "hardware/structs/pll.h".} = object
    cs* {.importc.}: IoRw32
    pwr* {.importc.}: IoRw32
    fbdiv_int* {.importc.}: IoRw32
    prim* {.importc.}: IoRw32

{.push header: "hardware/pll.h".}

const
  PllSys* {.importc: "pll_sys".} = Pll()
  PllUsb* {.importc: "pll_usb".} = Pll()

proc pllInit*(pll: Pll, refDiv, vcoFreq, postDiv1, postDiv2: cuint) {.importc: "pll_init".}
  ## Initialise specified PLL.
  ##     \ingroup hardware_pll
  ##    \param pll pll_sys or pll_usb
  ##    \param ref_div Input clock divider.
  ##    \param vco_freq  Requested output from the VCO (voltage controlled oscillator)
  ##    \param post_div1 Post Divider 1 - range 1-7. Must be >= post_div2
  ##    \param post_div2 Post Divider 2 - range 1-7

proc pllDeinit*(pll: Pll) {.importc: "pll_deinit".}
  ## Release/uninitialise specified PLL.
  ##     \ingroup hardware_pll
  ##   
  ##    This will turn off the power to the specified PLL. Note this function does not currently check if
  ##    the PLL is in use before powering it off so should be used with care.
  ##   
  ##    \param pll pll_sys or pll_usb

{.pop.}
