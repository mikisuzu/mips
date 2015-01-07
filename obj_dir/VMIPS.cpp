// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VMIPS.h for the primary calling header

#include "VMIPS.h"             // For This
#include "VMIPS__Syms.h"

//--------------------
// STATIC VARIABLES


//--------------------

VL_CTOR_IMP(VMIPS) {
    VMIPS__Syms* __restrict vlSymsp = __VlSymsp = new VMIPS__Syms(this, name());
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    VL_CELL (v, VMIPS_MIPS);
    // Reset internal values
    
    // Reset structure values
    R2_output = VL_RAND_RESET_I(32);
    data_address_2DM = VL_RAND_RESET_I(32);
    data_write_2DM = VL_RAND_RESET_I(32);
    VL_RAND_RESET_W(256,block_write_2DM);
    VL_RAND_RESET_W(256,block_write_2IM);
    MemRead = 0;
    MemWrite = 0;
    dBlkRead = 0;
    dBlkWrite = 0;
    iBlkRead = 0;
    iBlkWrite = 0;
    PC_init = VL_RAND_RESET_I(32);
    R2_input = VL_RAND_RESET_I(32);
    VL_RAND_RESET_W(256,block_read_fDM);
    VL_RAND_RESET_W(256,block_read_fIM);
    CLK = 0;
    RESET = 0;
    do_delay_syscall = 0;
    __Vclklast__TOP__CLK = 0;
    __Vclklast__TOP__RESET = 0;
}

