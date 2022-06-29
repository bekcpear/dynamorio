#include "../globals.h"
#include "instr.h"
#include "arch.h"

reg_id_t dr_reg_stolen = DR_REG_NULL;

uint
opnd_immed_float_arch(uint opcode)
{
    ASSERT_NOT_IMPLEMENTED(false); /* FIXME i#1551, i#1569 */
    return 0;
}

DR_API
bool
reg_is_stolen(reg_id_t reg)
{
    if (dr_reg_fixer[reg] == dr_reg_stolen && dr_reg_fixer[reg] != DR_REG_NULL)
        return true;
    return false;
}

int
opnd_get_reg_dcontext_offs(reg_id_t reg)
{
#ifdef RISCV64
  /*
   * TODO: riscv64
   * TODO: this is a copy of AARCH64
   */
    if (DR_REG_X0 <= reg && reg <= DR_REG_X30)
        return R0_OFFSET + (R1_OFFSET - R0_OFFSET) * (reg - DR_REG_X0);
    if (DR_REG_W0 <= reg && reg <= DR_REG_W30)
        return R0_OFFSET + (R1_OFFSET - R0_OFFSET) * (reg - DR_REG_W0);
    if (reg == DR_REG_XSP || reg == DR_REG_WSP)
        return XSP_OFFSET;
    CLIENT_ASSERT(false, "opnd_get_reg_dcontext_offs: invalid reg");
    return -1;
#endif
}

#ifndef STANDALONE_DECODER

opnd_t
opnd_create_sized_tls_slot(int offs, opnd_size_t size)
{
    return opnd_create_base_disp(dr_reg_stolen, REG_NULL, 0, offs, size);
}

#endif /* !STANDALONE_DECODER */
