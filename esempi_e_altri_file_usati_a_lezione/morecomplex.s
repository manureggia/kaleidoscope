	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 14, 0
	.globl	_f                              ; -- Begin function f
	.p2align	2
_f:                                     ; @f
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #16
	.cfi_def_cfa_offset 16
	fmov	d2, d0
	fmov	d0, #3.00000000
	fmul	d0, d1, d0
	fadd	d3, d2, d2
	fmul	d4, d2, d2
	fmul	d0, d0, d1
	fmul	d3, d3, d1
	fsub	d3, d4, d3
	fadd	d0, d3, d0
	stp	d2, d1, [sp], #16
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_helper                         ; -- Begin function helper
	.p2align	2
_helper:                                ; @helper
	.cfi_startproc
; %bb.0:                                ; %entry
	stp	d9, d8, [sp, #-32]!             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	.cfi_def_cfa_offset 32
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset b8, -24
	.cfi_offset b9, -32
	bl	_x
	fmov	d8, d0
	bl	_y
	fmov	d1, d0
	fmov	d0, d8
	bl	_f
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp], #32               ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:                                ; %entry
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	.cfi_def_cfa_offset 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_helper
	bl	_printval
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
