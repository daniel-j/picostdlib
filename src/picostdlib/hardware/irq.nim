import ./regs/intctrl
export intctrl

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_irq/include".}
{.push header: "hardware/irq.h".}

const
  PICO_LOWEST_IRQ_PRIORITY* = uint8.low
  PICO_HIGHEST_IRQ_PRIORITY* = uint8.high

let
  PICO_MAX_SHARED_IRQ_HANDLERS* {.importc: "PICO_MAX_SHARED_IRQ_HANDLERS".}: uint
  PICO_DISABLE_SHARED_IRQ_HANDLERS* {.importc: "PICO_DISABLE_SHARED_IRQ_HANDLERS".}: bool
  PICO_VTABLE_PER_CORE* {.importc: "PICO_VTABLE_PER_CORE".}: bool
  PICO_DEFAULT_IRQ_PRIORITY* {.importc: "PICO_DEFAULT_IRQ_PRIORITY".}: uint8
  PICO_SHARED_IRQ_HANDLER_DEFAULT_ORDER_PRIORITY* {.importc: "PICO_SHARED_IRQ_HANDLER_DEFAULT_ORDER_PRIORITY".}: uint8
  PARAM_ASSERTIONS_ENABLED_IRQ* {.importc: "PARAM_ASSERTIONS_ENABLED_IRQ".}: bool

type
  IrqHandler* {.importc: "irq_handler_t".} = proc () {.cdecl.}

proc setPriority*(num: InterruptNumber; hardwarePriority: uint8) {.importc: "irq_set_priority".}
  ## Set specified interrupt's priority
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \param hardware_priority Priority to set.
  ## Numerically-lower values indicate a higher priority. Hardware priorities
  ## range from 0 (highest priority) to 255 (lowest priority). To make it easier to specify
  ## higher or lower priorities than the default, all IRQ priorities are
  ## initialized to PICO_DEFAULT_IRQ_PRIORITY by the SDK runtime at startup.
  ## PICO_DEFAULT_IRQ_PRIORITY defaults to 0x80
  ##
  ## \if rp2040_specific
  ## Only the top 2 bits are significant on ARM Cortex-M0+ on RP2040.
  ## \endif
  ##
  ## \if rp2350_specific
  ## Only the top 4 bits are significant on ARM Cortex-M33 or Hazard3 (RISC-V) on RP2350.
  ## Note that this API uses the same (inverted) ordering as ARM on RISC-V
  ## \endif

proc getPriority*(num: InterruptNumber): cuint {.importc: "irq_get_priority".}
  ## Get specified interrupt's priority
  ##
  ## Numerically-lower values indicate a higher priority. Hardware priorities
  ## range from 0 (highest priority) to 255 (lowest priority). To make it easier to specify
  ## higher or lower priorities than the default, all IRQ priorities are
  ## initialized to PICO_DEFAULT_IRQ_PRIORITY by the SDK runtime at startup.
  ## PICO_DEFAULT_IRQ_PRIORITY defaults to 0x80
  ##
  ## \if rp2040_specific
  ## Only the top 2 bits are significant on ARM Cortex-M0+ on RP2040.
  ## \endif
  ##
  ## \if rp2350_specific
  ## Only the top 4 bits are significant on ARM Cortex-M33 or Hazard3 (RISC-V) on RP2350.
  ## Note that this API uses the same (inverted) ordering as ARM on RISC-V
  ## \endif

proc setEnabled*(num: InterruptNumber; enabled: bool) {.importc: "irq_set_enabled".}
  ## Enable or disable a specific interrupt on the executing core
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \param enabled true to enable the interrupt, false to disable

proc isEnabled*(num: InterruptNumber): bool {.importc: "irq_is_enabled".}
  ## Determine if a specific interrupt is enabled on the executing core
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \return true if the interrupt is enabled

