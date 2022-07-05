/***************************************************************************
 * TODO: riscv64
 * RISCV64-specific assembly and trampoline code
 */

#include "../asm_defines.asm"
START_FILE
#include "include/syscall.h"

#ifndef UNIX
# error Non-Unix is not supported
#endif

/* sizeof(priv_mcontext_t) rounded up to a multiple of 16 */
#define PRIV_MCONTEXT_SIZE 800

/* offset of priv_mcontext_t in dr_mcontext_t */
#define PRIV_MCONTEXT_OFFSET 16

#if PRIV_MCONTEXT_OFFSET < 16 || PRIV_MCONTEXT_OFFSET % 16 != 0
# error PRIV_MCONTEXT_OFFSET
#endif

/* offsetof(spill_state_t, r0) */
#define spill_state_r0_OFFSET 0
/* offsetof(spill_state_t, r1) */
#define spill_state_r1_OFFSET 8
/* offsetof(spill_state_t, r2) */
#define spill_state_r2_OFFSET 16
/* offsetof(spill_state_t, r3) */
#define spill_state_r3_OFFSET 24
/* offsetof(spill_state_t, r4) */
#define spill_state_r4_OFFSET 32
/* offsetof(spill_state_t, r5) */
#define spill_state_r5_OFFSET 40
/* offsetof(spill_state_t, dcontext) */
#define spill_state_dcontext_OFFSET 56
/* offsetof(spill_state_t, fcache_return) */
#define spill_state_fcache_return_OFFSET 64

/* offsetof(priv_mcontext_t, simd) */
#define simd_OFFSET (16 * ARG_SZ*2 + 32)
/* offsetof(dcontext_t, dstack) */
#define dstack_OFFSET     0x368
/* offsetof(dcontext_t, is_exiting) */
#define is_exiting_OFFSET (dstack_OFFSET+1*ARG_SZ)
/* offsetof(struct tlsdesc_t, arg) */
#define tlsdesc_arg_OFFSET 8

/* offsetof(icache_op_struct_t, flag) */
#define icache_op_struct_flag_OFFSET 0
/* offsetof(icache_op_struct_t, lock) */
#define icache_op_struct_lock_OFFSET 4
/* offsetof(icache_op_struct_t, linesize) */
#define icache_op_struct_linesize_OFFSET 8
/* offsetof(icache_op_struct_t, begin) */
#define icache_op_struct_begin_OFFSET 16
/* offsetof(icache_op_struct_t, end) */
#define icache_op_struct_end_OFFSET 24
/* offsetof(icache_op_struct_t, spill) */
#define icache_op_struct_spill_OFFSET 32

/* TODO: riscv64 */
#define MCXT_NUM_SIMD_SLOTS 32
#define SIMD_REG_SIZE       16
#define NUM_GPR_SLOTS       33 /* incl flags */
#define GPR_REG_SIZE         8

#ifndef X64
# error X64 must be defined
#endif

#if defined(UNIX)
DECL_EXTERN(dr_setjmp_sigmask)
#endif

DECL_EXTERN(d_r_internal_error)

/* For debugging: report an error if the function called by call_switch_stack()
 * unexpectedly returns.  Also used elsewhere.
 */
        DECLARE_FUNC(unexpected_return)
GLOBAL_LABEL(unexpected_return:)
        END_FUNC(unexpected_return)

/* bool mrs_id_reg_supported(void)
 * Checks for kernel support of the MRS instr when reading system registers
 * above exception level EL0, by attempting to read Instruction Set Attribute
 * Register 0. Some older Linux kernels do not support reading system registers
 * above exception level 0 (EL0), raising a SIGILL. This is rare now as later
 * versions have all implemented a trap-and-emulate mechanism for a set of
 * system registers above EL0, of which ID_AA64ISAR0_EL1 is one.
 */
        DECLARE_FUNC(mrs_id_reg_supported)
GLOBAL_LABEL(mrs_id_reg_supported:)
        ret
        END_FUNC(mrs_id_reg_supported)

/* void call_switch_stack(void *func_arg,             // REG_X0
 *                        byte *stack,                // REG_X1
 *                        void (*func)(void *arg),    // REG_X2
 *                        void *mutex_to_free,        // REG_X3
 *                        bool return_on_return)      // REG_W4
 */
        DECLARE_FUNC(call_switch_stack)
GLOBAL_LABEL(call_switch_stack:)
        ret
        END_FUNC(call_switch_stack)

