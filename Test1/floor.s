	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 14, 0
	.globl	_pow2                           ; -- Begin function pow2
	.p2align	2
_pow2:                                  ; @pow2
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	.cfi_def_cfa_offset 32
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	fadd	d2, d1, d1
	stp	d0, d1, [sp]
	fcmp	d0, d2
	b.ge	LBB0_2
; %bb.1:                                ; %trueblock
	ldr	d0, [sp, #8]
	b	LBB0_3
LBB0_2:                                 ; %falseblock
	ldr	d0, [sp, #8]
	fadd	d1, d0, d0
	ldr	d0, [sp]
	bl	_pow2
LBB0_3:                                 ; %mergeblock
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_intpart                        ; -- Begin function intpart
	.p2align	2
_intpart:                               ; @intpart
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #48
	stp	x29, x30, [sp, #32]             ; 16-byte Folded Spill
	.cfi_def_cfa_offset 48
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	fmov	d2, d0
	fmov	d3, #1.00000000
	movi	d0, #0000000000000000
	fcmp	d2, d3
	stp	d2, d1, [sp, #8]
	b.lt	LBB1_2
; %bb.1:                                ; %falseblock
	ldr	d0, [sp, #8]
	fmov	d1, #1.00000000
	bl	_pow2
LBB1_2:                                 ; %mergeblock
	fcmp	d0, #0.0
	str	d0, [sp, #24]
	b.mi	LBB1_4
	b.gt	LBB1_4
; %bb.3:                                ; %trueblock6
	ldr	d0, [sp, #16]
	b	LBB1_5
LBB1_4:                                 ; %falseblock8
	ldp	d0, d2, [sp, #8]
	ldr	d1, [sp, #24]
	fsub	d0, d0, d1
	fadd	d1, d2, d1
	bl	_intpart
LBB1_5:                                 ; %mergeblock14
	ldp	x29, x30, [sp, #32]             ; 16-byte Folded Reload
	add	sp, sp, #48
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_floor                          ; -- Begin function floor
	.p2align	2
_floor:                                 ; @floor
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	.cfi_def_cfa_offset 32
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	movi	d1, #0000000000000000
	str	d0, [sp, #8]
	bl	_intpart
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
