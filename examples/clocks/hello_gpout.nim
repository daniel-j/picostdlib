import picostdlib
import picostdlib/hardware/clocks

stdioInitAll()

echo "Hello gpout"

# Output clk_sys / 10 to gpio 21, etc...
Gpio(21).initClock(ClocksClkGpout0CtrlAuxSrc.ClkSys, 10)
Gpio(23).initClock(ClocksClkGpout0CtrlAuxSrc.ClkUsb, 10)
Gpio(24).initClock(ClocksClkGpout0CtrlAuxSrc.ClkAdc, 10)
when picoIncludeRtcDatetime:
  Gpio(25).initClock(ClocksClkGpout0CtrlAuxSrc.ClkRtc, 10)
