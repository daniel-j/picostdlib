{.warning[UnusedImport]:off.}

# stdlib
import picostdlib/pico/cyw43_arch
import picostdlib/pico/cyw43_driver as pico_cyw43_driver

# futhark stuff
import picostdlib/lib/lwip
import picostdlib/lib/lwip_apps
import picostdlib/lib/cyw43_driver
import picostdlib/lib/btstack
import picostdlib/lib/btstack_ble
import picostdlib/lib/btstack_classic
import picostdlib/lib/btstack_mesh
import picostdlib/lib/btstack_le_audio
# import picostdlib/lib/freertos

# examples
import "../examples/pico_w/picow_tls_client"
import "../examples/pico_w/picow_wifi_scan"
import "../examples/pico_w/picow_ntp_client"

# import and include pico_w blink example
import "../examples/pico_w/picow_blink"
include "../examples/pico_w/picow_blink"