void VMIPS::__Vconfigure(VMIPS__Syms* vlSymsp, bool first) {
    if (0 && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
}

VMIPS::~VMIPS() {
    delete __VlSymsp; __VlSymsp=NULL;
}

//--------------------


void VMIPS::eval() {
    VMIPS__Syms* __restrict vlSymsp = this->__VlSymsp; // Setup global symbol table
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    VL_DEBUG_IF(VL_PRINTF("\n----TOP Evaluate VMIPS::eval\n"); );
    int __VclockLoop = 0;
    IData __Vchange=1;
    while (VL_LIKELY(__Vchange)) {
	VL_DEBUG_IF(VL_PRINTF(" Clock loop\n"););
	vlSymsp->__Vm_activity = true;
	_eval(vlSymsp);
	__Vchange = _change_request(vlSymsp);
	if (++__VclockLoop > 100) vl_fatal(__FILE__,__LINE__,__FILE__,"Verilated model didn't converge");
    }
}

void VMIPS::_eval_initial_loop(VMIPS__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    vlSymsp->__Vm_activity = true;
    int __VclockLoop = 0;
    IData __Vchange=1;
    while (VL_LIKELY(__Vchange)) {
	_eval_settle(vlSymsp);
	_eval(vlSymsp);
	__Vchange = _change_request(vlSymsp);
	if (++__VclockLoop > 100) vl_fatal(__FILE__,__LINE__,__FILE__,"Verilated model didn't DC converge");
    }
}

//--------------------
// Internal Methods

void VMIPS::_settle__TOP__1(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_settle__TOP__1\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->R2_output = vlSymsp->TOP__v.R2_output;
    vlTOPp->block_write_2DM[0] = vlSymsp->TOP__v.block_write_2DM[0];
    vlTOPp->block_write_2DM[1] = vlSymsp->TOP__v.block_write_2DM[1];
    vlTOPp->block_write_2DM[2] = vlSymsp->TOP__v.block_write_2DM[2];
    vlTOPp->block_write_2DM[3] = vlSymsp->TOP__v.block_write_2DM[3];
    vlTOPp->block_write_2DM[4] = vlSymsp->TOP__v.block_write_2DM[4];
    vlTOPp->block_write_2DM[5] = vlSymsp->TOP__v.block_write_2DM[5];
    vlTOPp->block_write_2DM[6] = vlSymsp->TOP__v.block_write_2DM[6];
    vlTOPp->block_write_2DM[7] = vlSymsp->TOP__v.block_write_2DM[7];
    vlTOPp->iBlkWrite = vlSymsp->TOP__v.iBlkWrite;
    vlTOPp->dBlkWrite = vlSymsp->TOP__v.dBlkWrite;
    vlTOPp->block_write_2IM[0] = vlSymsp->TOP__v.block_write_2IM[0];
    vlTOPp->block_write_2IM[1] = vlSymsp->TOP__v.block_write_2IM[1];
    vlTOPp->block_write_2IM[2] = vlSymsp->TOP__v.block_write_2IM[2];
    vlTOPp->block_write_2IM[3] = vlSymsp->TOP__v.block_write_2IM[3];
    vlTOPp->block_write_2IM[4] = vlSymsp->TOP__v.block_write_2IM[4];
    vlTOPp->block_write_2IM[5] = vlSymsp->TOP__v.block_write_2IM[5];
    vlTOPp->block_write_2IM[6] = vlSymsp->TOP__v.block_write_2IM[6];
    vlTOPp->block_write_2IM[7] = vlSymsp->TOP__v.block_write_2IM[7];
}

void VMIPS::_sequent__TOP__2(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_sequent__TOP__2\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->dBlkRead = (0 == (IData)(vlSymsp->TOP__v.__PVT__dCache1__DOT__waitCount));
}

void VMIPS::_sequent__TOP__4(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_sequent__TOP__4\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->iBlkRead = (0 == (IData)(vlSymsp->TOP__v.__PVT__iCache1__DOT__waitCount));
}

void VMIPS::_sequent__TOP__5(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_sequent__TOP__5\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->data_write_2DM = vlSymsp->TOP__v.__PVT__mem_entry_LS[8];
    vlTOPp->MemRead = (1 & (vlSymsp->TOP__v.__PVT__mem_entry_LS[4] 
			    >> 7));
    vlTOPp->data_address_2DM = vlSymsp->TOP__v.__PVT__mem_entry_LS[6];
}

void VMIPS::_settle__TOP__6(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_settle__TOP__6\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->iBlkRead = (0 == (IData)(vlSymsp->TOP__v.__PVT__iCache1__DOT__waitCount));
    vlTOPp->data_address_2DM = vlSymsp->TOP__v.__PVT__mem_entry_LS[6];
    vlTOPp->data_write_2DM = vlSymsp->TOP__v.__PVT__mem_entry_LS[8];
    vlTOPp->MemRead = (1 & (vlSymsp->TOP__v.__PVT__mem_entry_LS[4] 
			    >> 7));
}

void VMIPS::_sequent__TOP__7(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_sequent__TOP__7\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->MemWrite = vlSymsp->TOP__v.MemWrite;
}

void VMIPS::_eval(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_eval\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    if (((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK)))) {
	vlSymsp->TOP__v._sequent__TOP__v__2(vlSymsp);
	vlTOPp->_sequent__TOP__2(vlSymsp);
    }
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((~ (IData)(vlTOPp->RESET)) & (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._sequent__TOP__v__3(vlSymsp);
    }
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((IData)(vlTOPp->RESET) & (~ (IData)(vlTOPp->__Vclklast__TOP__RESET))))) {
	vlSymsp->TOP__v._sequent__TOP__v__4(vlSymsp);
    }
    if (((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK)))) {
	vlSymsp->TOP__v._sequent__TOP__v__6(vlSymsp);
	vlTOPp->_sequent__TOP__4(vlSymsp);
    }
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((~ (IData)(vlTOPp->RESET)) & (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._sequent__TOP__v__7(vlSymsp);
	vlTOPp->_sequent__TOP__5(vlSymsp);
    }
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((IData)(vlTOPp->RESET) ^ (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._multiclk__TOP__v__9(vlSymsp);
    }
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((~ (IData)(vlTOPp->RESET)) & (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._sequent__TOP__v__10(vlSymsp);
	vlTOPp->_sequent__TOP__7(vlSymsp);
    }
    vlSymsp->TOP__v._combo__TOP__v__11(vlSymsp);
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((IData)(vlTOPp->RESET) ^ (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._multiclk__TOP__v__13(vlSymsp);
    }
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((~ (IData)(vlTOPp->RESET)) & (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._sequent__TOP__v__14(vlSymsp);
    }
    vlSymsp->TOP__v._combo__TOP__v__15(vlSymsp);
    vlSymsp->TOP__v._combo__TOP__v__17(vlSymsp);
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((~ (IData)(vlTOPp->RESET)) & (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._sequent__TOP__v__18(vlSymsp);
    }
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((IData)(vlTOPp->RESET) ^ (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._multiclk__TOP__v__19(vlSymsp);
    }
    vlSymsp->TOP__v._combo__TOP__v__21(vlSymsp);
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((IData)(vlTOPp->RESET) ^ (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._multiclk__TOP__v__22(vlSymsp);
    }
    if ((((IData)(vlTOPp->CLK) & (~ (IData)(vlTOPp->__Vclklast__TOP__CLK))) 
	 | ((~ (IData)(vlTOPp->RESET)) & (IData)(vlTOPp->__Vclklast__TOP__RESET)))) {
	vlSymsp->TOP__v._sequent__TOP__v__23(vlSymsp);
    }
    // Final
    vlTOPp->__Vclklast__TOP__CLK = vlTOPp->CLK;
    vlTOPp->__Vclklast__TOP__RESET = vlTOPp->RESET;
}

void VMIPS::_eval_initial(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_eval_initial\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void VMIPS::final() {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::final\n"); );
    // Variables
    VMIPS__Syms* __restrict vlSymsp = this->__VlSymsp;
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void VMIPS::_eval_settle(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_eval_settle\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlSymsp->TOP__v._settle__TOP__v__1(vlSymsp);
    vlTOPp->_settle__TOP__1(vlSymsp);
    vlTOPp->_sequent__TOP__2(vlSymsp);
    vlSymsp->TOP__v._settle__TOP__v__5(vlSymsp);
    vlTOPp->_settle__TOP__6(vlSymsp);
    vlSymsp->TOP__v._settle__TOP__v__8(vlSymsp);
    vlSymsp->TOP__v._settle__TOP__v__12(vlSymsp);
    vlTOPp->_sequent__TOP__7(vlSymsp);
    vlSymsp->TOP__v._settle__TOP__v__16(vlSymsp);
    vlSymsp->TOP__v._settle__TOP__v__20(vlSymsp);
    vlSymsp->TOP__v._settle__TOP__v__24(vlSymsp);
}

IData VMIPS::_change_request(VMIPS__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_PRINTF("    VMIPS::_change_request\n"); );
    VMIPS* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    IData __req = false;  // Logically a bool
    return __req;
}
