/*
 * memfuncs.asm: Contains our custom memcpy and memset routines.
 *
 * See the long comment at the top of x86/memfuncs.asm.
 */

#include "../asm_defines.asm"
START_FILE
#ifdef UNIX

/* Private memcpy.
   TODO: riscv64
 */
        DECLARE_FUNC(memcpy)
GLOBAL_LABEL(memcpy:)
        ret
        END_FUNC(memcpy)

/* Private memset.
   TODO: riscv64
 */
        DECLARE_FUNC(memset)
GLOBAL_LABEL(memset:)
        ret
        END_FUNC(memset)

/* See x86.asm notes about needing these to avoid gcc invoking *_chk */
.global __memcpy_chk
.hidden __memcpy_chk
WEAK(__memcpy_chk)
.set __memcpy_chk,memcpy

.global __memset_chk
.hidden __memset_chk
WEAK(__memset_chk)
.set __memset_chk,memset

#endif /* UNIX */

END_FILE
