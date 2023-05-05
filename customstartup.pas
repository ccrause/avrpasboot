unit customstartup;

// Replacement startup code used when compiling application with -Cd (discard rtl startup code)
//
{$if (FPC_FULLVERSION < 30301)}
  {$warning 'Custom startup code is unlikely to be useful on older compiler versions'}
{$endif}

interface

implementation

var
  _stack_top: record end; external name '_stack_top';
  //__dtors_end: record end; external name '__dtors_end';

procedure PASCALMAIN; external name 'PASCALMAIN';

{ custom_jump_init is only required if there is progmem data
  This jumps to the rest of the init sections, skipping over potential progmem data.
}

//procedure custom_jump_init; section '.init.0'; assembler; nostackframe; noreturn;
//asm
//  jmp __dtors_end
//end;

//procedure custom_init_zeroreg_SP; section '.init3'; assembler; nostackframe; noreturn; public name 'start';
//asm
//  clr r1
//  ldi r30,lo8(_stack_top)
//  out 0x3d,r30
//  ldi r30,hi8(_stack_top)
//  out 0x3e,r30
//end;
//
//procedure custom_jmp_main; section '.init8'; assembler; nostackframe; noreturn;
//asm
//  // Initialize .data section
//  rjmp PASCALMAIN
//end;

end.

