// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "VMIPS__Syms.h"
#include "VMIPS.h"
#include "VMIPS_MIPS.h"

// FUNCTIONS
VMIPS__Syms::VMIPS__Syms(VMIPS* topp, const char* namep)
	// Setup locals
	: __Vm_namep(namep)
	, __Vm_activity(false)
	, __Vm_didInit(false)
	// Setup submodule names
	, TOP__v                         (Verilated::catName(topp->name(),"v"))
{
    // Pointer to top level
    TOPp = topp;
    // Setup each module's pointers to their submodules
    TOPp->v                         = &TOP__v;
    // Setup each module's pointer back to symbol table (for public functions)
    TOPp->__Vconfigure(this, true);
    TOP__v.__Vconfigure(this, true);
    // Setup scope names
    __Vscope_v.configure(this,name(),"v");
}