/*
 * Calls the specified function 'func' after switching to the DR stack
 * for the thread corresponding to 'drcontext'.
 * Passes in 8 arguments.  Uses the C calling convention, so 'func' will work
 * just fine even if if takes fewer than 8 args.
 * Swaps the stack back upon return and returns the value returned by 'func'.
 *
 * void * dr_call_on_clean_stack(void *drcontext,
 *                               void *(*func)(arg1...arg8),
 *                               void *arg1,
 *                               void *arg2,
 *                               void *arg3,
 *                               void *arg4,
 *                               void *arg5,
 *                               void *arg6,
 *                               void *arg7,
 *                               void *arg8)
 */
        DECLARE_EXPORTED_FUNC(dr_call_on_clean_stack)
GLOBAL_LABEL(dr_call_on_clean_stack:)
        ret
        END_FUNC(dr_call_on_clean_stack)

#ifndef NOT_DYNAMORIO_CORE_PROPER

#ifdef DR_APP_EXPORTS

/* Save priv_mcontext_t, except for X0, X1, X30, SP and PC, to the address in X0.
 * Typically the caller will save those five registers itself before calling this.
 * Clobbers X1-X4.
 */
save_priv_mcontext_helper:
        ret

        DECLARE_EXPORTED_FUNC(dr_app_start)
GLOBAL_LABEL(dr_app_start:)
        ret
        END_FUNC(dr_app_start)

        DECLARE_EXPORTED_FUNC(dr_app_take_over)
GLOBAL_LABEL(dr_app_take_over:)
        ret
        END_FUNC(dr_app_running_under_dynamorio)

#endif /* DR_APP_EXPORTS */

        DECLARE_EXPORTED_FUNC(dynamorio_app_take_over)
GLOBAL_LABEL(dynamorio_app_take_over:)
        ret
        END_FUNC(dynamorio_app_take_over)

/*
 * cleanup_and_terminate(dcontext_t *dcontext,     // X0 -> X19
 *                       int sysnum,               // W1 -> W20 = syscall #
 *                       int sys_arg1/param_base,  // W2 -> W21 = arg1 for syscall
 *                       int sys_arg2,             // W3 -> W22 = arg2 for syscall
 *                       bool exitproc,            // W4 -> W23
 *                       (2 more args that are ignored: Mac-only))
 *
 * See decl in arch_exports.h for description.
 */
        DECLARE_FUNC(cleanup_and_terminate)
GLOBAL_LABEL(cleanup_and_terminate:)
        END_FUNC(cleanup_and_terminate)

#endif /* NOT_DYNAMORIO_CORE_PROPER */

        /* void atomic_add(int *adr, int val) */
        DECLARE_FUNC(atomic_add)
GLOBAL_LABEL(atomic_add:)
        ret

        DECLARE_FUNC(global_do_syscall_int)
GLOBAL_LABEL(global_do_syscall_int:)
        END_FUNC(global_do_syscall_int)

DECLARE_GLOBAL(safe_read_asm_pre)
DECLARE_GLOBAL(safe_read_asm_mid)
DECLARE_GLOBAL(safe_read_asm_post)
DECLARE_GLOBAL(safe_read_asm_recover)

/* i#350: Xref comment in x86.asm about safe_read.
 *
 * FIXME i#1569: NYI: We need to save the PC's that can fault and have
 * is_safe_read_pc() identify them.
 *
 * FIXME i#1569: We should optimize this as it can be on the critical path.
 *
 * void *safe_read_asm(void *dst, const void *src, size_t n);
 */
        DECLARE_FUNC(safe_read_asm)
GLOBAL_LABEL(safe_read_asm:)
        ret
        END_FUNC(safe_read_asm)

/* Xref x86.asm dr_try_start about calling dr_setjmp without a call frame.
 *
 * int dr_try_start(try_except_context_t *cxt) ;
 */
        DECLARE_EXPORTED_FUNC(dr_try_start)
GLOBAL_LABEL(dr_try_start:)
        END_FUNC(dr_try_start)

/* We save only the callee-saved registers: X19-X30, (gap), SP, D8-D15:
 * a total of 22 reg_t (64-bit) slots. See definition of dr_jmp_buf_t.
 * The gap is for better alignment of the D registers.
 *
 * int dr_setjmp(dr_jmp_buf_t *buf);
 */
        DECLARE_FUNC(dr_setjmp)
GLOBAL_LABEL(dr_setjmp:)
        ret
        END_FUNC(dr_setjmp)

/* int dr_longjmp(dr_jmp_buf_t *buf,  int val);
 */
        DECLARE_FUNC(dr_longjmp)
