import ./picostdlib/[
  pico,
  pico/stdio,
  pico/time,
  hardware/gpio,
  hardware/uart,
  pico/binary_info,
  pico/platform,
  pico/util/datetime, pico/util/queue, pico/util/pheap,
  pico/error
]
export
  pico,
  stdio,
  time,
  gpio,
  uart,
  binary_info,
  platform,
  datetime, queue, pheap,
  error

{.push header: "pico/stdlib.h".}

proc setupDefaultUart*() {.importc: "setup_default_uart".}
  ## Set up the default UART and assign it to the default GPIOs
  ##
  ## By default this will use UART 0, with TX to pin GPIO 0,
  ## RX to pin GPIO 1, and the baudrate to 115200
  ##
  ## Calling this method also initializes stdin/stdout over UART if the
  ## @ref pico_stdio_uart library is linked.
  ##
  ## Defaults can be changed using configuration defines,
  ##  PICO_DEFAULT_UART_INSTANCE,
  ##  PICO_DEFAULT_UART_BAUD_RATE
  ##  PICO_DEFAULT_UART_TX_PIN
  ##  PICO_DEFAULT_UART_RX_PIN

{.pop.}