proc irqSetMaskEnabled*(mask: uint32; enabled: bool) {.importc: "irq_set_mask_enabled".}
  ## Enable/disable multiple interrupts on the executing core
  ##
  ## \param mask 32-bit mask with one bits set for the interrupts to enable/disable \ref interrupt_nums
  ## \param enabled true to enable the interrupts, false to disable them.

proc irqSetMaskNEnabled*(n: cuint; mask: uint32; enabled: bool) {.importc: "irq_set_mask_n_enabled".}
  ## Enable/disable multiple interrupts on the executing core
  ##
  ## \param n the index of the mask to update. n == 0 means 0->31, n == 1 mean 32->63 etc.
  ## \param mask 32-bit mask with one bits set for the interrupts to enable/disable \ref interrupt_nums
  ## \param enabled true to enable the interrupts, false to disable them.

proc setExclusiveHandler*(num: InterruptNumber; handler: IrqHandler) {.importc: "irq_set_exclusive_handler".}
  ## Set an exclusive interrupt handler for an interrupt on the executing core.
  ##
  ## Use this method to set a handler for single IRQ source interrupts, or when
  ## your code, use case or performance requirements dictate that there should be
  ## no other handlers for the interrupt.
  ##
  ## This method will assert if there is already any sort of interrupt handler installed
  ## for the specified irq number.
  ##
  ## NOTE: By default, the SDK uses a single shared vector table for both cores, and the currently installed
  ## IRQ handlers are effectively a linked list starting a vector table entry for a particular IRQ number.
  ## Therefore, this method (when using the same vector table for both cores) sets the same interrupt handler
  ## for both cores.
  ##
  ## On RP2040 this was never really a cause of any confusion, because it rarely made sense to enable
  ## the same interrupt number in the NVIC on both cores (see \ref irq_set_enabled()), because the interrupt
  ## would then fire on both cores, and the interrupt handlers would race.
  ##
  ## The problem *does* exist however when dealing with interrupts which are independent on the two cores.
  ##
  ## This includes:
  ##
  ## the core local "spare" IRQs
  ## on RP2350 the SIO FIFO IRQ which is now the same irq number for both cores (vs RP2040 where it was two)
  ##
  ## In the cases where you want to enable the same IRQ on both cores, and both cores are sharing the same vector
  ## table, you should install the IRQ handler once - it will be used on both cores - and check the core
  ## number (via \ref get_core_num()) on each core.
  ##
  ## NOTE: It is not thread safe to add/remove/handle IRQs for the same irq number in the same vector table
  ## from both cores concurrently.
  ##
  ## NOTE: The SDK has a PICO_VTABLE_PER_CORE define indicating whether the two vector tables are separate,
  ## however as of version 2.1.1 the user cannot set this value, and expect the vector table duplication to be handled
  ## for them. This functionality will be added in a future SDK version
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \param handler The handler to set. See \ref irq_handler_t
  ## \see irq_add_shared_handler()

proc getExclusiveHandler*(num: InterruptNumber): IrqHandler {.importc: "irq_get_exclusive_handler".}
  ## Get the exclusive interrupt handler for an interrupt on the executing core.
  ##
  ## This method will return an exclusive IRQ handler set on this core
  ## by irq_set_exclusive_handler if there is one.
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \see irq_set_exclusive_handler()
  ## \return handler The handler if an exclusive handler is set for the IRQ,
  ##                 NULL if no handler is set or shared/shareable handlers are installed