GLOBAL_LABEL(dr_longjmp:)
        END_FUNC(dr_longjmp)

        /* int atomic_swap(int *adr, int val) */
        DECLARE_FUNC(atomic_swap)
GLOBAL_LABEL(atomic_swap:)
        ret
        END_FUNC(atomic_swap)

#ifdef UNIX
        DECLARE_FUNC(client_int_syscall)
GLOBAL_LABEL(client_int_syscall:)
        END_FUNC(_dynamorio_runtime_resolve)
#endif /* UNIX */

#ifdef LINUX
/* thread_id_t dynamorio_clone(uint flags, byte *newsp, void *ptid, void *tls,
 *                             void *ctid, void (*func)(void))
 */
        DECLARE_FUNC(dynamorio_clone)
GLOBAL_LABEL(dynamorio_clone:)
        ret
        END_FUNC(dynamorio_clone)

        DECLARE_FUNC(dynamorio_sigreturn)
GLOBAL_LABEL(dynamorio_sigreturn:)
        END_FUNC(dynamorio_sigreturn)

        DECLARE_FUNC(dynamorio_sys_exit)
GLOBAL_LABEL(dynamorio_sys_exit:)
        END_FUNC(dynamorio_sys_exit)

# ifndef NOT_DYNAMORIO_CORE_PROPER

#  ifndef HAVE_SIGALTSTACK
#   error NYI
#  endif
        DECLARE_FUNC(main_signal_handler)
GLOBAL_LABEL(main_signal_handler:)
        END_FUNC(main_signal_handler)

# endif /* NOT_DYNAMORIO_CORE_PROPER */

#endif /* LINUX */

        DECLARE_FUNC(hashlookup_null_handler)
GLOBAL_LABEL(hashlookup_null_handler:)
        END_FUNC(hashlookup_null_handler)

        DECLARE_FUNC(back_from_native_retstubs)
GLOBAL_LABEL(back_from_native_retstubs:)
DECLARE_GLOBAL(back_from_native_retstubs_end)
ADDRTAKEN_LABEL(back_from_native_retstubs_end:)
        END_FUNC(back_from_native_retstubs)

        DECLARE_FUNC(back_from_native)
GLOBAL_LABEL(back_from_native:)
        END_FUNC(back_from_native)

/* A static resolver for TLS descriptors, implemented in assembler as
 * it does not use the standard calling convention. In C, it could be:
 *
 * ptrdiff_t
 * tlsdesc_resolver(struct tlsdesc_t *tlsdesc)
 * {
 *     return (ptrdiff_t)tlsdesc->arg;
 * }
 */
        DECLARE_FUNC(tlsdesc_resolver)
GLOBAL_LABEL(tlsdesc_resolver:)
        ret

/* This function is called from the fragment cache when the original code had
 * IC IVAU, Xt. Typically it just records which cache lines have been invalidated
 * and sets icache_op_struct.flag. However, if non-contiguous cache lines have
 * been invalidated we branch to fcache_return instead of returning.
 * When we enter here:
 *
 * X0 contains the pointer to spill_state_t.
 * X30 contains the return address in the fragment cache.
 * TLS_REG0_SLOT contains app's X0.
 * TLS_REG1_SLOT contains app's X30.
 * TLS_REG2_SLOT contains the argument of "IC IVAU, Xt".
 * TLS_REG3_SLOT contains the original address of the instruction after the IC.
 *
 * If we return, the first two slots and all registers except X0 and X30 must
 * be preserved.
 *
 * XXX: We do not correctly handle the case where the set of contiguous cache
 * lines covers the entire address space, so begin == end again, but that would
 * require more than 1e14 calls to this function even with the largest possible
 * icache line.
 */
        DECLARE_FUNC(icache_op_ic_ivau_asm)
GLOBAL_LABEL(icache_op_ic_ivau_asm:)
        END_FUNC(icache_op_ic_ivau_asm)

/* This code is branched to from the fragment cache when the original code had
 * ISB and icache_op_struct.flag was found to be set. We must reset icache_op_struct,
 * then branch to fcache_return, where we will call flush_fragments_from_region.
 * When we enter here:
 *
 * X0 contains the pointer to spill_state_t.
 * X1 contains the original address of the instruction after the ISB.
 * X2 is corrupted.
 * TLS_REG0_SLOT contains app's X0.
 * TLS_REG1_SLOT contains app's X1.
 * TLS_REG2_SLOT contains app's X2.
 */
        DECLARE_FUNC(icache_op_isb_asm)
GLOBAL_LABEL(icache_op_isb_asm:)
        END_FUNC(icache_op_isb_asm)

END_FILE
