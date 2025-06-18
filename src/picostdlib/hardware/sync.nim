import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_sync/include".}
{.push header: "hardware/sync.h".}

const picoUseSwSpinLocks* {.booldefine.} = picoRp2350

const
  SpinlockIdIrq* = 9
  SpinlockIdTimer* = 10
  SpinlockIdHardwareClaim* = 11
  SpinlockIdOs1* = 14
  SpinlockIdOs2* = 15
  SpinlockIdStripedFirst* = 16
  SpinlockIdStripedLast* = 23
  SpinlockIdClaimFreeFirst* = 24
  SpinlockIdClaimFreeLast* = 31

type
  LockNum* = distinct cuint

when not picoUseSwSpinLocks:
  type
    SpinLock* {.importc: "spin_lock_t".} = uint32
      ## A spin lock identifier
else:
  type
    SpinLock* {.importc: "spin_lock_t".} = uint8
      ## A software spin lock identifier


proc `==`*(a, b: LockNum): bool {.borrow.}
proc `$`*(a: LockNum): string {.borrow.}

## hardware_sync

proc nop*() {.importc: "__nop".}
  ## Insert a NOP instruction in to the code path.
  ##
  ## NOP does nothing for one cycle. On RP2350 Arm binaries this is forced to be
  ## a 32-bit instruction to avoid dual-issue of NOPs.

proc sev*() {.importc: "__sev".}
  ## Insert a SEV instruction in to the code path.
  ##
  ## The SEV (send event) instruction sends an event to both cores.

proc wfe*() {.importc: "__wfe".}
  ## Insert a WFE instruction in to the code path.
  ##
  ## The WFE (wait for event) instruction waits until one of a number of
  ## events occurs, including events signalled by the SEV instruction on either core.

proc wfi*() {.importc: "__wfi".}
  ## Insert a WFI instruction in to the code path.
  ##
  ## The WFI (wait for interrupt) instruction waits for a interrupt to wake up the core.

proc dmb*() {.importc: "__dmb".}
  ## Insert a DMB instruction in to the code path.
  ##
  ## The DMB (data memory barrier) acts as a memory barrier, all memory accesses prior to this
  ## instruction will be observed before any explicit access after the instruction.

proc dsb*() {.importc: "__dsb".}
  ## Insert a DSB instruction in to the code path.
  ##
  ## The DSB (data synchronization barrier) acts as a special kind of data
  ## memory barrier (DMB). The DSB operation completes when all explicit memory
  ## accesses before this instruction complete.

proc isb*() {.importc: "__isb".}
  ## Insert a ISB instruction in to the code path.
  ##
  ## ISB acts as an instruction synchronization barrier. It flushes the pipeline of the processor,
  ## so that all instructions following the ISB are fetched from cache or memory again, after
  ## the ISB instruction has been completed.

proc disableInterrupts*(): uint32 {.importc: "disable_interrupts".}
  ## Explicitly disable interrupts on the calling core

proc enableInterrupts*(): uint32 {.importc: "enable_interrupts".}
  ## Explicitly enable interrupts on the calling core

proc saveAndDisableInterrupts*(): uint32 {.importc: "save_and_disable_interrupts".}
  ## Disable interrupts on the calling core, returning the previous interrupt state
  ##
  ## This method is commonly paired with \ref restore_interrupts_from_disabled() to temporarily
  ## disable interrupts around a piece of code, without needing to care whether interrupts
  ## were previously enabled
  ##
  ## \return The prior interrupt enable status for restoration later via \ref restore_interrupts_from_disabled()
  ## or \ref restore_interrupts()

proc restoreInterrupts*(status: uint32) {.importc: "restore_interrupts".}
  ## Restore interrupts to a specified state on the calling core
  ##
  ## \param status Previous interrupt status from save_and_disable_interrupts()

proc restoreInterruptsFromDisabled*(status: uint32) {.importc: "restore_interrupts_from_disabled".}
  ## Restore interrupts to a specified state on the calling core with restricted transitions
  ##
  ## This method should only be used when the current interrupt state is known to be disabled,
  ## e.g. when paired with \ref save_and_disable_interrupts()
  ##
  ## \param status Previous interrupt status from save_and_disable_interrupts()

## hardware_sync_spin_lock

proc spinLockInstance*(lockNum: LockNum): ptr SpinLock {.importc: "spin_lock_instance".}
  ## Get HW Spinlock instance from number
  ##
  ## \param lock_num Spinlock ID
  ## \return The spinlock instance

proc getNum*(lock: ptr SpinLock): LockNum {.importc: "spin_lock_get_num".}
  ## Get HW Spinlock number from instance
  ##
  ## \param lock The Spinlock instance
  ## \return The Spinlock ID

