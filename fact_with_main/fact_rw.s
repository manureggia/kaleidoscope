	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 14, 0
	.globl	_fact                           ; -- Begin function fact
	.p2align	2
_fact:                                  ; @fact
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #48
	stp	d9, d8, [sp, #16]               ; 16-byte Folded Spill
	stp	x29, x30, [sp, #32]             ; 16-byte Folded Spill
	.cfi_def_cfa_offset 48
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset b8, -24
	.cfi_offset b9, -32
	fmov	d1, d0
	fmov	d0, #1.00000000
	fcmp	d1, d0
	str	d1, [sp, #8]
	b.lt	LBB0_2
; %bb.1:                                ; %falseblock
	ldr	d8, [sp, #8]
	fmov	d0, #-1.00000000
	fadd	d0, d8, d0
	bl	_fact
	fmul	d0, d8, d0
LBB0_2:                                 ; %mergeblock
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #16]               ; 16-byte Folded Reload
	add	sp, sp, #48
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
	bl	_n
	bl	_fact
	bl	_printval
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