proc addSharedHandler*(num: InterruptNumber; handler: IrqHandler; orderPriority: uint8) {.importc: "irq_add_shared_handler".}
  ## Add a shared interrupt handler for an interrupt on the executing core
  ##
  ## Use this method to add a handler on an irq number shared between multiple distinct hardware sources (e.g. GPIO, DMA or PIO IRQs).
  ## Handlers added by this method will all be called in sequence from highest order_priority to lowest. The
  ## irq_set_exclusive_handler() method should be used instead if you know there will or should only ever be one handler for the interrupt.
  ##
  ## This method will assert if there is an exclusive interrupt handler set for this irq number on this core, or if
  ## the (total across all IRQs on both cores) maximum (configurable via PICO_MAX_SHARED_IRQ_HANDLERS) number of shared handlers
  ## would be exceeded.
  ##
  ## NOTE: By default, the SDK uses a single shared vector table for both cores, and the currently installed
  ## IRQ handlers are effectively a linked list starting a vector table entry for a particular IRQ number.
  ## Therefore, this method (when using the same vector table for both cores) add the same interrupt handler
  ## for both cores.
  ##
  ## On RP2040 this was never really a cause of any confusion, because it rarely made sense to enable
  ## the same interrupt number in the NVIC on both cores (see \ref irq_set_enabled()), because the interrupt
  ## would then fire on both cores, and the interrupt handlers would race.
  ##
  ## The problem *does* exist however when dealing with interrupts which are independent on the two cores.
  ##
  ## This includes:
  ##
  ## * the core local "spare" IRQs
  ## * on RP2350 the SIO FIFO IRQ which is now the same irq number for both cores (vs RP2040 where it was two)
  ##
  ## In the cases where you want to enable the same IRQ on both cores, and both cores are sharing the same vector
  ## table, you should install the IRQ handler once - it will be used on both cores - and check the core
  ## number (via \ref get_core_num()) on each core.
  ##
  ## NOTE: It is not thread safe to add/remove/handle IRQs for the same irq number in the same vector table
  ## from both cores concurrently.
  ##
  ## NOTE: The SDK has a PICO_VTABLE_PER_CORE define indicating whether the two vector tables are separate,
  ## however as of version 2.1.1 the user cannot set this value, and expect the vector table duplication to be handled
  ## for them. This functionality will be added in a future SDK version
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \param handler The handler to set. See \ref irq_handler_t
  ## \param order_priority The order priority controls the order that handlers for the same IRQ number on the core are called.
  ## The shared irq handlers for an interrupt are all called when an IRQ fires, however the order of the calls is based
  ## on the order_priority (higher priorities are called first, identical priorities are called in undefined order). A good
  ## rule of thumb is to use PICO_SHARED_IRQ_HANDLER_DEFAULT_ORDER_PRIORITY if you don't much care, as it is in the middle of
  ## the priority range by default.
  ##
  ## \note The order_priority uses \em higher values for higher priorities which is the \em opposite of the CPU interrupt priorities passed
  ## to irq_set_priority() which use lower values for higher priorities.
  ##
  ## \see irq_set_exclusive_handler()

proc removeHandler*(num: InterruptNumber; handler: IrqHandler) {.importc: "irq_remove_handler".}
  ## Remove a specific interrupt handler for the given irq number on the executing core
  ##
  ## This method may be used to remove an irq set via either irq_set_exclusive_handler() or
  ## irq_add_shared_handler(), and will assert if the handler is not currently installed for the given
  ## IRQ number
  ##
  ## \note This method mayonly* be called from user (non IRQ code) or from within the handler
  ## itself (i.e. an IRQ handler may remove itself as part of handling the IRQ). Attempts to call
  ## from another IRQ will cause an assertion.
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \param handler The handler to removed.
  ## \see irq_set_exclusive_handler()
  ## \see irq_add_shared_handler()

proc hasHandler*(num: InterruptNumber): bool {.importc: "irq_has_handler".}
  ## Determine if there is an installed IRQ handler for the given interrupt number
  ##
  ## See \ref irq_set_exclusive_handler() for discussion on the scope of handlers
  ## when using both cores.
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \return true if the specified IRQ has a handler

proc hasSharedHandler*(num: InterruptNumber): bool {.importc: "irq_has_shared_handler".}
  ## Determine if the current IRQ andler for the given interrupt number is shared
  ##
  ## See \ref irq_set_exclusive_handler() for discussion on the scope of handlers
  ## when using both cores.
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \return true if the specified IRQ has a shared handler

