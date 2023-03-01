import strutils
import picostdlib/[pico/stdio, pico/binary_info, hardware/i2c, pico/error]

# I2C reserves some addresses for special purposes. We exclude these from the scan.
# These are any addresses of the form 000 0xxx or 111 1xxx
proc reservedAddr(address: I2cAddress): bool =
  return (address.ord and 0x78) == 0 or (address.ord and 0x78) == 0x78


stdioInitAll()

# This example will use I2C0 on the default SDA and SCL pins (GP4, GP5 on a Pico)
discard i2cInit(i2cDefault, 100 * 1000)
gpioSetFunction(DefaultI2cSdaPin, I2c)
gpioSetFunction(DefaultI2cSclPin, I2c)
gpioPullUp(DefaultI2cSdaPin)
gpioPullUp(DefaultI2cSclPin)


# Make the I2C pins available to picotool
{.emit: "#include \"pico/binary_info.h\"".}
{.emit: ["bi_decl(bi_2pins_with_func(", DefaultI2cSdaPin, ", ", DefaultI2cSclPin, ", ", I2c, "));"].}

echo "I2C Bus Scan"
echo "   0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F"

var ret: int
var rxdata: uint8
for address in 0..<(1 shl 7):
  if address mod 16 == 0:
    stdout.write(address.toHex(2) & " ")
    stdout.flushFile()

    # Perform a 1-byte dummy read from the probe address. If a slave
    # acknowledges this address, the function returns the number of bytes
    # transferred. If the address byte is ignored, the function returns
    # -1.

    # Skip over any reserved addresses.
    if reservedAddr(address.I2cAddress):
      ret = PicoErrorGeneric.ord
    else:
      ret = i2cReadBlocking(i2cDefault, address.I2cAddress, rxdata.addr, 1, false)

    stdout.write(if ret < 0: '.' else: '@')
    stdout.write(if address mod 16 == 15: "\n" else: "  ")
    stdout.flushFile()

echo "Done"