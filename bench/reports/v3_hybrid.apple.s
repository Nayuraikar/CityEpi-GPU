	.build_version macos, 26, 0	sdk_version 27, 0
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ; -- Begin function _Z24run_simulation_v3_hybridRK6Paramsb
lCPI0_0:
	.byte	1                               ; 0x1
	.byte	2                               ; 0x2
	.byte	4                               ; 0x4
	.byte	8                               ; 0x8
	.byte	16                              ; 0x10
	.byte	32                              ; 0x20
	.byte	64                              ; 0x40
	.byte	128                             ; 0x80
	.byte	1                               ; 0x1
	.byte	2                               ; 0x2
	.byte	4                               ; 0x4
	.byte	8                               ; 0x8
	.byte	16                              ; 0x10
	.byte	32                              ; 0x20
	.byte	64                              ; 0x40
	.byte	128                             ; 0x80
	.section	__TEXT,__text,regular,pure_instructions
	.globl	__Z24run_simulation_v3_hybridRK6Paramsb
	.p2align	2
__Z24run_simulation_v3_hybridRK6Paramsb: ; @_Z24run_simulation_v3_hybridRK6Paramsb
Lfunc_begin0:
	.cfi_startproc
	.cfi_personality 155, ___gxx_personality_v0
	.cfi_lsda 16, Lexception0
