import ../helpers
import ./types
import ../hardware/dma

export types, dma

{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_sha256/include".}
{.push header: "pico/sha256.h".}

const SHA256_RESULT_BYTES* = 32

type
  Sha256Endianness* {.importc: "enum sha256_endianness".} = enum
    SHA256_LITTLE_ENDIAN
    SHA256_BIG_ENDIAN

  Sha256Result* {.importc: "sha256_result_t", union.} = object
    words*: array[SHA256_RESULT_BYTES div 4, uint32]
    bytes*: array[SHA256_RESULT_BYTES, uint8]

  PicoSha256State* {.importc: "pico_sha256_state_t".} = object
    ## SHA-256 state used by the API
    endianness*: Sha256Endianness
    channel*: int8
    locked*: bool
    cache_used*: uint8
    word*: uint32
    config*: DmaChannelConfig
    total_data_size*: csize_t

proc cleanup*(state: ptr PicoSha256State) {.importc: "pico_sha256_cleanup".}
  ## Release the internal lock on the SHA-256 hardware
  ##
  ## Release the internal lock on the SHA-256 hardware.
  ## Does nothing if the internal lock was not claimed.
  ##
  ## @param state A pointer to a pico_sha256_state_t instance

proc tryStart*(state: ptr PicoSha256State; endianness: Sha256Endianness; useDma: bool): cint {.importc: "pico_sha256_try_start".}
  ## Start a SHA-256 calculation returning immediately with an error if the SHA-256 hardware is not available
  ##
  ## Initialises the hardware and state ready to start a new SHA-256 calculation.
  ## Only one instance can be started at any time.
  ##
  ## @param state A pointer to a pico_sha256_state_t instance
  ## @param endianness SHA256_BIG_ENDIAN or SHA256_LITTLE_ENDIAN for data in and data out
  ## @param use_dma Set to true to use DMA internally to copy data to hardware. This is quicker at the expense of hardware DMA resources.
  ## @return Returns PICO_OK if the hardware was available for use and the sha256 calculation could be started, otherwise an error is returned

proc startBlockingUntil*(state: ptr PicoSha256State; endianness: Sha256Endianness; useDma: bool; until: AbsoluteTime): cint {.importc: "pico_sha256_start_blocking_until".}
  ## Start a SHA-256 calculation waiting for a defined period for the SHA-256 hardware to be available
  ##
  ## Initialises the hardware and state ready to start a new SHA-256 calculation.
  ## Only one instance can be started at any time.
  ##
  ## @param state A pointer to a pico_sha256_state_t instance
  ## @param endianness SHA256_BIG_ENDIAN or SHA256_LITTLE_ENDIAN for data in and data out
  ## @param use_dma Set to true to use DMA internally to copy data to hardware. This is quicker at the expense of hardware DMA resources.
  ## @param until How long to wait for the SHA hardware to be available
  ## @return Returns PICO_OK if the hardware was available for use and the sha256 calculation could be started in time, otherwise an error is returned

proc startBlocking*(state: ptr PicoSha256State; endianness: Sha256Endianness; useDma: bool): cint {.importc: "pico_sha256_start_blocking".}
  ## Start a SHA-256 calculation, blocking forever waiting until the SHA-256 hardware is available
  ##
  ## Initialises the hardware and state ready to start a new SHA-256 calculation.
  ## Only one instance can be started at any time.
  ##
  ## @param state A pointer to a pico_sha256_state_t instance
  ## @param endianness SHA256_BIG_ENDIAN or SHA256_LITTLE_ENDIAN for data in and data out
  ## @param use_dma Set to true to use DMA internally to copy data to hardware. This is quicker at the expense of hardware DMA resources.
  ## @return Returns PICO_OK if the hardware was available for use and the sha256 calculation could be started, otherwise an error is returned

proc update*(state: ptr PicoSha256State; data: ptr uint8; dataSizeBytes: csize_t) {.importc: "pico_sha256_update".}
  ## Add byte data to be SHA-256 calculation
  ##
  ## Add byte data to be SHA-256 calculation
  ## You may call this as many times as required to add all the data needed.
  ## You must have called pico_sha256_try_start (or equivalent) already.
  ##
  ## @param state A pointer to a pico_sha256_state_t instance
  ## @param data Pointer to the data to be added to the calculation
  ## @param data_size_bytes Amount of data to add
  ##
  ## @note This function may return before the copy has completed in which case the data passed to the function must remain valid and
  ## unchanged until a further call to pico_sha256_update or pico_sha256_finish. If this is not done, corrupt data may be used for the
  ## SHA-256 calculation giving an unexpected result.

proc updateBlocking*(state: ptr PicoSha256State; data: ptr uint8; dataSizeBytes: csize_t) {.importc: "update_blocking".}
  ## Add byte data to be SHA-256 calculation
  ##
  ## Add byte data to be SHA-256 calculation
  ## You may call this as many times as required to add all the data needed.
  ## You must have called pico_sha256_try_start already.
  ##
  ## @param state A pointer to a pico_sha256_state_t instance
  ## @param data Pointer to the data to be added to the calculation
  ## @param data_size_bytes Amount of data to add
  ##
  ## @note This function will only return when the data passed in is no longer required, so it can be freed or changed on return.

proc finish*(state: ptr PicoSha256State; output: ptr Sha256Result) {.importc: "pico_sha256_finish".}
  ## Finish the SHA-256 calculation and return the result
  ##
  ## Ends the SHA-256 calculation freeing the hardware for use by another caller.
  ## You must have called pico_sha256_try_start already.
  ##
  ## @param state A pointer to a pico_sha256_state_t instance
  ## @param out The SHA-256 checksum

{.pop.}
