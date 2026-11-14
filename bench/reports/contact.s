	.build_version macos, 26, 0	sdk_version 27, 0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	__Z16compute_exposureRK6ParamsRK10PopulationRK9LocationsjRNSt3__16vectorIhNS8_9allocatorIhEEEE ; -- Begin function _Z16compute_exposureRK6ParamsRK10PopulationRK9LocationsjRNSt3__16vectorIhNS8_9allocatorIhEEEE
	.p2align	2
__Z16compute_exposureRK6ParamsRK10PopulationRK9LocationsjRNSt3__16vectorIhNS8_9allocatorIhEEEE: ; @_Z16compute_exposureRK6ParamsRK10PopulationRK9LocationsjRNSt3__16vectorIhNS8_9allocatorIhEEEE
Lfunc_begin0:
	.cfi_startproc
	.cfi_personality 155, ___gxx_personality_v0
	.cfi_lsda 16, Lexception0
; %bb.0:
	sub	sp, sp, #144
	stp	d11, d10, [sp, #16]             ; 16-byte Folded Spill
	stp	d9, d8, [sp, #32]               ; 16-byte Folded Spill
	stp	x28, x27, [sp, #48]             ; 16-byte Folded Spill
	stp	x26, x25, [sp, #64]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #80]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #96]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #112]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #128]            ; 16-byte Folded Spill
	add	x29, sp, #128
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	.cfi_offset w25, -72
	.cfi_offset w26, -80
	.cfi_offset w27, -88
	.cfi_offset w28, -96
	.cfi_offset b8, -104
	.cfi_offset b9, -112
	.cfi_offset b10, -120
	.cfi_offset b11, -128
	mov	x20, x4
	mov	x21, x3
	mov	x22, x2
	mov	x23, x1
	mov	x24, x0
	ldp	x28, x27, [x1]
	ldp	x9, x8, [x2]
	subs	x8, x8, x9
	b.eq	LBB0_3
; %bb.1:
	lsr	x9, x8, #62
	cbnz	x9, LBB0_56
; %bb.2:
	lsl	x25, x8, #2
	mov	x0, x25
	bl	__Znwm
	mov	x19, x0
	mov	x1, x25
	bl	_bzero
	sub	x25, x27, x28
	cmp	x27, x28
	b.ne	LBB0_4
	b	LBB0_29
LBB0_3:
	mov	x19, #0                         ; =0x0
	sub	x25, x27, x28
	cmp	x27, x28
	b.eq	LBB0_29
LBB0_4:
	ldr	x9, [x23, #48]
	ldr	x10, [x23, #72]
	and	x8, x25, #0x7
	sub	x11, x28, x27
	cmn	x11, #8
	b.ls	LBB0_6
; %bb.5:
	mov	x11, #0                         ; =0x0
	cbnz	x8, LBB0_25
	b	LBB0_29
LBB0_6:
	mov	x11, #0                         ; =0x0
	and	x12, x25, #0xfffffffffffffff8
	neg	x12, x12
	add	x13, x28, #3
	add	x14, x10, #16
	add	x15, x9, #16
	b	LBB0_8
LBB0_7:                                 ;   in Loop: Header=BB0_8 Depth=1
	sub	x11, x11, #8
	add	x13, x13, #8
	add	x14, x14, #32
	add	x15, x15, #32
	cmp	x12, x11
	b.eq	LBB0_24
LBB0_8:                                 ; =>This Inner Loop Header: Depth=1
	ldurb	w16, [x13, #-3]
	cmp	w16, #2
	b.eq	LBB0_16
; %bb.9:                                ;   in Loop: Header=BB0_8 Depth=1
	ldurb	w16, [x13, #-2]
	cmp	w16, #2
	b.eq	LBB0_17
LBB0_10:                                ;   in Loop: Header=BB0_8 Depth=1
	ldurb	w16, [x13, #-1]
	cmp	w16, #2
	b.eq	LBB0_18
LBB0_11:                                ;   in Loop: Header=BB0_8 Depth=1
	ldrb	w16, [x13]
	cmp	w16, #2
	b.eq	LBB0_19
LBB0_12:                                ;   in Loop: Header=BB0_8 Depth=1
	ldrb	w16, [x13, #1]
	cmp	w16, #2
	b.eq	LBB0_20
LBB0_13:                                ;   in Loop: Header=BB0_8 Depth=1
	ldrb	w16, [x13, #2]
	cmp	w16, #2
	b.eq	LBB0_21
LBB0_14:                                ;   in Loop: Header=BB0_8 Depth=1
	ldrb	w16, [x13, #3]
	cmp	w16, #2
	b.eq	LBB0_22
LBB0_15:                                ;   in Loop: Header=BB0_8 Depth=1
	ldrb	w16, [x13, #4]
	cmp	w16, #2
	b.ne	LBB0_7
	b	LBB0_23
LBB0_16:                                ;   in Loop: Header=BB0_8 Depth=1
	ldur	w16, [x15, #-16]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldur	w16, [x14, #-16]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldurb	w16, [x13, #-2]
	cmp	w16, #2
	b.ne	LBB0_10
LBB0_17:                                ;   in Loop: Header=BB0_8 Depth=1
	ldur	w16, [x15, #-12]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldur	w16, [x14, #-12]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldurb	w16, [x13, #-1]
	cmp	w16, #2
	b.ne	LBB0_11
LBB0_18:                                ;   in Loop: Header=BB0_8 Depth=1
	ldur	w16, [x15, #-8]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldur	w16, [x14, #-8]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldrb	w16, [x13]
	cmp	w16, #2
	b.ne	LBB0_12
LBB0_19:                                ;   in Loop: Header=BB0_8 Depth=1
	ldur	w16, [x15, #-4]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldur	w16, [x14, #-4]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldrb	w16, [x13, #1]
	cmp	w16, #2
	b.ne	LBB0_13
LBB0_20:                                ;   in Loop: Header=BB0_8 Depth=1
	ldr	w16, [x15]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldr	w16, [x14]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldrb	w16, [x13, #2]
	cmp	w16, #2
	b.ne	LBB0_14
LBB0_21:                                ;   in Loop: Header=BB0_8 Depth=1
	ldr	w16, [x15, #4]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldr	w16, [x14, #4]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldrb	w16, [x13, #3]
	cmp	w16, #2
	b.ne	LBB0_15
LBB0_22:                                ;   in Loop: Header=BB0_8 Depth=1
	ldr	w16, [x15, #8]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldr	w16, [x14, #8]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldrb	w16, [x13, #4]
	cmp	w16, #2
	b.ne	LBB0_7
LBB0_23:                                ;   in Loop: Header=BB0_8 Depth=1
	ldr	w16, [x15, #12]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	ldr	w16, [x14, #12]
	ldr	w17, [x19, x16, lsl #2]
	add	w17, w17, #1
	str	w17, [x19, x16, lsl #2]
	b	LBB0_7
LBB0_24:
	neg	x11, x11
	cbz	x8, LBB0_29
LBB0_25:
	lsl	x12, x11, #2
	add	x10, x10, x12
	add	x9, x9, x12
	add	x11, x28, x11
	b	LBB0_27
LBB0_26:                                ;   in Loop: Header=BB0_27 Depth=1
	add	x10, x10, #4
	add	x9, x9, #4
	subs	x8, x8, #1
	b.eq	LBB0_29
LBB0_27:                                ; =>This Inner Loop Header: Depth=1
	ldrb	w12, [x11], #1
	cmp	w12, #2
	b.ne	LBB0_26
; %bb.28:                               ;   in Loop: Header=BB0_27 Depth=1
	ldr	w12, [x9]
	ldr	w13, [x19, x12, lsl #2]
	add	w13, w13, #1
	str	w13, [x19, x12, lsl #2]
	ldr	w12, [x10]
	ldr	w13, [x19, x12, lsl #2]
	add	w13, w13, #1
	str	w13, [x19, x12, lsl #2]
	b	LBB0_26
LBB0_29:
	ldr	x8, [x20, #16]
	ldr	x0, [x20]
	sub	x9, x8, x0
	cmp	x25, x9
	b.ls	LBB0_35
; %bb.30:
	str	x28, [sp, #8]                   ; 8-byte Folded Spill
	cbz	x0, LBB0_32
; %bb.31:
	str	x0, [x20, #8]
	bl	__ZdlPv
	mov	x8, #0                          ; =0x0
	stp	xzr, xzr, [x20]
	str	xzr, [x20, #16]
LBB0_32:
	tbnz	x25, #63, LBB0_57
; %bb.33:
	mov	x28, x27
	lsl	x9, x8, #1
	cmp	x9, x25
	csel	x9, x9, x25, hi
	mov	x10, #4611686018427387903       ; =0x3fffffffffffffff
	mov	x11, #9223372036854775807       ; =0x7fffffffffffffff
	cmp	x8, x10
	csel	x27, x9, x11, lo
Ltmp0:
	mov	x0, x27
	bl	__Znwm
Ltmp1:
; %bb.34:
	mov	x26, x0
	str	x0, [x20]
	add	x8, x0, x27
	str	x8, [x20, #16]
	mov	x1, x25
	bl	_bzero
	add	x8, x26, x25
	str	x8, [x20, #8]
	mov	x27, x28
	ldr	x28, [sp, #8]                   ; 8-byte Folded Reload
	cmp	x27, x28
	b.ne	LBB0_40
	b	LBB0_53
LBB0_35:
	ldr	x8, [x20, #8]
	sub	x26, x8, x0
	cmp	x26, x25
	csel	x1, x26, x25, lo
	cbz	x1, LBB0_37
; %bb.36:
	bl	_bzero
LBB0_37:
	subs	x26, x25, x26
	b.ls	LBB0_39
; %bb.38:
	str	x28, [sp, #8]                   ; 8-byte Folded Spill
	mov	x28, x27
	ldr	x27, [x20, #8]
	mov	x0, x27
	mov	x1, x26
	bl	_bzero
	add	x8, x27, x26
	mov	x27, x28
	ldr	x28, [sp, #8]                   ; 8-byte Folded Reload
	str	x8, [x20, #8]
	cmp	x27, x28
	b.ne	LBB0_40
	b	LBB0_53
LBB0_39:
	ldr	x8, [x20]
	add	x8, x8, x25
	str	x8, [x20, #8]
	cmp	x27, x28
	b.eq	LBB0_53
LBB0_40:
	mov	x26, #0                         ; =0x0
	fmov	d8, #1.00000000
	b	LBB0_44
LBB0_41:                                ;   in Loop: Header=BB0_44 Depth=1
	mov	w8, #1                          ; =0x1
LBB0_42:                                ;   in Loop: Header=BB0_44 Depth=1
	ldr	x9, [x20]
	strb	w8, [x9, x26]
LBB0_43:                                ;   in Loop: Header=BB0_44 Depth=1
	add	x26, x26, #1
	cmp	x25, x26
	b.eq	LBB0_53
LBB0_44:                                ; =>This Inner Loop Header: Depth=1
	ldr	x8, [x23]
	ldrb	w8, [x8, x26]
	cbnz	w8, LBB0_43
; %bb.45:                               ;   in Loop: Header=BB0_44 Depth=1
	ldr	x8, [x23, #48]
	ldr	w8, [x8, x26, lsl #2]
	ldr	x9, [x23, #72]
	ldr	w27, [x9, x26, lsl #2]
	ldr	x28, [x22, #24]
	ldr	w9, [x28, x8, lsl #2]
	movi.2d	v9, #0000000000000000
	movi.2d	v10, #0000000000000000
	cbz	w9, LBB0_47
; %bb.46:                               ;   in Loop: Header=BB0_44 Depth=1
	ldr	s0, [x19, x8, lsl #2]
	ldr	d1, [x24, #24]
	ucvtf	d0, d0
	fnmul	d0, d1, d0
	ucvtf	d1, w9
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d10, d8, d0
LBB0_47:                                ;   in Loop: Header=BB0_44 Depth=1
	ldr	w8, [x28, x27, lsl #2]
	cbz	w8, LBB0_49
; %bb.48:                               ;   in Loop: Header=BB0_44 Depth=1
	ldr	s0, [x19, x27, lsl #2]
	ldr	d1, [x24, #32]
	ucvtf	d0, d0
	fnmul	d0, d1, d0
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d9, d8, d0
LBB0_49:                                ;   in Loop: Header=BB0_44 Depth=1
	ldr	x0, [x24, #16]
Ltmp2:
	mov	x1, x26
	mov	x2, x21
	mov	w3, #3                          ; =0x3
	bl	__Z6rand01yjjj
Ltmp3:
; %bb.50:                               ;   in Loop: Header=BB0_44 Depth=1
	fcmp	d0, d10
	b.mi	LBB0_41
; %bb.51:                               ;   in Loop: Header=BB0_44 Depth=1
	ldr	x0, [x24, #16]
Ltmp4:
	mov	x1, x26
	mov	x2, x21
	mov	w3, #4                          ; =0x4
	bl	__Z6rand01yjjj
Ltmp5:
; %bb.52:                               ;   in Loop: Header=BB0_44 Depth=1
	fcmp	d0, d9
	cset	w8, mi
	b	LBB0_42
LBB0_53:
	cbz	x19, LBB0_55
; %bb.54:
	mov	x0, x19
	ldp	x29, x30, [sp, #128]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #112]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #96]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #80]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #64]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #48]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #32]               ; 16-byte Folded Reload
	ldp	d11, d10, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #144
	b	__ZdlPv
LBB0_55:
	ldp	x29, x30, [sp, #128]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #112]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #96]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #80]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #64]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #48]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #32]               ; 16-byte Folded Reload
	ldp	d11, d10, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #144
	ret
LBB0_56:
	bl	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev
LBB0_57:
Ltmp7:
	bl	__ZNSt3__16vectorIhNS_9allocatorIhEEE20__throw_length_errorB9nqe220106Ev
Ltmp8:
; %bb.58:
	brk	#0x1
LBB0_59:
Ltmp9:
	b	LBB0_61
LBB0_60:
Ltmp6:
LBB0_61:
	mov	x20, x0
	cbz	x19, LBB0_63
; %bb.62:
	mov	x0, x19
	bl	__ZdlPv
LBB0_63:
	mov	x0, x20
	bl	__Unwind_Resume
Lfunc_end0:
	.cfi_endproc
	.section	__TEXT,__gcc_except_tab
	.p2align	2, 0x0
GCC_except_table0:
Lexception0:
	.byte	255                             ; @LPStart Encoding = omit
	.byte	255                             ; @TType Encoding = omit
	.byte	1                               ; Call site Encoding = uleb128
	.uleb128 Lcst_end0-Lcst_begin0
Lcst_begin0:
	.uleb128 Lfunc_begin0-Lfunc_begin0      ; >> Call Site 1 <<
	.uleb128 Ltmp0-Lfunc_begin0             ;   Call between Lfunc_begin0 and Ltmp0
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp0-Lfunc_begin0             ; >> Call Site 2 <<
	.uleb128 Ltmp1-Ltmp0                    ;   Call between Ltmp0 and Ltmp1
	.uleb128 Ltmp9-Lfunc_begin0             ;     jumps to Ltmp9
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp1-Lfunc_begin0             ; >> Call Site 3 <<
	.uleb128 Ltmp2-Ltmp1                    ;   Call between Ltmp1 and Ltmp2
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp2-Lfunc_begin0             ; >> Call Site 4 <<
	.uleb128 Ltmp5-Ltmp2                    ;   Call between Ltmp2 and Ltmp5
	.uleb128 Ltmp6-Lfunc_begin0             ;     jumps to Ltmp6
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp5-Lfunc_begin0             ; >> Call Site 5 <<
	.uleb128 Ltmp7-Ltmp5                    ;   Call between Ltmp5 and Ltmp7
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp7-Lfunc_begin0             ; >> Call Site 6 <<
	.uleb128 Ltmp8-Ltmp7                    ;   Call between Ltmp7 and Ltmp8
	.uleb128 Ltmp9-Lfunc_begin0             ;     jumps to Ltmp9
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp8-Lfunc_begin0             ; >> Call Site 7 <<
	.uleb128 Lfunc_end0-Ltmp8               ;   Call between Ltmp8 and Lfunc_end0
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
Lcst_end0:
	.p2align	2, 0x0
                                        ; -- End function
	.section	__TEXT,__text,regular,pure_instructions
	.private_extern	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev ; -- Begin function _ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev
	.globl	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev
	.weak_def_can_be_hidden	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev
	.p2align	2
__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev: ; @_ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh0:
	adrp	x0, l_.str@PAGE
Lloh1:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZNSt3__120__throw_length_errorB9nqe220106EPKc ; -- Begin function _ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.globl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.weak_def_can_be_hidden	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.p2align	2
__ZNSt3__120__throw_length_errorB9nqe220106EPKc: ; @_ZNSt3__120__throw_length_errorB9nqe220106EPKc
Lfunc_begin1:
	.cfi_startproc
	.cfi_personality 155, ___gxx_personality_v0
	.cfi_lsda 16, Lexception1
; %bb.0:
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	mov	x20, x0
	mov	w0, #16                         ; =0x10
	bl	___cxa_allocate_exception
	mov	x19, x0
Ltmp10:
	mov	x1, x20
	bl	__ZNSt12length_errorC1B9nqe220106EPKc
Ltmp11:
; %bb.1:
Lloh2:
	adrp	x1, __ZTISt12length_error@GOTPAGE
Lloh3:
	ldr	x1, [x1, __ZTISt12length_error@GOTPAGEOFF]
Lloh4:
	adrp	x2, __ZNSt12length_errorD1Ev@GOTPAGE
Lloh5:
	ldr	x2, [x2, __ZNSt12length_errorD1Ev@GOTPAGEOFF]
	mov	x0, x19
	bl	___cxa_throw
LBB2_2:
Ltmp12:
	mov	x20, x0
	mov	x0, x19
	bl	___cxa_free_exception
	mov	x0, x20
	bl	__Unwind_Resume
	.loh AdrpLdrGot	Lloh4, Lloh5
	.loh AdrpLdrGot	Lloh2, Lloh3
Lfunc_end1:
	.cfi_endproc
	.section	__TEXT,__gcc_except_tab
	.p2align	2, 0x0
GCC_except_table2:
Lexception1:
	.byte	255                             ; @LPStart Encoding = omit
	.byte	255                             ; @TType Encoding = omit
	.byte	1                               ; Call site Encoding = uleb128
	.uleb128 Lcst_end1-Lcst_begin1
Lcst_begin1:
	.uleb128 Lfunc_begin1-Lfunc_begin1      ; >> Call Site 1 <<
	.uleb128 Ltmp10-Lfunc_begin1            ;   Call between Lfunc_begin1 and Ltmp10
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp10-Lfunc_begin1            ; >> Call Site 2 <<
	.uleb128 Ltmp11-Ltmp10                  ;   Call between Ltmp10 and Ltmp11
	.uleb128 Ltmp12-Lfunc_begin1            ;     jumps to Ltmp12
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp11-Lfunc_begin1            ; >> Call Site 3 <<
	.uleb128 Lfunc_end1-Ltmp11              ;   Call between Ltmp11 and Lfunc_end1
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
Lcst_end1:
	.p2align	2, 0x0
                                        ; -- End function
	.section	__TEXT,__text,regular,pure_instructions
	.private_extern	__ZNSt12length_errorC1B9nqe220106EPKc ; -- Begin function _ZNSt12length_errorC1B9nqe220106EPKc
	.globl	__ZNSt12length_errorC1B9nqe220106EPKc
	.weak_def_can_be_hidden	__ZNSt12length_errorC1B9nqe220106EPKc
	.p2align	2
__ZNSt12length_errorC1B9nqe220106EPKc:  ; @_ZNSt12length_errorC1B9nqe220106EPKc
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	__ZNSt11logic_errorC2EPKc
Lloh6:
	adrp	x8, __ZTVSt12length_error@GOTPAGE
Lloh7:
	ldr	x8, [x8, __ZTVSt12length_error@GOTPAGEOFF]
	add	x8, x8, #16
	str	x8, [x0]
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.loh AdrpLdrGot	Lloh6, Lloh7
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZNSt3__16vectorIhNS_9allocatorIhEEE20__throw_length_errorB9nqe220106Ev ; -- Begin function _ZNSt3__16vectorIhNS_9allocatorIhEEE20__throw_length_errorB9nqe220106Ev
	.globl	__ZNSt3__16vectorIhNS_9allocatorIhEEE20__throw_length_errorB9nqe220106Ev
	.weak_def_can_be_hidden	__ZNSt3__16vectorIhNS_9allocatorIhEEE20__throw_length_errorB9nqe220106Ev
	.p2align	2
__ZNSt3__16vectorIhNS_9allocatorIhEEE20__throw_length_errorB9nqe220106Ev: ; @_ZNSt3__16vectorIhNS_9allocatorIhEEE20__throw_length_errorB9nqe220106Ev
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh8:
	adrp	x0, l_.str@PAGE
Lloh9:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh8, Lloh9
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"vector"

.subsections_via_symbols