; %bb.0:
	stp	d11, d10, [sp, #-128]!          ; 16-byte Folded Spill
	stp	d9, d8, [sp, #16]               ; 16-byte Folded Spill
	stp	x28, x27, [sp, #32]             ; 16-byte Folded Spill
	stp	x26, x25, [sp, #48]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #64]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #80]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #96]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #112]            ; 16-byte Folded Spill
	add	x29, sp, #112
	sub	sp, sp, #512
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
	mov	x26, x1
	mov	x27, x8
Lloh0:
	adrp	x8, ___stack_chk_guard@GOTPAGE
Lloh1:
	ldr	x8, [x8, ___stack_chk_guard@GOTPAGEOFF]
Lloh2:
	ldr	x8, [x8]
	stur	x8, [x29, #-128]
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
	stp	q0, q0, [sp, #368]
	stp	q0, q0, [sp, #336]
	stp	q0, q0, [sp, #304]
	stp	q0, q0, [sp, #272]
	str	q0, [sp, #256]
Ltmp0:
	sub	x0, x29, #224
	add	x1, sp, #304
	add	x2, sp, #256
	bl	__Z18generate_syntheticRK6ParamsR10PopulationR9Locations
Ltmp1:
; %bb.3:
Ltmp2:
	sub	x0, x29, #224
	add	x1, sp, #304
	bl	__Z15seed_infectionsRK6ParamsR10Population
Ltmp3:
; %bb.4:
	ldp	x25, x19, [sp, #304]
	ldp	x8, x9, [sp, #256]
	stp	x8, x9, [sp, #144]              ; 16-byte Folded Spill
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [x27]
Ltmp5:
	add	x0, sp, #304
	str	x27, [sp, #112]                 ; 8-byte Folded Spill
	bl	__Z12count_statesRK10Population
Ltmp6:
; %bb.5:
	stp	x0, x1, [sp, #224]
	ldp	x8, x9, [x27, #8]
	str	x8, [sp, #208]
	add	x10, sp, #208
	add	x11, sp, #224
	stp	x10, x11, [x29, #-160]
	stur	x27, [x29, #-144]
	cmp	x8, x9
	b.hs	LBB0_14
; %bb.6:
	ldr	q0, [sp, #224]
	str	q0, [x8], #16
	ldp	x10, x9, [sp, #144]             ; 16-byte Folded Reload
	sub	x24, x9, x10
	str	x8, [x27, #8]
	cmp	x9, x10
	b.eq	LBB0_16
LBB0_7:
	lsr	x8, x24, #62
	cbnz	x8, LBB0_87
; %bb.8:
	lsl	x22, x24, #2
Ltmp10:
	mov	x0, x22
	bl	__Znwm
Ltmp11:
; %bb.9:
	mov	x20, x0
	mov	x1, x22
	bl	_bzero
	lsr	x8, x24, #61
	cbnz	x8, LBB0_88
; %bb.10:
	lsl	x23, x24, #3
Ltmp12:
	mov	x0, x23
	bl	__Znwm
Ltmp13:
; %bb.11:
	mov	x21, x0
	add	x22, x20, x22
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
	sub	x0, x29, #160
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
Ltmp8:
; %bb.15:
	ldr	x8, [sp, #208]
	ldp	x10, x9, [sp, #144]             ; 16-byte Folded Reload
	sub	x24, x9, x10
	str	x8, [x27, #8]
	cmp	x9, x10
	b.ne	LBB0_7
LBB0_16:
	mov	x20, #0                         ; =0x0
	mov	x22, #0                         ; =0x0
	mov	x21, #0                         ; =0x0
LBB0_17:
	sub	x28, x19, x25
	ldr	x9, [sp, #304]
	ldr	x8, [sp, #352]
	stp	x8, x9, [sp, #128]              ; 16-byte Folded Spill
	ldr	x8, [sp, #376]
	str	x8, [sp, #120]                  ; 8-byte Folded Spill
	cmp	x19, x25
	b.eq	LBB0_20
; %bb.18:
	ldp	x8, x9, [sp, #120]              ; 16-byte Folded Reload
	ldr	x10, [sp, #136]                 ; 8-byte Folded Reload
	mov	x11, x28
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
	ldr	x8, [sp, #328]
	str	x8, [sp, #104]                  ; 8-byte Folded Spill
	ldur	x25, [x29, #-208]
	ldurh	w8, [x29, #-180]
	cmp	w8, #1
	csinc	w8, w8, wzr, hi
	strh	w8, [sp, #224]
	ldurh	w8, [x29, #-178]
	cmp	w8, #1
	csinc	w8, w8, wzr, hi
	strh	w8, [sp, #226]
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	str	x0, [sp, #8]                    ; 8-byte Folded Spill
	ldur	w8, [x29, #-212]
	cbz	w8, LBB0_68
; %bb.21:
	str	xzr, [sp, #160]                 ; 8-byte Folded Spill
	mov	x23, #58809                     ; =0xe5b9
	movk	x23, #7396, lsl #16
	movk	x23, #18285, lsl #32
	movk	x23, #48984, lsl #48
	mov	x19, #31765                     ; =0x7c15
	movk	x19, #32586, lsl #16
	movk	x19, #31161, lsl #32
	movk	x19, #40503, lsl #48
	mov	x9, x26
	mov	x26, #4587                      ; =0x11eb
	movk	x26, #4913, lsl #16
	movk	x26, #18875, lsl #32
	movk	x26, #38096, lsl #48
	add	x8, x25, x19
	eor	x8, x8, x8, lsr #30
	mul	x8, x8, x23
	eor	x8, x8, x8, lsr #27
	mul	x8, x8, x26
	eor	x25, x8, x8, lsr #31
	sub	x8, x22, x20
	str	x8, [sp, #72]                   ; 8-byte Folded Spill
	cmp	x28, #15
	csel	w8, wzr, w9, ls
	str	w8, [sp, #68]                   ; 4-byte Folded Spill
	and	x8, x24, #0x7
	str	x8, [sp, #96]                   ; 8-byte Folded Spill
	ldp	x9, x8, [sp, #144]              ; 16-byte Folded Reload
	sub	x8, x9, x8
	str	x8, [sp, #48]                   ; 8-byte Folded Spill
	add	x8, sp, #224
	orr	x8, x8, #0x4
	str	x8, [sp, #56]                   ; 8-byte Folded Spill
	ldrh	w8, [sp, #226]
	str	w8, [sp, #188]                  ; 4-byte Folded Spill
	ldrh	w8, [sp, #224]
	str	w8, [sp, #172]                  ; 4-byte Folded Spill
	and	x8, x24, #0xfffffffffffffff8
	neg	x8, x8
	str	x8, [sp, #176]                  ; 8-byte Folded Spill
	add	x9, x21, #32
	add	x8, x20, #16
	stp	x8, x9, [sp, #16]               ; 16-byte Folded Spill
Lloh3:
	adrp	x8, lCPI0_0@PAGE
Lloh4:
	ldr	q0, [x8, lCPI0_0@PAGEOFF]
	str	q0, [sp, #192]                  ; 16-byte Folded Spill
	fmov	d8, #1.00000000
	stp	x28, x25, [sp, #80]             ; 16-byte Folded Spill
LBB0_22:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_27 Depth 2
                                        ;     Child Loop BB0_46 Depth 2
                                        ;     Child Loop BB0_53 Depth 2
                                        ;       Child Loop BB0_55 Depth 3
                                        ;     Child Loop BB0_62 Depth 2
	ldp	x9, x8, [sp, #144]              ; 16-byte Folded Reload
	cmp	x8, x9
	b.eq	LBB0_48
; %bb.23:                               ;   in Loop: Header=BB0_22 Depth=1
	ldp	d10, d9, [x29, #-200]
	ldr	x10, [sp, #280]
	ldr	x11, [sp, #256]
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	cmn	x8, #8
	b.ls	LBB0_25
; %bb.24:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x8, #0                          ; =0x0
	ldr	x9, [sp, #96]                   ; 8-byte Folded Reload
	cbnz	x9, LBB0_44
	b	LBB0_48
LBB0_25:                                ;   in Loop: Header=BB0_22 Depth=1
	mov	x28, #0                         ; =0x0
	stp	x11, x10, [sp, #32]             ; 16-byte Folded Spill
	add	x27, x11, #3
	add	x22, x10, #16
	ldp	x24, x25, [sp, #16]             ; 16-byte Folded Reload
	b	LBB0_27
LBB0_26:                                ;   in Loop: Header=BB0_27 Depth=2
	sub	x28, x28, #8
	add	x27, x27, #8
	str	d11, [x25, #24]
	add	x25, x25, #64
	add	x24, x24, #32
	add	x22, x22, #32
	ldr	x8, [sp, #176]                  ; 8-byte Folded Reload
	cmp	x8, x28
	b.eq	LBB0_43
LBB0_27:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldur	w8, [x22, #-16]
	movi.2d	v11, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_29
; %bb.28:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x27, #-3]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x24, #-16]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
LBB0_29:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d0, [x25, #-32]
	ldur	w8, [x22, #-12]
	cbz	w8, LBB0_31
; %bb.30:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x27, #-2]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x24, #-12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d11, d8, d0
LBB0_31:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d11, [x25, #-24]
	ldur	w8, [x22, #-8]
	movi.2d	v11, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_33
; %bb.32:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x27, #-1]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x24, #-8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
LBB0_33:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d0, [x25, #-16]
	ldur	w8, [x22, #-4]
	cbz	w8, LBB0_35
; %bb.34:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x24, #-4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d11, d8, d0
LBB0_35:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d11, [x25, #-8]
	ldr	w8, [x22]
	movi.2d	v11, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_37
; %bb.36:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27, #1]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x24]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
LBB0_37:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d0, [x25]
	ldr	w8, [x22, #4]
	cbz	w8, LBB0_39
; %bb.38:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27, #2]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x24, #4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d11, d8, d0
LBB0_39:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d11, [x25, #8]
	ldr	w8, [x22, #8]
	movi.2d	v11, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_41
; %bb.40:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27, #3]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x24, #8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
LBB0_41:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d0, [x25, #16]
	ldr	w8, [x22, #12]
	cbz	w8, LBB0_26
; %bb.42:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27, #4]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x24, #12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d11, d8, d0
	b	LBB0_26
LBB0_43:                                ;   in Loop: Header=BB0_22 Depth=1
	neg	x8, x28
	ldp	x11, x10, [sp, #32]             ; 16-byte Folded Reload
	ldr	x9, [sp, #96]                   ; 8-byte Folded Reload
	cbz	x9, LBB0_48
LBB0_44:                                ;   in Loop: Header=BB0_22 Depth=1
	add	x22, x21, x8, lsl #3
	lsl	x9, x8, #2
	add	x24, x20, x9
	add	x25, x11, x8
	add	x27, x10, x9
	ldr	x28, [sp, #96]                  ; 8-byte Folded Reload
	b	LBB0_46
LBB0_45:                                ;   in Loop: Header=BB0_46 Depth=2
	ldrb	w9, [x25], #1
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x24], #4
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
	str	d0, [x22], #8
	subs	x28, x28, #1
	b.eq	LBB0_48
LBB0_46:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	w8, [x27], #4
	cbnz	w8, LBB0_45
; %bb.47:                               ;   in Loop: Header=BB0_46 Depth=2
	movi.2d	v0, #0000000000000000
	str	d0, [x22], #8
	add	x24, x24, #4
	add	x25, x25, #1
	subs	x28, x28, #1
	b.ne	LBB0_46
LBB0_48:                                ;   in Loop: Header=BB0_22 Depth=1
	ldr	x1, [sp, #72]                   ; 8-byte Folded Reload
	cmp	x1, #1
	b.lt	LBB0_50
; %bb.49:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x0, x20
	bl	_bzero
LBB0_50:                                ;   in Loop: Header=BB0_22 Depth=1
	ldr	x8, [sp, #56]                   ; 8-byte Folded Reload
	stp	xzr, xzr, [x8]
	ldr	x28, [sp, #80]                  ; 8-byte Folded Reload
	ldp	x6, x5, [sp, #128]              ; 16-byte Folded Reload
	ldr	x7, [sp, #120]                  ; 8-byte Folded Reload
	ldr	x22, [sp, #104]                 ; 8-byte Folded Reload
	ldr	x24, [sp, #160]                 ; 8-byte Folded Reload
	ldr	w8, [sp, #68]                   ; 4-byte Folded Reload
	cbz	w8, LBB0_57
; %bb.51:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x14, #0                         ; =0x0
	mov	w9, #3                          ; =0x3
	bfi	x9, x24, #8, #55
	mov	x10, x5
	mov	x11, x6
	mov	x12, x7
	mov	w16, #16                        ; =0x10
	mov	w8, #4                          ; =0x4
	orr	x13, x8, x24, lsl #8
	ldr	x27, [sp, #112]                 ; 8-byte Folded Reload
	ldr	x25, [sp, #88]                  ; 8-byte Folded Reload
	b	LBB0_53
LBB0_52:                                ;   in Loop: Header=BB0_53 Depth=2
	ldr	q1, [x5, x14]
	ldur	q0, [x29, #-160]
	movi.16b	v25, #1
	cmeq.16b	v0, v0, v25
	cmeq.16b	v2, v1, #0
	cmeq.16b	v3, v1, v25
	movi.16b	v26, #2
	cmeq.16b	v4, v1, v26
	movi.2d	v5, #0xffffffffffffffff
	add.16b	v5, v1, v5
	cmhi.16b	v5, v26, v5
	ushll2.8h	v6, v5, #0
	shl.8h	v6, v6, #15
	cmlt.8h	v6, v6, #0
	ushll.8h	v7, v5, #0
	shl.8h	v7, v7, #15
	cmlt.8h	v7, v7, #0
	add	x15, x22, x14, lsl #1
	ldp	q16, q17, [x15]
	saddw.8h	v18, v16, v5
	saddw2.8h	v5, v17, v5
	cmeq.8h	v19, v5, #0
	cmeq.8h	v20, v18, #0
	uzp1.16b	v21, v20, v19
	xtn.8b	v19, v19
	xtn.8b	v20, v20
	and.16b	v22, v3, v21
	and.16b	v4, v4, v21
	and.16b	v0, v2, v0
	ushll2.8h	v2, v0, #0
	shl.8h	v2, v2, #15
	cmlt.8h	v2, v2, #0
	ushll.8h	v21, v0, #0
	shl.8h	v21, v21, #15
	cmlt.8h	v21, v21, #0
	orr.16b	v0, v4, v0
	orr.16b	v4, v0, v22
	sub.16b	v0, v1, v4
	add	x0, sp, #224
	ld1r.8h	{ v22 }, [x0]
	ldur	q23, [sp, #226]
	dup.8h	v24, v23[0]
	str	q0, [x5, x14]
	and.8b	v20, v3, v20
	bsl.16b	v7, v18, v16
	sshll.8h	v16, v20, #0
	bit.16b	v7, v24, v16
	bit.16b	v7, v22, v21
	ext.16b	v3, v3, v3, #8
	and.8b	v3, v3, v19
	bif.16b	v5, v17, v6
	sshll.8h	v3, v3, #0
	bsl.16b	v3, v24, v5
	bsl.16b	v2, v22, v3
	stp	q7, q2, [x15]
	cmeq.16b	v1, v1, v4
	ldr	q5, [sp, #192]                  ; 16-byte Folded Reload
	and.16b	v1, v1, v5
	ext.16b	v2, v1, v1, #8
	zip1.16b	v1, v1, v2
	addv.8h	h1, v1
	mov.d	x15, v23[1]
	fmov	x16, d23
	cmeq.16b	v2, v0, v25
	and.16b	v2, v2, v5
	ext.16b	v3, v2, v2, #8
	zip1.16b	v2, v2, v3
	addv.8h	h2, v2
	cmeq.16b	v3, v0, v26
	and.16b	v3, v3, v5
	ext.16b	v4, v3, v3, #8
	zip1.16b	v3, v3, v4
	addv.8h	h3, v3
	lsr	x17, x15, #16
	movi.16b	v4, #3
	cmeq.16b	v4, v0, v4
	and.16b	v4, v4, v5
	ext.16b	v5, v4, v4, #8
	zip1.16b	v4, v4, v5
	addv.8h	h4, v4
	add	x0, x0, #16
	extr	x15, x15, x16, #48
	fmov	d5, x15
	lsr	x15, x16, #16
	fmov	d6, x15
	zip1.2s	v5, v6, v5
	mov.h	v1[1], v2[0]
	mov.h	v1[2], v3[0]
	mov.h	v1[3], v4[0]
	cnt.8b	v1, v1
	fmov	s2, w17
	ld1.s	{ v2 }[1], [x0]
	mov.d	v5[1], v2[0]
	uaddlp.4h	v1, v1
	uaddw.4s	v1, v5, v1
	stur	q1, [sp, #228]
	umov.b	w15, v0[0]
	lsl	x14, x14, #2
	ldr	w16, [x6, x14]
	ldr	w17, [x20, x16, lsl #2]
	cmp	w15, #2
	cinc	w15, w17, eq
	str	w15, [x20, x16, lsl #2]
	ldr	w15, [x7, x14]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[1]
	orr	x16, x14, #0x4
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[2]
	orr	x16, x14, #0x8
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[3]
	orr	x16, x14, #0xc
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[4]
	orr	x16, x14, #0x10
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[5]
	mov	w16, #20                        ; =0x14
	orr	x16, x14, x16
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[6]
	orr	x16, x14, #0x18
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[7]
	orr	x16, x14, #0x1c
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[8]
	orr	x16, x14, #0x20
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[9]
	mov	w16, #36                        ; =0x24
	orr	x16, x14, x16
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[10]
	mov	w16, #40                        ; =0x28
	orr	x16, x14, x16
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[11]
	mov	w16, #44                        ; =0x2c
	orr	x16, x14, x16
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[12]
	orr	x16, x14, #0x30
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[13]
	mov	w16, #52                        ; =0x34
	orr	x16, x14, x16
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[14]
	orr	x16, x14, #0x38
	ldr	w17, [x6, x16]
	ldr	w0, [x20, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x20, x17, lsl #2]
	ldr	w15, [x7, x16]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	umov.b	w15, v0[15]
	orr	x14, x14, #0x3c
	ldr	w16, [x6, x14]
	ldr	w17, [x20, x16, lsl #2]
	cmp	w15, #2
	cinc	w15, w17, eq
	str	w15, [x20, x16, lsl #2]
	ldr	w14, [x7, x14]
	ldr	w15, [x20, x14, lsl #2]
	cinc	w15, w15, eq
	str	w15, [x20, x14, lsl #2]
	add	x16, x8, #16
	add	x12, x12, #64
	add	x11, x11, #64
	add	x10, x10, #16
	mov	x14, x8
	cmp	x16, x28
	b.hi	LBB0_58
LBB0_53:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_55 Depth 3
	mov	x15, #0                         ; =0x0
	mov	x8, x16
	mov	w16, w14
	b	LBB0_55
LBB0_54:                                ;   in Loop: Header=BB0_55 Depth=3
	add	x17, x16, x15
	eor	x17, x17, x25
	add	x17, x17, x19
	eor	x17, x17, x17, lsr #30
	mul	x17, x17, x23
	eor	x17, x17, x17, lsr #27
	mul	x17, x17, x26
	eor	x17, x17, x17, lsr #31
	eor	x0, x17, x9
	add	x0, x0, x19
	eor	x0, x0, x0, lsr #30
	mul	x0, x0, x23
	eor	x0, x0, x0, lsr #27
	mul	x0, x0, x26
	lsr	x1, x0, #42
	eor	x0, x1, x0, lsr #11
	ucvtf	d0, x0, #53
	eor	x17, x17, x13
	add	x17, x17, x19
	eor	x17, x17, x17, lsr #30
	mul	x17, x17, x23
	eor	x17, x17, x17, lsr #27
	mul	x17, x17, x26
	lsr	x0, x17, #42
	eor	x17, x0, x17, lsr #11
	ucvtf	d1, x17, #53
	ldr	w17, [x11, x15, lsl #2]
	ldr	d2, [x21, x17, lsl #3]
	fcmp	d0, d2
	cset	w17, mi
	ldr	w0, [x12, x15, lsl #2]
	ldr	d0, [x21, x0, lsl #3]
	fcmp	d1, d0
	csinc	w17, w17, wzr, pl
	sub	x0, x29, #160
	strb	w17, [x0, x15]
	add	x15, x15, #1
	cmp	x15, #16
	b.eq	LBB0_52
LBB0_55:                                ;   Parent Loop BB0_22 Depth=1
                                        ;     Parent Loop BB0_53 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldrb	w17, [x10, x15]
	cbz	w17, LBB0_54
; %bb.56:                               ;   in Loop: Header=BB0_55 Depth=3
	mov	w17, #0                         ; =0x0
	sub	x0, x29, #160
	strb	w17, [x0, x15]
	add	x15, x15, #1
	cmp	x15, #16
	b.ne	LBB0_55
	b	LBB0_52
LBB0_57:                                ;   in Loop: Header=BB0_22 Depth=1
	mov	w9, #0                          ; =0x0
	mov	w10, #0                         ; =0x0
	mov	w11, #0                         ; =0x0
	mov	w12, #0                         ; =0x0
	mov	x8, #0                          ; =0x0
	ldr	x27, [sp, #112]                 ; 8-byte Folded Reload
	ldr	x25, [sp, #88]                  ; 8-byte Folded Reload
	cmp	x8, x28
	b.lo	LBB0_59
	b	LBB0_64
LBB0_58:                                ;   in Loop: Header=BB0_22 Depth=1
	ldp	w12, w11, [sp, #228]
	ldp	w10, w9, [sp, #236]
	cmp	x8, x28
	b.hs	LBB0_64
LBB0_59:                                ;   in Loop: Header=BB0_22 Depth=1
	mov	w13, #3                         ; =0x3
	bfi	x13, x24, #8, #55
	mov	w14, #4                         ; =0x4
	orr	x14, x14, x24, lsl #8
	b	LBB0_62
LBB0_60:                                ;   in Loop: Header=BB0_62 Depth=2
	and	w0, w17, #0xff
	cmp	w0, #3
	cset	w2, lo
	sub	w3, w1, w2
	tst	w3, #0xffff
	cset	w4, eq
	cmp	w0, #3
	csel	w1, w3, w1, lo
	cmp	w0, #1
	and	w0, w3, #0xffff
	ccmp	w0, #0, #0, eq
	mov	w0, #1                          ; =0x1
	csel	w3, w0, w4, eq
	csel	w0, w0, w2, eq
	mov	w2, wzr
	ldr	w4, [sp, #188]                  ; 4-byte Folded Reload
	csel	w1, w4, w1, eq
LBB0_61:                                ;   in Loop: Header=BB0_62 Depth=2
	and	w0, w3, w0
	orr	w0, w0, w2
	add	w17, w17, w0
	strb	w17, [x5, x8]
	strh	w1, [x22, x8, lsl #1]
	ands	w17, w17, #0xff
	cinc	w12, w12, eq
	cmp	w17, #1
	cinc	w11, w11, eq
	cmp	w17, #3
	cinc	w9, w9, eq
	ldr	w0, [x20, x16, lsl #2]
	cmp	w17, #2
	cinc	w17, w0, eq
	str	w17, [x20, x16, lsl #2]
	ldr	w16, [x20, x15, lsl #2]
	cinc	w10, w10, eq
	cinc	w16, w16, eq
	str	w16, [x20, x15, lsl #2]
	add	x8, x8, #1
	cmp	x8, x28
	b.hs	LBB0_64
LBB0_62:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w17, [x5, x8]
	ldrh	w1, [x22, x8, lsl #1]
	ldr	w16, [x6, x8, lsl #2]
	ldr	w15, [x7, x8, lsl #2]
	tst	w17, #0xff
	b.ne	LBB0_60
; %bb.63:                               ;   in Loop: Header=BB0_62 Depth=2
	mov	w0, #0                          ; =0x0
	mov	w2, w8
	eor	x2, x2, x25
	add	x2, x2, x19
	eor	x2, x2, x2, lsr #30
	mul	x2, x2, x23
	eor	x2, x2, x2, lsr #27
	mul	x2, x2, x26
	eor	x2, x2, x2, lsr #31
	eor	x3, x2, x13
	add	x3, x3, x19
	eor	x3, x3, x3, lsr #30
	mul	x3, x3, x23
	eor	x3, x3, x3, lsr #27
	mul	x3, x3, x26
	lsr	x4, x3, #42
	eor	x3, x4, x3, lsr #11
	ucvtf	d0, x3, #53
	eor	x2, x2, x14
	add	x2, x2, x19
	eor	x2, x2, x2, lsr #30
	mul	x2, x2, x23
	eor	x2, x2, x2, lsr #27
	mul	x2, x2, x26
	lsr	x3, x2, #42
	eor	x2, x3, x2, lsr #11
	ucvtf	d1, x2, #53
	ldr	d2, [x21, x16, lsl #3]
	fcmp	d0, d2
	cset	w2, mi
	ldr	d0, [x21, x15, lsl #3]
	fcmp	d1, d0
	csinc	w2, w2, wzr, pl
	cmp	w1, #0
	cset	w3, eq
	cmp	w2, #0
	ldr	w4, [sp, #172]                  ; 4-byte Folded Reload
	csel	w1, w4, w1, ne
	b	LBB0_61
LBB0_64:                                ;   in Loop: Header=BB0_22 Depth=1
	stp	w12, w11, [sp, #228]
	stp	w10, w9, [sp, #236]
	stp	w12, w11, [sp, #208]
	str	w10, [sp, #216]
	lsr	w8, w9, #16
	strh	w9, [sp, #220]
	strh	w8, [sp, #222]
	ldp	x8, x9, [x27, #8]
	sub	x10, x29, #168
	stp	x8, x10, [x29, #-168]
	add	x10, sp, #208
	stp	x10, x27, [x29, #-152]
	cmp	x8, x9
	b.hs	LBB0_66
; %bb.65:                               ;   in Loop: Header=BB0_22 Depth=1
	ldr	q0, [sp, #208]
	str	q0, [x8], #16
	str	x8, [x27, #8]
	add	x24, x24, #1
	ldur	w8, [x29, #-212]
	str	x24, [sp, #160]                 ; 8-byte Folded Spill
	cmp	x24, x8
	b.lo	LBB0_22
	b	LBB0_68
LBB0_66:                                ;   in Loop: Header=BB0_22 Depth=1
Ltmp20:
	sub	x0, x29, #160
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
Ltmp21:
; %bb.67:                               ;   in Loop: Header=BB0_22 Depth=1
	ldur	x8, [x29, #-168]
	str	x8, [x27, #8]
	add	x24, x24, #1
	ldur	w8, [x29, #-212]
	str	x24, [sp, #160]                 ; 8-byte Folded Spill
	cmp	x24, x8
	b.lo	LBB0_22
LBB0_68:
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	ldr	x8, [sp, #8]                    ; 8-byte Folded Reload
	sub	x8, x0, x8
	scvtf	d0, x8
	mov	x8, #225833675390976            ; =0xcd6500000000
	movk	x8, #16845, lsl #48
	fmov	d1, x8
	fdiv	d0, d0, d1
	str	d0, [x27, #24]
	cbz	x21, LBB0_70
; %bb.69:
	mov	x0, x21
	bl	__ZdlPv
LBB0_70:
	cbz	x20, LBB0_72
; %bb.71:
	mov	x0, x20
	bl	__ZdlPv
LBB0_72:
	ldr	x0, [sp, #280]
	cbz	x0, LBB0_74
; %bb.73:
	str	x0, [sp, #288]
	bl	__ZdlPv
LBB0_74:
	ldr	x0, [sp, #256]
	cbz	x0, LBB0_76
; %bb.75:
	str	x0, [sp, #264]
	bl	__ZdlPv
LBB0_76:
	ldr	x0, [sp, #376]
	cbz	x0, LBB0_78
; %bb.77:
	str	x0, [sp, #384]
	bl	__ZdlPv
LBB0_78:
	ldr	x0, [sp, #352]
	cbz	x0, LBB0_80
; %bb.79:
	str	x0, [sp, #360]
	bl	__ZdlPv
LBB0_80:
	ldr	x0, [sp, #328]
	cbz	x0, LBB0_82
; %bb.81:
	str	x0, [sp, #336]
	bl	__ZdlPv
LBB0_82:
	ldr	x0, [sp, #304]
	cbz	x0, LBB0_84
; %bb.83:
	str	x0, [sp, #312]
	bl	__ZdlPv
LBB0_84:
	ldur	x8, [x29, #-128]
Lloh5:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh6:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh7:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB0_86
; %bb.85:
	add	sp, sp, #512
	ldp	x29, x30, [sp, #112]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #96]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #80]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #64]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #48]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #32]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #16]               ; 16-byte Folded Reload
	ldp	d11, d10, [sp], #128            ; 16-byte Folded Reload
	ret
LBB0_86:
	bl	___stack_chk_fail
LBB0_87:
Ltmp17:
	bl	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev
Ltmp18:
	b	LBB0_89
LBB0_88:
Ltmp14:
	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev
Ltmp15:
LBB0_89:
	brk	#0x1
LBB0_90:
Ltmp22:
	mov	x22, x0
	cbnz	x21, LBB0_94
; %bb.91:
	cbnz	x20, LBB0_97
LBB0_92:
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbnz	x0, LBB0_99
LBB0_93:
	add	x0, sp, #256
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #304
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
	bl	__Unwind_Resume
LBB0_94:
	mov	x0, x21
	bl	__ZdlPv
	cbz	x20, LBB0_92
	b	LBB0_97
LBB0_95:
Ltmp9:
	mov	x22, x0
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_93
	b	LBB0_99
LBB0_96:
Ltmp16:
	mov	x22, x0
LBB0_97:
	mov	x0, x20
	bl	__ZdlPv
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_93
	b	LBB0_99
LBB0_98:
Ltmp19:
	mov	x22, x0
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_93
LBB0_99:
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	str	x0, [x8, #8]
	bl	__ZdlPv
	add	x0, sp, #256
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #304
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
	bl	__Unwind_Resume
LBB0_100:
Ltmp4:
	mov	x22, x0
	add	x0, sp, #256
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #304
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
	bl	__Unwind_Resume
	.loh AdrpLdrGotLdr	Lloh0, Lloh1, Lloh2
	.loh AdrpLdr	Lloh3, Lloh4
	.loh AdrpLdrGotLdr	Lloh5, Lloh6, Lloh7
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
	.uleb128 Ltmp21-Lfunc_begin0            ; >> Call Site 10 <<
	.uleb128 Ltmp17-Ltmp21                  ;   Call between Ltmp21 and Ltmp17
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp17-Lfunc_begin0            ; >> Call Site 11 <<
	.uleb128 Ltmp18-Ltmp17                  ;   Call between Ltmp17 and Ltmp18
	.uleb128 Ltmp19-Lfunc_begin0            ;     jumps to Ltmp19
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp14-Lfunc_begin0            ; >> Call Site 12 <<
	.uleb128 Ltmp15-Ltmp14                  ;   Call between Ltmp14 and Ltmp15
	.uleb128 Ltmp16-Lfunc_begin0            ;     jumps to Ltmp16
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp15-Lfunc_begin0            ; >> Call Site 13 <<
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
Lloh8:
	adrp	x0, l_.str@PAGE
Lloh9:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh8, Lloh9
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
Lloh10:
	adrp	x1, __ZTISt12length_error@GOTPAGE
Lloh11:
	ldr	x1, [x1, __ZTISt12length_error@GOTPAGEOFF]
Lloh12:
	adrp	x2, __ZNSt12length_errorD1Ev@GOTPAGE
Lloh13:
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
	.loh AdrpLdrGot	Lloh12, Lloh13
	.loh AdrpLdrGot	Lloh10, Lloh11
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
Lloh14:
	adrp	x8, __ZTVSt12length_error@GOTPAGE
Lloh15:
	ldr	x8, [x8, __ZTVSt12length_error@GOTPAGEOFF]
	add	x8, x8, #16
	str	x8, [x0]
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.loh AdrpLdrGot	Lloh14, Lloh15
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
Lloh16:
	adrp	x1, __ZTISt20bad_array_new_length@GOTPAGE
Lloh17:
	ldr	x1, [x1, __ZTISt20bad_array_new_length@GOTPAGEOFF]
Lloh18:
	adrp	x2, __ZNSt20bad_array_new_lengthD1Ev@GOTPAGE
Lloh19:
	ldr	x2, [x2, __ZNSt20bad_array_new_lengthD1Ev@GOTPAGEOFF]
	bl	___cxa_throw
	.loh AdrpLdrGot	Lloh18, Lloh19
	.loh AdrpLdrGot	Lloh16, Lloh17
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
Lloh20:
	adrp	x0, l_.str@PAGE
Lloh21:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh20, Lloh21
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
Lloh22:
	adrp	x0, l_.str@PAGE
Lloh23:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh22, Lloh23
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"vector"

.subsections_via_symbols