proc lockUnsafeBlocking*(lock: ptr SpinLock) {.importc: "spin_lock_unsafe_blocking".}
  ## Acquire a spin lock without disabling interrupts (hence unsafe)
  ##
  ## \param lock Spinlock instance

proc unlockUnsafe*(lock: ptr SpinLock) {.importc: "spin_unlock_unsafe".}
  ## Release a spin lock without re-enabling interrupts
  ##
  ## \param lock Spinlock instance

proc lockBlocking*(lock: ptr SpinLock): uint32 {.importc: "spin_lock_blocking".}
  ## Acquire a spin lock safely
  ##
  ## This function will disable interrupts prior to acquiring the spinlock
  ##
  ## \param lock Spinlock instance
  ## \return interrupt status to be used when unlocking, to restore to original state

proc isSpinLocked*(lock: ptr SpinLock): bool {.importc: "is_spin_locked".}
  ## Check to see if a spinlock is currently acquired elsewhere.
  ##
  ## \param lock Spinlock instance

proc unlock*(lock: ptr SpinLock, savedIrq: uint32) {.importc: "spin_unlock".}
  ## Release a spin lock safely
  ##
  ## This function will re-enable interrupts according to the parameters.
  ##
  ## \param lock Spinlock instance
  ## \param saved_irq Return value from the \ref spin_lock_blocking() function.
  ## \return interrupt status to be used when unlocking, to restore to original state
  ##
  ## \sa spin_lock_blocking()

proc spinLockInit*(lockNum: LockNum): ptr SpinLock {.importc: "spin_lock_init".}
  ## Initialise a spin lock
  ##
  ## The spin lock is initially unlocked
  ##
  ## \param lock_num The spin lock number
  ## \return The spin lock instance

proc spinLocksReset*() {.importc: "spin_locks_reset".}
  ## Release all spin locks

## hardware_sync

proc nextStripedSpinLockNum*(): uint {.importc: "next_striped_spin_lock_num".}
  ## Return a spin lock number from the _striped_ range
  ##
  ## Returns a spin lock number in the range PICO_SPINLOCK_ID_STRIPED_FIRST to PICO_SPINLOCK_ID_STRIPED_LAST
  ## in a round robin fashion. This does not grant the caller exclusive access to the spin lock, so the caller
  ## must:
  ##
  ## -# Abide (with other callers) by the contract of only holding this spin lock briefly (and with IRQs disabled - the default via \ref spin_lock_blocking()),
  ## and not whilst holding other spin locks.
  ## -# Be OK with any contention caused by the - brief due to the above requirement - contention with other possible users of the spin lock.
  ##
  ## \return lock_num a spin lock number the caller may use (non exclusively)
  ## \see PICO_SPINLOCK_ID_STRIPED_FIRST
  ## \see PICO_SPINLOCK_ID_STRIPED_LAST

proc spinLockClaim*(lockNum: LockNum) {.importc: "spin_lock_claim".}
  ## Mark a spin lock as used
  ##
  ## Method for cooperative claiming of hardware. Will cause a panic if the spin lock
  ## is already claimed. Use of this method by libraries detects accidental
  ## configurations that would fail in unpredictable ways.
  ##
  ## \param lock_num the spin lock number

proc spinLockClaimMask*(lockNumMask: uint32) {.importc: "spin_lock_claim_mask".}
  ## Mark multiple spin locks as used
  ##
  ## Method for cooperative claiming of hardware. Will cause a panic if any of the spin locks
  ## are already claimed. Use of this method by libraries detects accidental
  ## configurations that would fail in unpredictable ways.
  ##
  ## \param lock_num_mask Bitfield of all required spin locks to claim (bit 0 == spin lock 0, bit 1 == spin lock 1 etc)

proc spinLockUnclaim*(lockNum: LockNum) {.importc: "spin_lock_unclaim".}
  ## Mark a spin lock as no longer used
  ##
  ## Method for cooperative claiming of hardware.
  ##
  ## \param lock_num the spin lock number to release

proc spinLockClaimUnused*(required: bool): cint {.importc: "spin_lock_claim_unused".}
  ## Claim a free spin lock
  ##
  ## \param required if true the function will panic if none are available
  ## \return the spin lock number or -1 if required was false, and none were free

proc spinLockIsClaimed*(lockNum: LockNum): bool {.importc: "spin_lock_is_claimed".}
  ## Determine if a spin lock is claimed
  ##
  ## \param lock_num the spin lock number
  ## \return true if claimed, false otherwise
  ## \see spin_lock_claim
  ## \see spin_lock_claim_mask

{.pop.}