proc getVtableHandler*(num: InterruptNumber): IrqHandler {.importc: "irq_get_vtable_handler".}
  ## Get the current IRQ handler for the specified IRQ from the currently installed hardware vector table (VTOR)
  ## of the execution core
  ##
  ## \param num Interrupt number \ref interrupt_nums
  ## \return the address stored in the VTABLE for the given irq number

proc clear*(intNum: InterruptNumber) {.importc: "irq_clear".}
  ## Clear a specific interrupt on the executing core
  ##
  ## This method is only useful for "software" IRQs that are not connected to hardware (e.g. IRQs 26-31 on RP2040)
  ## as the the NVIC always reflects the current state of the IRQ state of the hardware for hardware IRQs, and clearing
  ## of the IRQ state of the hardware is performed via the hardware's registers instead.
  ##
  ## \param int_num Interrupt number \ref interrupt_nums

proc setPending*(num: InterruptNumber) {.importc: "irq_set_pending".}
  ## Force an interrupt to be pending on the executing core
  ##
  ## This should generally not be used for IRQs connected to hardware.
  ##
  ## \param num Interrupt number \ref interrupt_nums

proc irqInitPriorities*() {.importc: "irq_init_priorities".}
  ## Perform IRQ priority initialization for the current core
  ##
  ## \note This is an internal method and user should generally not call it.

proc userIrqClaim*(irqNum: InterruptNumber) {.importc: "user_irq_claim".}
  ## Claim ownership of a user IRQ on the calling core
  ##
  ## User IRQs starting from FIRST_USER_IRQ are not connected to any hardware, but can be triggered by \ref irq_set_pending.
  ##
  ## \note User IRQs are a core local feature; they cannot be used to communicate between cores. Therefore all functions
  ## dealing with Uer IRQs affect only the calling core
  ##
  ## This method explicitly claims ownership of a user IRQ, so other code can know it is being used.
  ##
  ## \param irq_num the user IRQ to claim

proc userIrqUnclaim*(irqNum: InterruptNumber) {.importc: "user_irq_unclaim".}
  ## Mark a user IRQ as no longer used on the calling core
  ##
  ## User IRQs starting from FIRST_USER_IRQ are not connected to any hardware, but can be triggered by \ref irq_set_pending.
  ##
  ## \note User IRQs are a core local feature; they cannot be used to communicate between cores. Therefore all functions
  ## dealing with Uer IRQs affect only the calling core
  ##
  ## This method explicitly releases ownership of a user IRQ, so other code can know it is free to use.
  ##
  ## \note it is customary to have disabled the irq and removed the handler prior to calling this method.
  ##
  ## \param irq_num the irq irq_num to unclaim

proc userIrqClaimUnused*(required: bool): cint {.importc: "user_irq_claim_unused".}
  ## Claim ownership of a free user IRQ on the calling core
  ##
  ## User IRQs starting from FIRST_USER_IRQ are not connected to any hardware, but can be triggered by \ref irq_set_pending.
  ##
  ## \note User IRQs are a core local feature; they cannot be used to communicate between cores. Therefore all functions
  ## dealing with Uer IRQs affect only the calling core
  ##
  ## This method explicitly claims ownership of an unused user IRQ if there is one, so other code can know it is being used.
  ##
  ## \param required if true the function will panic if none are available
  ## \return the user IRQ number or -1 if required was false, and none were free

proc userIrqIsClaimed*(irqNum: InterruptNumber): bool {.importc: "user_irq_is_claimed".}
  ## Check if a user IRQ is in use on the calling core
  ##
  ## User IRQs starting from FIRST_USER_IRQ are not connected to any hardware, but can be triggered by \ref irq_set_pending.
  ##
  ## \note User IRQs are a core local feature; they cannot be used to communicate between cores. Therefore all functions
  ## dealing with Uer IRQs affect only the calling core
  ##
  ## \param irq_num the irq irq_num
  ## \return true if the irq_num is claimed, false otherwise
  ## \sa user_irq_claim
  ## \sa user_irq_unclaim
  ## \sa user_irq_claim_unused

{.pop.}
