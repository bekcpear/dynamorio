/***************************************************************************
 * RISCV64-specific assembly and trampoline code, shared with non-core-DR-lib
 * TODO: riscv64
 */

#include "../asm_defines.asm"
START_FILE

/*
 * ptr_int_t dynamorio_syscall(uint sysnum, uint num_args, ...);
 *
 * Linux arm64 system call:
 * - x8: syscall number
 * - x0..x6: syscall arguments
 */
        DECLARE_FUNC(dynamorio_syscall)
GLOBAL_LABEL(dynamorio_syscall:)
        ret

#define FUNCNAME dr_fpu_exception_init
        DECLARE_FUNC(FUNCNAME)
GLOBAL_LABEL(FUNCNAME:)
        ret
        END_FUNC(FUNCNAME)
#undef FUNCNAME

END_FILE
