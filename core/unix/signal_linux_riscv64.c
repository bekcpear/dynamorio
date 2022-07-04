/*
 * TODO: riscv64
 * TODO: this is just a copy of aarch64
 */
/***************************************************************************
 * signal_linux_riscv64.c - signal code for riscv64 Linux
 */

#include "signal_private.h" /* pulls in globals.h for us, in right order */

#ifndef LINUX
#    error Linux-only
#endif

#ifndef RISCV64
#    error RISCV64-only
#endif

#include "arch.h"

void
save_fpstate(dcontext_t *dcontext, sigframe_rt_t *frame)
{
    ASSERT_NOT_IMPLEMENTED(false); /* FIXME i#1569 */
}

#ifdef DEBUG
void
dump_sigcontext(dcontext_t *dcontext, sigcontext_t *sc)
{
    int i;
    for (i = 0; i <= DR_REG_X30 - DR_REG_X0; i++)
        LOG(THREAD, LOG_ASYNCH, 1, "\tx%-2d    = " PFX "\n", i, sc->regs[i]);
    LOG(THREAD, LOG_ASYNCH, 1, "\tsp     = " PFX "\n", sc->sp);
    LOG(THREAD, LOG_ASYNCH, 1, "\tpc     = " PFX "\n", sc->pc);
    LOG(THREAD, LOG_ASYNCH, 1, "\tpstate = " PFX "\n", sc->pstate);
}
#endif /* DEBUG */

void
sigcontext_to_mcontext_simd(priv_mcontext_t *mc, sig_full_cxt_t *sc_full)
{
    struct fpsimd_context *fpc = (struct fpsimd_context *)sc_full->fp_simd_state;
    if (fpc == NULL)
        return;
    ASSERT(fpc->head.magic == FPSIMD_MAGIC);
    ASSERT(fpc->head.size == sizeof(struct fpsimd_context));
    mc->fpsr = fpc->fpsr;
    mc->fpcr = fpc->fpcr;
    ASSERT(sizeof(mc->simd) == sizeof(fpc->vregs));
    memcpy(&mc->simd, &fpc->vregs, sizeof(mc->simd));
}

void
mcontext_to_sigcontext_simd(sig_full_cxt_t *sc_full, priv_mcontext_t *mc)
{
    struct fpsimd_context *fpc = (struct fpsimd_context *)sc_full->fp_simd_state;
    if (fpc == NULL)
        return;
    struct _aarch64_ctx *next = (void *)((char *)fpc + sizeof(struct fpsimd_context));
    fpc->head.magic = FPSIMD_MAGIC;
    fpc->head.size = sizeof(struct fpsimd_context);
    fpc->fpsr = mc->fpsr;
    fpc->fpcr = mc->fpcr;
    ASSERT(sizeof(fpc->vregs) == sizeof(mc->simd));
    memcpy(&fpc->vregs, &mc->simd, sizeof(fpc->vregs));
    next->magic = 0;
    next->size = 0;
}

size_t
signal_frame_extra_size(bool include_alignment)
{
    return 0;
}

void
signal_arch_init(void)
{
    /* Nothing. */
}
