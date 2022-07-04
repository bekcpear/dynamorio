/*
 * TODO: riscv64
 */

/***************************************************************************
 * assembly utilities for which there are no intrinsics
 */

#include "cpp2asm_defines.h"

START_FILE

#define FUNCNAME replace_native_xfer
        DECLARE_FUNC(FUNCNAME)
GLOBAL_LABEL(FUNCNAME:)
        END_FUNC(FUNCNAME)
#undef FUNCNAME

DECLARE_GLOBAL(replace_native_ret_imms)
DECLARE_GLOBAL(replace_native_ret_imms_end)
#define FUNCNAME replace_native_rets
        DECLARE_FUNC(FUNCNAME)
GLOBAL_LABEL(FUNCNAME:)
        ret
ADDRTAKEN_LABEL(replace_native_ret_imms:)
ADDRTAKEN_LABEL(replace_native_ret_imms_end:)
        nop
        END_FUNC(FUNCNAME)
#undef FUNCNAME

#define FUNCNAME get_cur_xsp
        DECLARE_FUNC(FUNCNAME)
GLOBAL_LABEL(FUNCNAME:)
        ret
        END_FUNC(FUNCNAME)
#undef FUNCNAME

/* We just need a sentinel block that does not cause DR to complain about
 * non-executable code or illegal instrutions, for DRWRAP_REPLACE_RETADDR.
 */
#define FUNCNAME replace_retaddr_sentinel
        DECLARE_FUNC(FUNCNAME)
GLOBAL_LABEL(FUNCNAME:)
        ret
        END_FUNC(FUNCNAME)

END_FILE
