	.build_version macos, 26, 0	sdk_version 27, 0
	.section	__TEXT,__literal8,8byte_literals
	.p2align	3, 0x0                          ; -- Begin function _Z17run_simulation_v1RK6Params
lCPI0_0:
	.short	0                               ; 0x0
	.short	1                               ; 0x1
	.short	2                               ; 0x2
	.short	3                               ; 0x3
	.section	__TEXT,__text,regular,pure_instructions
	.globl	__Z17run_simulation_v1RK6Params
	.p2align	2
__Z17run_simulation_v1RK6Params:        ; @_Z17run_simulation_v1RK6Params
Lfunc_begin0:
	.cfi_startproc
	.cfi_personality 155, ___gxx_personality_v0
	.cfi_lsda 16, Lexception0
; %bb.0:
	stp	d13, d12, [sp, #-144]!          ; 16-byte Folded Spill
	stp	d11, d10, [sp, #16]             ; 16-byte Folded Spill
	stp	d9, d8, [sp, #32]               ; 16-byte Folded Spill
	stp	x28, x27, [sp, #48]             ; 16-byte Folded Spill
	stp	x26, x25, [sp, #64]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #80]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #96]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #112]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #128]            ; 16-byte Folded Spill
	add	x29, sp, #128
	sub	sp, sp, #416
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
	.cfi_offset b12, -136
	.cfi_offset b13, -144
	mov	x25, x8
	ldp	q1, q0, [x0, #16]
	stp	q1, q0, [x29, #-208]
	ldr	q0, [x0]
	stur	q0, [x29, #-224]
	ldurh	w8, [x29, #-180]
	cbz	w8, LBB0_12
; %bb.1:
	ldurh	w8, [x29, #-178]
	cbz	w8, LBB0_13
LBB0_2:
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [sp, #288]
	stp	q0, q0, [sp, #256]
	stp	q0, q0, [sp, #224]
	stp	q0, q0, [sp, #192]
	str	q0, [sp, #176]
Ltmp0:
	sub	x0, x29, #224
	add	x1, sp, #224
	add	x2, sp, #176
	bl	__Z18generate_syntheticRK6ParamsR10PopulationR9Locations
Ltmp1:
; %bb.3:
Ltmp2:
	sub	x0, x29, #224
	add	x1, sp, #224
	bl	__Z15seed_infectionsRK6ParamsR10Population
Ltmp3:
; %bb.4:
	ldp	x8, x9, [sp, #224]
	stp	x8, x9, [sp, #104]              ; 16-byte Folded Spill
	ldp	x8, x9, [sp, #176]
	stp	x8, x9, [sp, #120]              ; 16-byte Folded Spill
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [x25]
Ltmp5:
	add	x0, sp, #224
	str	x25, [sp, #96]                  ; 8-byte Folded Spill
	bl	__Z12count_statesRK10Population
Ltmp6:
; %bb.5:
	stp	x0, x1, [sp, #160]
	ldp	x8, x9, [x25, #8]
	stp	x25, x8, [x29, #-152]
	sub	x10, x29, #144
	add	x11, sp, #160
	stp	x10, x11, [x29, #-168]
	cmp	x8, x9
	b.hs	LBB0_14
; %bb.6:
	ldr	q0, [sp, #160]
	str	q0, [x8], #16
	ldp	x10, x9, [sp, #120]             ; 16-byte Folded Reload
	sub	x19, x9, x10
	str	x8, [x25, #8]
	cmp	x9, x10
	b.eq	LBB0_16
LBB0_7:
	lsr	x8, x19, #62
	cbnz	x8, LBB0_78
; %bb.8:
	lsl	x22, x19, #2
Ltmp10:
	mov	x0, x22
	bl	__Znwm
Ltmp11:
; %bb.9:
	mov	x20, x0
	mov	x1, x22
	bl	_bzero
	lsr	x8, x19, #61
	cbnz	x8, LBB0_79
; %bb.10:
	lsl	x23, x19, #3
Ltmp12:
	mov	x0, x23
	bl	__Znwm
Ltmp13:
; %bb.11:
	mov	x28, x0
	add	x21, x20, x22
	mov	x1, x23
	bl	_bzero
	b	LBB0_17
LBB0_12:
	mov	w8, #1                          ; =0x1
	sturh	w8, [x29, #-180]
	ldurh	w8, [x29, #-178]
	cbnz	w8, LBB0_2
LBB0_13:
	mov	w8, #1                          ; =0x1
	sturh	w8, [x29, #-178]
	b	LBB0_2
LBB0_14:
Ltmp7:
	sub	x0, x29, #168
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
Ltmp8:
; %bb.15:
	ldur	x8, [x29, #-144]
	ldp	x10, x9, [sp, #120]             ; 16-byte Folded Reload
	sub	x19, x9, x10
	str	x8, [x25, #8]
	cmp	x9, x10
	b.ne	LBB0_7
LBB0_16:
	mov	x20, #0                         ; =0x0
	mov	x21, #0                         ; =0x0
	mov	x28, #0                         ; =0x0
LBB0_17:
	ldp	x9, x8, [sp, #104]              ; 16-byte Folded Reload
	sub	x15, x8, x9
	ldr	x22, [sp, #224]
	ldr	x16, [sp, #272]
	ldr	x17, [sp, #296]
	cmp	x8, x9
	b.eq	LBB0_20
; %bb.18:
	mov	x8, x17
	mov	x9, x16
	mov	x10, x22
	mov	x11, x15
LBB0_19:                                ; =>This Inner Loop Header: Depth=1
	ldrb	w12, [x10], #1
	ldr	w13, [x9], #4
	ldr	w14, [x20, x13, lsl #2]
	cmp	w12, #2
	cinc	w12, w14, eq
	str	w12, [x20, x13, lsl #2]
	ldr	w12, [x8], #4
	ldr	w13, [x20, x12, lsl #2]
	cinc	w13, w13, eq
	str	w13, [x20, x12, lsl #2]
	subs	x11, x11, #1
	b.ne	LBB0_19
LBB0_20:
	stp	x17, x16, [sp, #72]             ; 16-byte Folded Spill
	str	x15, [sp, #88]                  ; 8-byte Folded Spill
	ldur	x24, [x29, #-208]
	ldurh	w8, [x29, #-180]
	cmp	w8, #1
	csinc	w26, w8, wzr, hi
	ldurh	w8, [x29, #-178]
	cmp	w8, #1
	csinc	w27, w8, wzr, hi
	ldr	x23, [sp, #248]
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	str	x0, [sp]                        ; 8-byte Folded Spill
	ldur	w8, [x29, #-212]
	cbz	w8, LBB0_61
; %bb.21:
	str	xzr, [sp, #144]                 ; 8-byte Folded Spill
	mov	x9, #58809                      ; =0xe5b9
	movk	x9, #7396, lsl #16
	movk	x9, #18285, lsl #32
	movk	x9, #48984, lsl #48
	mov	x8, #31765                      ; =0x7c15
	movk	x8, #32586, lsl #16
	movk	x8, #31161, lsl #32
	movk	x8, #40503, lsl #48
	mov	x10, #4587                      ; =0x11eb
	movk	x10, #4913, lsl #16
	movk	x10, #18875, lsl #32
	movk	x10, #38096, lsl #48
	add	x8, x24, x8
	eor	x8, x8, x8, lsr #30
	mul	x8, x8, x9
	eor	x8, x8, x8, lsr #27
	mul	x8, x8, x10
	sub	x21, x21, x20
	and	x9, x19, #0x7
	str	x9, [sp, #64]                   ; 8-byte Folded Spill
	ldp	x10, x9, [sp, #120]             ; 16-byte Folded Reload
	sub	x9, x10, x9
	str	x9, [sp, #48]                   ; 8-byte Folded Spill
	eor	x24, x8, x8, lsr #31
	and	x8, x19, #0xfffffffffffffff8
	neg	x8, x8
	str	x8, [sp, #152]                  ; 8-byte Folded Spill
	add	x9, x28, #32
	add	x8, x20, #16
	stp	x8, x9, [sp, #8]                ; 16-byte Folded Spill
Lloh0:
	adrp	x8, lCPI0_0@PAGE
Lloh1:
	ldr	d8, [x8, lCPI0_0@PAGEOFF]
	fmov	d9, #1.00000000
	str	x28, [sp, #136]                 ; 8-byte Folded Spill
	str	x21, [sp, #56]                  ; 8-byte Folded Spill
	str	x24, [sp, #40]                  ; 8-byte Folded Spill
LBB0_22:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_27 Depth 2
                                        ;     Child Loop BB0_46 Depth 2
                                        ;     Child Loop BB0_54 Depth 2
	ldp	x9, x8, [sp, #120]              ; 16-byte Folded Reload
	cmp	x8, x9
	b.eq	LBB0_48
; %bb.23:                               ;   in Loop: Header=BB0_22 Depth=1
	ldp	d11, d10, [x29, #-200]
	ldr	x10, [sp, #200]
	ldr	x11, [sp, #176]
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	cmn	x8, #8
	b.ls	LBB0_25
; %bb.24:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x8, #0                          ; =0x0
	ldr	x9, [sp, #64]                   ; 8-byte Folded Reload
	cbnz	x9, LBB0_44
	b	LBB0_48
LBB0_25:                                ;   in Loop: Header=BB0_22 Depth=1
	mov	x19, #0                         ; =0x0
	stp	x11, x10, [sp, #24]             ; 16-byte Folded Spill
	add	x21, x11, #3
	add	x28, x10, #16
	ldp	x24, x25, [sp, #8]              ; 16-byte Folded Reload
	b	LBB0_27
LBB0_26:                                ;   in Loop: Header=BB0_27 Depth=2
	sub	x19, x19, #8
	add	x21, x21, #8
	str	d12, [x25, #24]
	add	x25, x25, #64
	add	x24, x24, #32
	add	x28, x28, #32
	ldr	x8, [sp, #152]                  ; 8-byte Folded Reload
	cmp	x8, x19
	b.eq	LBB0_43
LBB0_27:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldur	w8, [x28, #-16]
	movi.2d	v12, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_29
; %bb.28:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x21, #-3]
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldur	s1, [x24, #-16]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d9, d0
LBB0_29:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d0, [x25, #-32]
	ldur	w8, [x28, #-12]
	cbz	w8, LBB0_31
; %bb.30:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x21, #-2]
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldur	s1, [x24, #-12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d12, d9, d0
LBB0_31:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d12, [x25, #-24]
	ldur	w8, [x28, #-8]
	movi.2d	v12, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_33
; %bb.32:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x21, #-1]
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldur	s1, [x24, #-8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d9, d0
LBB0_33:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d0, [x25, #-16]
	ldur	w8, [x28, #-4]
	cbz	w8, LBB0_35
; %bb.34:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x21]
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldur	s1, [x24, #-4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d12, d9, d0
LBB0_35:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d12, [x25, #-8]
	ldr	w8, [x28]
	movi.2d	v12, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_37
; %bb.36:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x21, #1]
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldr	s1, [x24]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d9, d0
LBB0_37:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d0, [x25]
	ldr	w8, [x28, #4]
	cbz	w8, LBB0_39
; %bb.38:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x21, #2]
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldr	s1, [x24, #4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d12, d9, d0
LBB0_39:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d12, [x25, #8]
	ldr	w8, [x28, #8]
	movi.2d	v12, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_41
; %bb.40:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x21, #3]
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldr	s1, [x24, #8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d9, d0
LBB0_41:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d0, [x25, #16]
	ldr	w8, [x28, #12]
	cbz	w8, LBB0_26
; %bb.42:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x21, #4]
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldr	s1, [x24, #12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d12, d9, d0
	b	LBB0_26
LBB0_43:                                ;   in Loop: Header=BB0_22 Depth=1
	neg	x8, x19
	ldp	x11, x10, [sp, #24]             ; 16-byte Folded Reload
	ldr	x9, [sp, #64]                   ; 8-byte Folded Reload
	cbz	x9, LBB0_48
LBB0_44:                                ;   in Loop: Header=BB0_22 Depth=1
	ldr	x9, [sp, #136]                  ; 8-byte Folded Reload
	add	x19, x9, x8, lsl #3
	lsl	x9, x8, #2
	add	x21, x20, x9
	add	x24, x11, x8
	add	x25, x10, x9
	ldr	x28, [sp, #64]                  ; 8-byte Folded Reload
	b	LBB0_46
LBB0_45:                                ;   in Loop: Header=BB0_46 Depth=2
	ldrb	w9, [x24], #1
	cmp	w9, #0
	fcsel	d0, d11, d10, eq
	ldr	s1, [x21], #4
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d9, d0
	str	d0, [x19], #8
	subs	x28, x28, #1
	b.eq	LBB0_48
LBB0_46:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	w8, [x25], #4
	cbnz	w8, LBB0_45
; %bb.47:                               ;   in Loop: Header=BB0_46 Depth=2
	movi.2d	v0, #0000000000000000
	str	d0, [x19], #8
	add	x21, x21, #4
	add	x24, x24, #1
	subs	x28, x28, #1
	b.ne	LBB0_46
LBB0_48:                                ;   in Loop: Header=BB0_22 Depth=1
	ldr	x21, [sp, #56]                  ; 8-byte Folded Reload
	cmp	x21, #1
	b.lt	LBB0_50
; %bb.49:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x0, x20
	mov	x1, x21
	bl	_bzero
LBB0_50:                                ;   in Loop: Header=BB0_22 Depth=1
	ldp	x9, x8, [sp, #104]              ; 16-byte Folded Reload
	cmp	x8, x9
	ldp	x2, x25, [sp, #88]              ; 16-byte Folded Reload
	ldp	x28, x19, [sp, #136]            ; 16-byte Folded Reload
	ldp	x4, x3, [sp, #72]               ; 16-byte Folded Reload
	mov	x5, #58809                      ; =0xe5b9
	movk	x5, #7396, lsl #16
	movk	x5, #18285, lsl #32
	movk	x5, #48984, lsl #48
	mov	x6, #31765                      ; =0x7c15
	movk	x6, #32586, lsl #16
	movk	x6, #31161, lsl #32
	movk	x6, #40503, lsl #48
	mov	x7, #4587                       ; =0x11eb
	movk	x7, #4913, lsl #16
	movk	x7, #18875, lsl #32
	movk	x7, #38096, lsl #48
	b.eq	LBB0_56
; %bb.51:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x8, #0                          ; =0x0
	mov	w9, #3                          ; =0x3
	bfi	x9, x19, #8, #55
	mov	w10, #4                         ; =0x4
	orr	x10, x10, x19, lsl #8
	movi.2d	v0, #0000000000000000
	ldr	x24, [sp, #40]                  ; 8-byte Folded Reload
	b	LBB0_54
LBB0_52:                                ;   in Loop: Header=BB0_54 Depth=2
	mov	w14, w8
	eor	x14, x14, x24
	add	x14, x14, x6
	eor	x14, x14, x14, lsr #30
	mul	x14, x14, x5
	eor	x14, x14, x14, lsr #27
	mul	x14, x14, x7
	eor	x14, x14, x14, lsr #31
	eor	x15, x14, x9
	add	x15, x15, x6
	eor	x15, x15, x15, lsr #30
	mul	x15, x15, x5
	eor	x15, x15, x15, lsr #27
	mul	x15, x15, x7
	lsr	x16, x15, #42
	eor	x15, x16, x15, lsr #11
	ucvtf	d1, x15, #53
	eor	x14, x14, x10
	add	x14, x14, x6
	eor	x14, x14, x14, lsr #30
	mul	x14, x14, x5
	eor	x14, x14, x14, lsr #27
	mul	x14, x14, x7
	lsr	x15, x14, #42
	eor	x14, x15, x14, lsr #11
	ucvtf	d2, x14, #53
	ldr	d3, [x28, x12, lsl #3]
	fcmp	d1, d3
	cset	w14, mi
	ldr	d1, [x28, x11, lsl #3]
	fcmp	d2, d1
	csinc	w14, w14, wzr, pl
LBB0_53:                                ;   in Loop: Header=BB0_54 Depth=2
	ldrh	w15, [x23, x8, lsl #1]
	subs	w16, w13, #1
	and	w16, w16, #0xff
	cset	w17, eq
	cmp	w16, #2
	cset	w0, lo
	sub	w1, w15, w0
	cmp	w16, #2
	csel	w15, w1, w15, lo
	tst	w1, #0xffff
	cset	w16, eq
	csel	w0, wzr, w0, ne
	orr	w0, w0, w14
	and	w0, w0, #0x1
	add	w13, w13, w0
	and	w0, w13, #0xff
	tst	w17, w16
	csel	w15, w27, w15, ne
	tst	w14, #0x1
	csel	w14, w26, w15, ne
	strb	w13, [x22, x8]
	strh	w14, [x23, x8, lsl #1]
	dup.4h	v1, w13
	bic.4h	v1, #1, lsl #8
	cmp	w0, #2
	cmeq.4h	v1, v1, v8
	ushll.4s	v1, v1, #0
	ldr	w13, [x20, x12, lsl #2]
	movi.4s	v2, #1
	and.16b	v1, v1, v2
	cinc	w13, w13, eq
	str	w13, [x20, x12, lsl #2]
	ldr	w12, [x20, x11, lsl #2]
	add.4s	v0, v0, v1
	cinc	w12, w12, eq
	str	w12, [x20, x11, lsl #2]
	add	x8, x8, #1
	cmp	x2, x8
	b.eq	LBB0_57
LBB0_54:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w13, [x22, x8]
	ldr	w12, [x3, x8, lsl #2]
	ldr	w11, [x4, x8, lsl #2]
	cbz	w13, LBB0_52
; %bb.55:                               ;   in Loop: Header=BB0_54 Depth=2
	mov	w14, #0                         ; =0x0
	b	LBB0_53
LBB0_56:                                ;   in Loop: Header=BB0_22 Depth=1
	movi.2d	v0, #0000000000000000
LBB0_57:                                ;   in Loop: Header=BB0_22 Depth=1
	str	q0, [sp, #160]
	ldp	x8, x9, [x25, #8]
	stp	x25, x8, [x29, #-152]
	sub	x10, x29, #144
	stur	x10, [x29, #-168]
	add	x10, sp, #160
	stur	x10, [x29, #-160]
	cmp	x8, x9
	b.hs	LBB0_59
; %bb.58:                               ;   in Loop: Header=BB0_22 Depth=1
	ldr	q0, [sp, #160]
	str	q0, [x8], #16
	str	x8, [x25, #8]
	add	x19, x19, #1
	ldur	w8, [x29, #-212]
	str	x19, [sp, #144]                 ; 8-byte Folded Spill
	cmp	x19, x8
	b.lo	LBB0_22
	b	LBB0_61
LBB0_59:                                ;   in Loop: Header=BB0_22 Depth=1
Ltmp20:
	sub	x0, x29, #168
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
Ltmp21:
; %bb.60:                               ;   in Loop: Header=BB0_22 Depth=1
	ldur	x8, [x29, #-144]
	str	x8, [x25, #8]
	add	x19, x19, #1
	ldur	w8, [x29, #-212]
	str	x19, [sp, #144]                 ; 8-byte Folded Spill
	cmp	x19, x8
	b.lo	LBB0_22
LBB0_61:
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	ldr	x8, [sp]                        ; 8-byte Folded Reload
	sub	x8, x0, x8
	scvtf	d0, x8
	mov	x8, #225833675390976            ; =0xcd6500000000
	movk	x8, #16845, lsl #48
	fmov	d1, x8
	fdiv	d0, d0, d1
	str	d0, [x25, #24]
	cbz	x28, LBB0_63
; %bb.62:
	mov	x0, x28
	bl	__ZdlPv
LBB0_63:
	cbz	x20, LBB0_65
; %bb.64:
	mov	x0, x20
	bl	__ZdlPv
LBB0_65:
	ldr	x0, [sp, #200]
	cbz	x0, LBB0_67
; %bb.66:
	str	x0, [sp, #208]
	bl	__ZdlPv
LBB0_67:
	ldr	x0, [sp, #176]
	cbz	x0, LBB0_69
; %bb.68:
	str	x0, [sp, #184]
	bl	__ZdlPv
LBB0_69:
	ldr	x0, [sp, #296]
	cbz	x0, LBB0_71
; %bb.70:
	str	x0, [sp, #304]
	bl	__ZdlPv
LBB0_71:
	ldr	x0, [sp, #272]
	cbz	x0, LBB0_73
; %bb.72:
	str	x0, [sp, #280]
	bl	__ZdlPv
LBB0_73:
	ldr	x0, [sp, #248]
	cbz	x0, LBB0_75
; %bb.74:
	str	x0, [sp, #256]
	bl	__ZdlPv
LBB0_75:
	ldr	x0, [sp, #224]
	cbz	x0, LBB0_77
; %bb.76:
	str	x0, [sp, #232]
	bl	__ZdlPv
LBB0_77:
	add	sp, sp, #416
	ldp	x29, x30, [sp, #128]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #112]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #96]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #80]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #64]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #48]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #32]               ; 16-byte Folded Reload
	ldp	d11, d10, [sp, #16]             ; 16-byte Folded Reload
	ldp	d13, d12, [sp], #144            ; 16-byte Folded Reload
	ret
LBB0_78:
Ltmp17:
	bl	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev
Ltmp18:
	b	LBB0_80
LBB0_79:
Ltmp14:
	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev
Ltmp15:
LBB0_80:
	brk	#0x1
LBB0_81:
Ltmp22:
	mov	x22, x0
	cbnz	x28, LBB0_85
; %bb.82:
	cbnz	x20, LBB0_88
LBB0_83:
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbnz	x0, LBB0_90
LBB0_84:
	add	x0, sp, #176
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #224
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
	bl	__Unwind_Resume
LBB0_85:
	ldr	x0, [sp, #136]                  ; 8-byte Folded Reload
	bl	__ZdlPv
	cbz	x20, LBB0_83
	b	LBB0_88
LBB0_86:
Ltmp9:
	mov	x22, x0
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_84
	b	LBB0_90
LBB0_87:
Ltmp16:
	mov	x22, x0
LBB0_88:
	mov	x0, x20
	bl	__ZdlPv
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_84
	b	LBB0_90
LBB0_89:
Ltmp19:
	mov	x22, x0
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_84
LBB0_90:
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	str	x0, [x8, #8]
	bl	__ZdlPv
	add	x0, sp, #176
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #224
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
	bl	__Unwind_Resume
LBB0_91:
Ltmp4:
	mov	x22, x0
	add	x0, sp, #176
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #224
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
	bl	__Unwind_Resume
	.loh AdrpLdr	Lloh0, Lloh1
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
	.uleb128 Ltmp0-Lfunc_begin0             ; >> Call Site 1 <<
	.uleb128 Ltmp3-Ltmp0                    ;   Call between Ltmp0 and Ltmp3
	.uleb128 Ltmp4-Lfunc_begin0             ;     jumps to Ltmp4
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp5-Lfunc_begin0             ; >> Call Site 2 <<
	.uleb128 Ltmp6-Ltmp5                    ;   Call between Ltmp5 and Ltmp6
	.uleb128 Ltmp9-Lfunc_begin0             ;     jumps to Ltmp9
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp10-Lfunc_begin0            ; >> Call Site 3 <<
	.uleb128 Ltmp11-Ltmp10                  ;   Call between Ltmp10 and Ltmp11
	.uleb128 Ltmp19-Lfunc_begin0            ;     jumps to Ltmp19
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp11-Lfunc_begin0            ; >> Call Site 4 <<
	.uleb128 Ltmp12-Ltmp11                  ;   Call between Ltmp11 and Ltmp12
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp12-Lfunc_begin0            ; >> Call Site 5 <<
	.uleb128 Ltmp13-Ltmp12                  ;   Call between Ltmp12 and Ltmp13
	.uleb128 Ltmp16-Lfunc_begin0            ;     jumps to Ltmp16
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp13-Lfunc_begin0            ; >> Call Site 6 <<
	.uleb128 Ltmp7-Ltmp13                   ;   Call between Ltmp13 and Ltmp7
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp7-Lfunc_begin0             ; >> Call Site 7 <<
	.uleb128 Ltmp8-Ltmp7                    ;   Call between Ltmp7 and Ltmp8
	.uleb128 Ltmp9-Lfunc_begin0             ;     jumps to Ltmp9
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp8-Lfunc_begin0             ; >> Call Site 8 <<
	.uleb128 Ltmp20-Ltmp8                   ;   Call between Ltmp8 and Ltmp20
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp20-Lfunc_begin0            ; >> Call Site 9 <<
	.uleb128 Ltmp21-Ltmp20                  ;   Call between Ltmp20 and Ltmp21
	.uleb128 Ltmp22-Lfunc_begin0            ;     jumps to Ltmp22
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp17-Lfunc_begin0            ; >> Call Site 10 <<
	.uleb128 Ltmp18-Ltmp17                  ;   Call between Ltmp17 and Ltmp18
	.uleb128 Ltmp19-Lfunc_begin0            ;     jumps to Ltmp19
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp14-Lfunc_begin0            ; >> Call Site 11 <<
	.uleb128 Ltmp15-Ltmp14                  ;   Call between Ltmp14 and Ltmp15
	.uleb128 Ltmp16-Lfunc_begin0            ;     jumps to Ltmp16
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp15-Lfunc_begin0            ; >> Call Site 12 <<
	.uleb128 Lfunc_end0-Ltmp15              ;   Call between Ltmp15 and Lfunc_end0
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
Lcst_end0:
	.p2align	2, 0x0
                                        ; -- End function
	.section	__TEXT,__text,regular,pure_instructions
	.globl	__ZN9LocationsD1Ev              ; -- Begin function _ZN9LocationsD1Ev
	.weak_def_can_be_hidden	__ZN9LocationsD1Ev
	.p2align	2
__ZN9LocationsD1Ev:                     ; @_ZN9LocationsD1Ev
	.cfi_startproc
; %bb.0:
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	mov	x19, x0
	ldr	x0, [x0, #24]
	cbz	x0, LBB1_2
; %bb.1:
	str	x0, [x19, #32]
	bl	__ZdlPv
LBB1_2:
	ldr	x0, [x19]
	cbz	x0, LBB1_4
; %bb.3:
	str	x0, [x19, #8]
	bl	__ZdlPv
LBB1_4:
	mov	x0, x19
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	__ZN10PopulationD1Ev            ; -- Begin function _ZN10PopulationD1Ev
	.weak_def_can_be_hidden	__ZN10PopulationD1Ev
	.p2align	2
__ZN10PopulationD1Ev:                   ; @_ZN10PopulationD1Ev
	.cfi_startproc
; %bb.0:
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	mov	x19, x0
	ldr	x0, [x0, #72]
	cbz	x0, LBB2_2
; %bb.1:
	str	x0, [x19, #80]
	bl	__ZdlPv
LBB2_2:
	ldr	x0, [x19, #48]
	cbz	x0, LBB2_4
; %bb.3:
	str	x0, [x19, #56]
	bl	__ZdlPv
LBB2_4:
	ldr	x0, [x19, #24]
	cbz	x0, LBB2_6
; %bb.5:
	str	x0, [x19, #32]
	bl	__ZdlPv
LBB2_6:
	ldr	x0, [x19]
	cbz	x0, LBB2_8
; %bb.7:
	str	x0, [x19, #8]
	bl	__ZdlPv
LBB2_8:
	mov	x0, x19
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv ; -- Begin function _ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
	.weak_def_can_be_hidden	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
	.p2align	2
__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv: ; @_ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
	.cfi_startproc
; %bb.0:
	stp	x26, x25, [sp, #-80]!           ; 16-byte Folded Spill
	stp	x24, x23, [sp, #16]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #32]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #48]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
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
	ldr	x23, [x0, #16]
	ldp	x20, x8, [x23]
	sub	x21, x8, x20
	asr	x24, x21, #4
	add	x8, x24, #1
	lsr	x9, x8, #60
	cbnz	x9, LBB3_5
; %bb.1:
	ldr	x9, [x23, #16]
	mov	x10, #9223372036854775792       ; =0x7ffffffffffffff0
	sub	x9, x9, x20
	asr	x11, x9, #3
	cmp	x11, x8
	csel	x8, x11, x8, hi
	cmp	x9, x10
	mov	x9, #1152921504606846975        ; =0xfffffffffffffff
	csel	x8, x8, x9, lo
	lsr	x9, x8, #60
	cbnz	x9, LBB3_6
; %bb.2:
	mov	x19, x0
	ldr	x25, [x0, #8]
	lsl	x22, x8, #4
	mov	x0, x22
	bl	__Znwm
	add	x8, x0, x21
	add	x26, x0, x22
	ldr	q0, [x25]
	str	q0, [x8]
	add	x25, x8, #16
	sub	x22, x8, x24, lsl #4
	mov	x0, x22
	mov	x1, x20
	mov	x2, x21
	bl	_memcpy
	stp	x22, x25, [x23]
	str	x26, [x23, #16]
	cbz	x20, LBB3_4
; %bb.3:
	mov	x0, x20
	bl	__ZdlPv
LBB3_4:
	ldr	x8, [x19]
	str	x25, [x8]
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp], #80             ; 16-byte Folded Reload
	ret
LBB3_5:
	bl	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe220106Ev
LBB3_6:
	bl	__ZSt28__throw_bad_array_new_lengthB9nqe220106v
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe220106Ev ; -- Begin function _ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe220106Ev
	.globl	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe220106Ev
	.weak_def_can_be_hidden	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe220106Ev
	.p2align	2
__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe220106Ev: ; @_ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe220106Ev
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh2:
	adrp	x0, l_.str@PAGE
Lloh3:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh2, Lloh3
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
Ltmp23:
	mov	x1, x20
	bl	__ZNSt12length_errorC1B9nqe220106EPKc
Ltmp24:
; %bb.1:
Lloh4:
	adrp	x1, __ZTISt12length_error@GOTPAGE
Lloh5:
	ldr	x1, [x1, __ZTISt12length_error@GOTPAGEOFF]
Lloh6:
	adrp	x2, __ZNSt12length_errorD1Ev@GOTPAGE
Lloh7:
	ldr	x2, [x2, __ZNSt12length_errorD1Ev@GOTPAGEOFF]
	mov	x0, x19
	bl	___cxa_throw
LBB5_2:
Ltmp25:
	mov	x20, x0
	mov	x0, x19
	bl	___cxa_free_exception
	mov	x0, x20
	bl	__Unwind_Resume
	.loh AdrpLdrGot	Lloh6, Lloh7
	.loh AdrpLdrGot	Lloh4, Lloh5
Lfunc_end1:
	.cfi_endproc
	.section	__TEXT,__gcc_except_tab
	.p2align	2, 0x0
GCC_except_table5:
Lexception1:
	.byte	255                             ; @LPStart Encoding = omit
	.byte	255                             ; @TType Encoding = omit
	.byte	1                               ; Call site Encoding = uleb128
	.uleb128 Lcst_end1-Lcst_begin1
Lcst_begin1:
	.uleb128 Lfunc_begin1-Lfunc_begin1      ; >> Call Site 1 <<
	.uleb128 Ltmp23-Lfunc_begin1            ;   Call between Lfunc_begin1 and Ltmp23
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp23-Lfunc_begin1            ; >> Call Site 2 <<
	.uleb128 Ltmp24-Ltmp23                  ;   Call between Ltmp23 and Ltmp24
	.uleb128 Ltmp25-Lfunc_begin1            ;     jumps to Ltmp25
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp24-Lfunc_begin1            ; >> Call Site 3 <<
	.uleb128 Lfunc_end1-Ltmp24              ;   Call between Ltmp24 and Lfunc_end1
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
Lloh8:
	adrp	x8, __ZTVSt12length_error@GOTPAGE
Lloh9:
	ldr	x8, [x8, __ZTVSt12length_error@GOTPAGEOFF]
	add	x8, x8, #16
	str	x8, [x0]
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.loh AdrpLdrGot	Lloh8, Lloh9
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZSt28__throw_bad_array_new_lengthB9nqe220106v ; -- Begin function _ZSt28__throw_bad_array_new_lengthB9nqe220106v
	.globl	__ZSt28__throw_bad_array_new_lengthB9nqe220106v
	.weak_def_can_be_hidden	__ZSt28__throw_bad_array_new_lengthB9nqe220106v
	.p2align	2
__ZSt28__throw_bad_array_new_lengthB9nqe220106v: ; @_ZSt28__throw_bad_array_new_lengthB9nqe220106v
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	mov	w0, #8                          ; =0x8
	bl	___cxa_allocate_exception
	bl	__ZNSt20bad_array_new_lengthC1Ev
Lloh10:
	adrp	x1, __ZTISt20bad_array_new_length@GOTPAGE
Lloh11:
	ldr	x1, [x1, __ZTISt20bad_array_new_length@GOTPAGEOFF]
Lloh12:
	adrp	x2, __ZNSt20bad_array_new_lengthD1Ev@GOTPAGE
Lloh13:
	ldr	x2, [x2, __ZNSt20bad_array_new_lengthD1Ev@GOTPAGEOFF]
	bl	___cxa_throw
	.loh AdrpLdrGot	Lloh12, Lloh13
	.loh AdrpLdrGot	Lloh10, Lloh11
	.cfi_endproc
                                        ; -- End function
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
Lloh14:
	adrp	x0, l_.str@PAGE
Lloh15:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh14, Lloh15
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev ; -- Begin function _ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev
	.globl	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev
	.weak_def_can_be_hidden	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev
	.p2align	2
__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev: ; @_ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh16:
	adrp	x0, l_.str@PAGE
Lloh17:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh16, Lloh17
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"vector"

.subsections_via_symbols
