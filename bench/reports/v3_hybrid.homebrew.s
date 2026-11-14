	.build_version macos, 26, 0	sdk_version 26, 5
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
	.p2align	6
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
	sub	sp, sp, #496
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
	str	w1, [sp, #76]                   ; 4-byte Spill
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
	stp	q0, q0, [sp, #352]
	stp	q0, q0, [sp, #320]
	stp	q0, q0, [sp, #288]
	stp	q0, q0, [sp, #256]
	str	q0, [sp, #240]
Ltmp0:                                  ; EH_LABEL
	sub	x0, x29, #224
	add	x1, sp, #288
	add	x2, sp, #240
	bl	__Z18generate_syntheticRK6ParamsR10PopulationR9Locations
Ltmp1:                                  ; EH_LABEL
; %bb.3:
Ltmp2:                                  ; EH_LABEL
	sub	x0, x29, #224
	add	x1, sp, #288
	bl	__Z15seed_infectionsRK6ParamsR10Population
Ltmp3:                                  ; EH_LABEL
; %bb.4:
	ldp	x25, x19, [sp, #288]
	ldp	x8, x9, [sp, #240]
	stp	x8, x9, [sp, #120]              ; 16-byte Folded Spill
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [x27]
Ltmp5:                                  ; EH_LABEL
	add	x0, sp, #288
	str	x27, [sp, #80]                  ; 8-byte Spill
	bl	__Z12count_statesRK10Population
Ltmp6:                                  ; EH_LABEL
; %bb.5:
	stp	x0, x1, [sp, #224]
	ldp	x8, x9, [x27, #8]
	sub	x10, x29, #168
	add	x11, sp, #224
	stp	x8, x10, [x29, #-168]
	stp	x11, x27, [x29, #-152]
	cmp	x8, x9
	b.eq	LBB0_14
; %bb.6:
	ldr	q0, [sp, #224]
	str	q0, [x8], #16
	ldp	x10, x9, [sp, #120]             ; 16-byte Folded Reload
	sub	x20, x9, x10
	str	x8, [x27, #8]
	cmp	x9, x10
	b.eq	LBB0_16
LBB0_7:
	lsr	x8, x20, #62
	cbnz	x8, LBB0_90
; %bb.8:
	lsl	x23, x20, #2
Ltmp10:                                 ; EH_LABEL
	mov	x0, x23
	bl	__Znwm
Ltmp11:                                 ; EH_LABEL
; %bb.9:
	mov	x21, x0
	mov	x1, x23
	bl	_bzero
	lsr	x8, x20, #61
	add	x9, x21, x20, lsl #2
	str	x9, [sp, #8]                    ; 8-byte Spill
	cbnz	x8, LBB0_91
; %bb.10:
	lsl	x24, x20, #3
Ltmp12:                                 ; EH_LABEL
	mov	x0, x24
	bl	__Znwm
Ltmp13:                                 ; EH_LABEL
; %bb.11:
	mov	x22, x0
	add	x23, x21, x23
	add	x8, x0, x20, lsl #3
	str	x8, [sp]                        ; 8-byte Spill
	mov	x1, x24
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
Ltmp7:                                  ; EH_LABEL
	sub	x0, x29, #160
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev
Ltmp8:                                  ; EH_LABEL
; %bb.15:
	ldur	x8, [x29, #-168]
	ldp	x10, x9, [sp, #120]             ; 16-byte Folded Reload
	sub	x20, x9, x10
	str	x8, [x27, #8]
	cmp	x9, x10
	b.ne	LBB0_7
LBB0_16:
	mov	x21, #0                         ; =0x0
	mov	x23, #0                         ; =0x0
	stp	xzr, xzr, [sp]                  ; 16-byte Folded Spill
	mov	x22, #0                         ; =0x0
LBB0_17:
	sub	x28, x19, x25
	ldr	x9, [sp, #288]
	ldr	x8, [sp, #336]
	stp	x8, x9, [sp, #104]              ; 16-byte Folded Spill
	ldr	x8, [sp, #360]
	str	x8, [sp, #96]                   ; 8-byte Spill
	cmp	x19, x25
	b.eq	LBB0_20
; %bb.18:
	ldp	x8, x9, [sp, #96]               ; 16-byte Folded Reload
	ldr	x10, [sp, #112]                 ; 8-byte Reload
	mov	x11, x28
LBB0_19:                                ; =>This Inner Loop Header: Depth=1
	ldrb	w12, [x10], #1
	ldr	w13, [x9], #4
	ldr	w14, [x21, x13, lsl #2]
	cmp	w12, #2
	cinc	w12, w14, eq
	str	w12, [x21, x13, lsl #2]
	ldr	w12, [x8], #4
	ldr	w13, [x21, x12, lsl #2]
	cinc	w13, w13, eq
	str	w13, [x21, x12, lsl #2]
	subs	x11, x11, #1
	b.ne	LBB0_19
LBB0_20:
	ldr	x8, [sp, #312]
	str	x8, [sp, #64]                   ; 8-byte Spill
	ldur	x25, [x29, #-208]
	ldurh	w8, [x29, #-180]
	cmp	w8, #1
	csinc	w9, w8, wzr, hi
	ldurh	w8, [x29, #-178]
	cmp	w8, #1
	csinc	w8, w8, wzr, hi
	stp	w8, w9, [sp, #88]               ; 8-byte Folded Spill
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	str	x0, [sp, #16]                   ; 8-byte Spill
	ldur	w8, [x29, #-212]
	cbz	w8, LBB0_71
; %bb.21:
	str	xzr, [sp, #144]                 ; 8-byte Spill
	mov	x26, #58809                     ; =0xe5b9
	movk	x26, #7396, lsl #16
	movk	x26, #18285, lsl #32
	movk	x26, #48984, lsl #48
	mov	x19, #31765                     ; =0x7c15
	movk	x19, #32586, lsl #16
	movk	x19, #31161, lsl #32
	movk	x19, #40503, lsl #48
	mov	x24, #4587                      ; =0x11eb
	movk	x24, #4913, lsl #16
	movk	x24, #18875, lsl #32
	movk	x24, #38096, lsl #48
	add	x8, x25, x19
	eor	x8, x8, x8, lsr #30
	mul	x8, x8, x26
	eor	x8, x8, x8, lsr #27
	mul	x8, x8, x24
	eor	x8, x8, x8, lsr #31
	str	x8, [sp, #216]                  ; 8-byte Spill
	sub	x8, x23, x21
	str	x8, [sp, #48]                   ; 8-byte Spill
	ldp	w8, w9, [sp, #88]               ; 8-byte Folded Reload
	dup.8h	v1, w9
	dup.8h	v0, w8
	stp	q0, q1, [sp, #176]              ; 32-byte Folded Spill
	and	x10, x20, #0x7
	ldp	x9, x8, [sp, #120]              ; 16-byte Folded Reload
	sub	x8, x9, x8
	stp	x8, x10, [sp, #32]              ; 16-byte Folded Spill
	and	x8, x20, #0xfffffffffffffff8
	neg	x8, x8
	str	x8, [sp, #152]                  ; 8-byte Spill
Lloh3:
	adrp	x8, lCPI0_0@PAGE
Lloh4:
	ldr	q0, [x8, lCPI0_0@PAGEOFF]
	str	q0, [sp, #160]                  ; 16-byte Spill
	fmov	d8, #1.00000000
	str	x28, [sp, #56]                  ; 8-byte Spill
LBB0_22:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_27 Depth 2
                                        ;     Child Loop BB0_47 Depth 2
                                        ;     Child Loop BB0_55 Depth 2
                                        ;       Child Loop BB0_57 Depth 3
                                        ;     Child Loop BB0_64 Depth 2
	ldp	x9, x8, [sp, #120]              ; 16-byte Folded Reload
	cmp	x8, x9
	b.eq	LBB0_49
; %bb.23:                               ;   in Loop: Header=BB0_22 Depth=1
	ldp	d10, d9, [x29, #-200]
	ldr	x9, [sp, #264]
	ldr	x10, [sp, #240]
	ldr	x8, [sp, #32]                   ; 8-byte Reload
	cmn	x8, #8
	str	x9, [sp, #136]                  ; 8-byte Spill
	b.ls	LBB0_25
; %bb.24:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x8, #0                          ; =0x0
	b	LBB0_45
LBB0_25:                                ;   in Loop: Header=BB0_22 Depth=1
	str	xzr, [sp, #208]                 ; 8-byte Spill
	str	x10, [sp, #24]                  ; 8-byte Spill
	add	x27, x10, #3
	add	x25, x9, #16
	add	x23, x21, #16
	add	x20, x22, #32
	b	LBB0_27
LBB0_26:                                ;   in Loop: Header=BB0_27 Depth=2
	ldr	x9, [sp, #208]                  ; 8-byte Reload
	sub	x9, x9, #8
	add	x27, x27, #8
	str	d11, [x20, #24]
	add	x20, x20, #64
	add	x23, x23, #32
	mov	x25, x28
	ldr	x8, [sp, #152]                  ; 8-byte Reload
	str	x9, [sp, #208]                  ; 8-byte Spill
	cmp	x8, x9
	b.eq	LBB0_43
LBB0_27:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldur	w8, [x25, #-16]
	movi.2d	v11, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_29
; %bb.28:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x27, #-3]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x23, #-16]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
LBB0_29:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d0, [x20, #-32]
	ldur	w8, [x25, #-12]
	cbz	w8, LBB0_31
; %bb.30:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x27, #-2]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x23, #-12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d11, d8, d0
LBB0_31:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d11, [x20, #-24]
	ldur	w8, [x25, #-8]
	movi.2d	v11, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_33
; %bb.32:                               ;   in Loop: Header=BB0_27 Depth=2
	ldurb	w9, [x27, #-1]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x23, #-8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
LBB0_33:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d0, [x20, #-16]
	ldur	w8, [x25, #-4]
	cbz	w8, LBB0_35
; %bb.34:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x23, #-4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d11, d8, d0
LBB0_35:                                ;   in Loop: Header=BB0_27 Depth=2
	stur	d11, [x20, #-8]
	mov	x28, x25
	ldr	w8, [x28], #32
	movi.2d	v11, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_37
; %bb.36:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27, #1]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x23]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
LBB0_37:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d0, [x20]
	ldr	w8, [x25, #4]
	cbz	w8, LBB0_39
; %bb.38:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27, #2]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x23, #4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d11, d8, d0
LBB0_39:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d11, [x20, #8]
	ldr	w8, [x25, #8]
	movi.2d	v11, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB0_41
; %bb.40:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27, #3]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x23, #8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
LBB0_41:                                ;   in Loop: Header=BB0_27 Depth=2
	str	d0, [x20, #16]
	ldr	w8, [x25, #12]
	cbz	w8, LBB0_26
; %bb.42:                               ;   in Loop: Header=BB0_27 Depth=2
	ldrb	w9, [x27, #4]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x23, #12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d11, d8, d0
	b	LBB0_26
LBB0_43:                                ;   in Loop: Header=BB0_22 Depth=1
	ldr	x8, [sp, #40]                   ; 8-byte Reload
	cbz	x8, LBB0_49
; %bb.44:                               ;   in Loop: Header=BB0_22 Depth=1
	ldr	x8, [sp, #208]                  ; 8-byte Reload
	neg	x8, x8
	ldr	x10, [sp, #24]                  ; 8-byte Reload
LBB0_45:                                ;   in Loop: Header=BB0_22 Depth=1
	add	x20, x22, x8, lsl #3
	lsl	x9, x8, #2
	add	x23, x21, x9
	add	x25, x10, x8
	ldr	x8, [sp, #136]                  ; 8-byte Reload
	add	x27, x8, x9
	ldr	x28, [sp, #40]                  ; 8-byte Reload
	b	LBB0_47
LBB0_46:                                ;   in Loop: Header=BB0_47 Depth=2
	ldrb	w9, [x25], #1
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x23], #4
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fsub	d0, d8, d0
	str	d0, [x20], #8
	subs	x28, x28, #1
	b.eq	LBB0_49
LBB0_47:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	w8, [x27], #4
	cbnz	w8, LBB0_46
; %bb.48:                               ;   in Loop: Header=BB0_47 Depth=2
	movi.2d	v0, #0000000000000000
	str	d0, [x20], #8
	add	x23, x23, #4
	add	x25, x25, #1
	subs	x28, x28, #1
	b.ne	LBB0_47
LBB0_49:                                ;   in Loop: Header=BB0_22 Depth=1
	ldr	x1, [sp, #48]                   ; 8-byte Reload
	cmp	x1, #1
	b.lt	LBB0_51
; %bb.50:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x0, x21
	bl	_bzero
LBB0_51:                                ;   in Loop: Header=BB0_22 Depth=1
	mov	x8, #0                          ; =0x0
	movi.2d	v0, #0000000000000000
	ldr	w9, [sp, #76]                   ; 4-byte Reload
	ldp	x28, x7, [sp, #56]              ; 16-byte Folded Reload
	ldp	x5, x4, [sp, #104]              ; 16-byte Folded Reload
	ldr	x6, [sp, #96]                   ; 8-byte Reload
	ldp	w23, w20, [sp, #88]             ; 8-byte Folded Reload
	ldr	x25, [sp, #144]                 ; 8-byte Reload
	cbz	w9, LBB0_59
; %bb.52:                               ;   in Loop: Header=BB0_22 Depth=1
	cmp	x28, #16
	ldr	x27, [sp, #80]                  ; 8-byte Reload
	b.lo	LBB0_60
; %bb.53:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	x14, #0                         ; =0x0
	mov	w9, #3                          ; =0x3
	bfi	x9, x25, #8, #55
	mov	x10, x4
	mov	x11, x5
	mov	x12, x6
	mov	w16, #16                        ; =0x10
	mov	w8, #4                          ; =0x4
	orr	x13, x8, x25, lsl #8
	b	LBB0_55
LBB0_54:                                ;   in Loop: Header=BB0_55 Depth=2
	ldr	q2, [x4, x14]
	ldur	q1, [x29, #-160]
	movi.16b	v24, #1
	cmeq.16b	v1, v1, v24
	cmeq.16b	v3, v2, #0
	cmeq.16b	v4, v2, v24
	movi.16b	v25, #2
	cmeq.16b	v5, v2, v25
	movi.2d	v6, #0xffffffffffffffff
	add.16b	v6, v2, v6
	cmhi.16b	v6, v25, v6
	ushll2.8h	v7, v6, #0
	shl.8h	v7, v7, #15
	cmlt.8h	v7, v7, #0
	ushll.8h	v16, v6, #0
	shl.8h	v16, v16, #15
	cmlt.8h	v16, v16, #0
	add	x15, x7, x14, lsl #1
	ldp	q17, q18, [x15]
	saddw.8h	v19, v17, v6
	saddw2.8h	v6, v18, v6
	cmeq.8h	v20, v6, #0
	cmeq.8h	v21, v19, #0
	uzp1.16b	v22, v21, v20
	xtn.8b	v20, v20
	xtn.8b	v21, v21
	and.16b	v23, v4, v22
	and.16b	v5, v5, v22
	and.16b	v1, v3, v1
	ushll2.8h	v3, v1, #0
	shl.8h	v3, v3, #15
	cmlt.8h	v3, v3, #0
	ushll.8h	v22, v1, #0
	shl.8h	v22, v22, #15
	orr.16b	v1, v5, v1
	orr.16b	v5, v1, v23
	sub.16b	v1, v2, v5
	str	q1, [x4, x14]
	cmlt.8h	v22, v22, #0
	and.8b	v21, v4, v21
	bsl.16b	v16, v19, v17
	sshll.8h	v17, v21, #0
	ldr	q19, [sp, #176]                 ; 16-byte Reload
	bit.16b	v16, v19, v17
	ldr	q17, [sp, #192]                 ; 16-byte Reload
	bit.16b	v16, v17, v22
	mov	d4, v4[1]
	and.8b	v4, v4, v20
	bif.16b	v6, v18, v7
	sshll.8h	v4, v4, #0
	bsl.16b	v4, v19, v6
	bsl.16b	v3, v17, v4
	stp	q16, q3, [x15]
	cmeq.16b	v2, v2, v5
	ldr	q6, [sp, #160]                  ; 16-byte Reload
	and.16b	v2, v2, v6
	addp.16b	v2, v2, v2
	addp.16b	v2, v2, v2
	addp.16b	v2, v2, v2
	cmeq.16b	v3, v1, v24
	and.16b	v3, v3, v6
	addp.16b	v3, v3, v3
	addp.16b	v3, v3, v3
	addp.16b	v3, v3, v3
	cmeq.16b	v4, v1, v25
	and.16b	v4, v4, v6
	addp.16b	v4, v4, v4
	addp.16b	v4, v4, v4
	addp.16b	v4, v4, v4
	movi.16b	v5, #3
	cmeq.16b	v5, v1, v5
	and.16b	v5, v5, v6
	addp.16b	v5, v5, v5
	addp.16b	v5, v5, v5
	addp.16b	v5, v5, v5
	zip1.4h	v5, v4, v5
	ext.8b	v4, v4, v5, #4
	zip1.4h	v2, v2, v3
	mov.s	v2[1], v4[1]
	umov.b	w15, v1[0]
	lsl	x14, x14, #2
	ldr	w16, [x5, x14]
	ldr	w17, [x21, x16, lsl #2]
	cmp	w15, #2
	cinc	w15, w17, eq
	str	w15, [x21, x16, lsl #2]
	ldr	w15, [x6, x14]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[1]
	orr	x16, x14, #0x4
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[2]
	orr	x16, x14, #0x8
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[3]
	orr	x16, x14, #0xc
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[4]
	orr	x16, x14, #0x10
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[5]
	mov	w16, #20                        ; =0x14
	orr	x16, x14, x16
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[6]
	orr	x16, x14, #0x18
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[7]
	orr	x16, x14, #0x1c
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[8]
	orr	x16, x14, #0x20
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[9]
	mov	w16, #36                        ; =0x24
	orr	x16, x14, x16
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[10]
	mov	w16, #40                        ; =0x28
	orr	x16, x14, x16
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[11]
	mov	w16, #44                        ; =0x2c
	orr	x16, x14, x16
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[12]
	orr	x16, x14, #0x30
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[13]
	mov	w16, #52                        ; =0x34
	orr	x16, x14, x16
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[14]
	orr	x16, x14, #0x38
	ldr	w17, [x5, x16]
	ldr	w0, [x21, x17, lsl #2]
	cmp	w15, #2
	cinc	w15, w0, eq
	str	w15, [x21, x17, lsl #2]
	ldr	w15, [x6, x16]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	umov.b	w15, v1[15]
	orr	x14, x14, #0x3c
	ldr	w16, [x5, x14]
	ldr	w17, [x21, x16, lsl #2]
	cmp	w15, #2
	cinc	w15, w17, eq
	str	w15, [x21, x16, lsl #2]
	ldr	w14, [x6, x14]
	ldr	w15, [x21, x14, lsl #2]
	cnt.8b	v1, v2
	uaddlp.4h	v1, v1
	cinc	w15, w15, eq
	str	w15, [x21, x14, lsl #2]
	add	x16, x8, #16
	add	x12, x12, #64
	uaddw.4s	v0, v0, v1
	add	x11, x11, #64
	add	x10, x10, #16
	mov	x14, x8
	cmp	x16, x28
	b.hi	LBB0_60
LBB0_55:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB0_57 Depth 3
	mov	x15, #0                         ; =0x0
	mov	x8, x16
	mov	w16, w14
	b	LBB0_57
LBB0_56:                                ;   in Loop: Header=BB0_57 Depth=3
	add	x17, x16, x15
	ldr	x0, [sp, #216]                  ; 8-byte Reload
	eor	x17, x17, x0
	add	x17, x17, x19
	eor	x17, x17, x17, lsr #30
	mul	x17, x17, x26
	eor	x17, x17, x17, lsr #27
	mul	x17, x17, x24
	eor	x17, x17, x17, lsr #31
	eor	x0, x17, x9
	add	x0, x0, x19
	eor	x0, x0, x0, lsr #30
	mul	x0, x0, x26
	eor	x0, x0, x0, lsr #27
	mul	x0, x0, x24
	lsr	x1, x0, #42
	eor	x0, x1, x0, lsr #11
	ucvtf	d1, x0, #53
	eor	x17, x17, x13
	add	x17, x17, x19
	eor	x17, x17, x17, lsr #30
	mul	x17, x17, x26
	eor	x17, x17, x17, lsr #27
	mul	x17, x17, x24
	lsr	x0, x17, #42
	eor	x17, x0, x17, lsr #11
	ucvtf	d2, x17, #53
	ldr	w17, [x11, x15, lsl #2]
	ldr	d3, [x22, x17, lsl #3]
	fcmp	d1, d3
	cset	w17, mi
	ldr	w0, [x12, x15, lsl #2]
	ldr	d1, [x22, x0, lsl #3]
	fcmp	d2, d1
	csinc	w17, w17, wzr, pl
	sub	x0, x29, #160
	strb	w17, [x0, x15]
	add	x15, x15, #1
	cmp	x15, #16
	b.eq	LBB0_54
LBB0_57:                                ;   Parent Loop BB0_22 Depth=1
                                        ;     Parent Loop BB0_55 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldrb	w17, [x10, x15]
	cbz	w17, LBB0_56
; %bb.58:                               ;   in Loop: Header=BB0_57 Depth=3
	mov	w17, #0                         ; =0x0
	sub	x0, x29, #160
	strb	w17, [x0, x15]
	add	x15, x15, #1
	cmp	x15, #16
	b.ne	LBB0_57
	b	LBB0_54
LBB0_59:                                ;   in Loop: Header=BB0_22 Depth=1
	ldr	x27, [sp, #80]                  ; 8-byte Reload
LBB0_60:                                ;   in Loop: Header=BB0_22 Depth=1
	mov.s	w9, v0[1]
	fmov	w10, s0
	mov.s	w11, v0[2]
	mov.s	w12, v0[3]
	cmp	x8, x28
	b.hs	LBB0_67
; %bb.61:                               ;   in Loop: Header=BB0_22 Depth=1
	mov	w13, #3                         ; =0x3
	bfi	x13, x25, #8, #55
	mov	w14, #4                         ; =0x4
	orr	x14, x14, x25, lsl #8
	b	LBB0_64
LBB0_62:                                ;   in Loop: Header=BB0_64 Depth=2
	cmp	w17, #3
	sbc	w1, w0, wzr
	csel	w0, w1, w0, lo
	cset	w2, lo
	tst	w1, #0xffff
	csel	w2, wzr, w2, ne
	cmp	w17, #1
	and	w1, w1, #0xffff
	ccmp	w1, #0, #0, eq
	csel	w0, w23, w0, eq
	csinc	w1, w2, wzr, ne
LBB0_63:                                ;   in Loop: Header=BB0_64 Depth=2
	add	w17, w17, w1
	strb	w17, [x4, x8]
	strh	w0, [x7, x8, lsl #1]
	ands	w17, w17, #0xff
	cinc	w10, w10, eq
	cmp	w17, #1
	cinc	w9, w9, eq
	cmp	w17, #3
	cinc	w12, w12, eq
	ldr	w0, [x21, x16, lsl #2]
	cmp	w17, #2
	cinc	w17, w0, eq
	str	w17, [x21, x16, lsl #2]
	ldr	w16, [x21, x15, lsl #2]
	cinc	w11, w11, eq
	cinc	w16, w16, eq
	str	w16, [x21, x15, lsl #2]
	add	x8, x8, #1
	cmp	x8, x28
	b.hs	LBB0_67
LBB0_64:                                ;   Parent Loop BB0_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w17, [x4, x8]
	ldrh	w0, [x7, x8, lsl #1]
	ldr	w16, [x5, x8, lsl #2]
	ldr	w15, [x6, x8, lsl #2]
	cbnz	w17, LBB0_62
; %bb.65:                               ;   in Loop: Header=BB0_64 Depth=2
	mov	w1, w8
	ldr	x2, [sp, #216]                  ; 8-byte Reload
	eor	x1, x1, x2
	add	x1, x1, x19
	eor	x1, x1, x1, lsr #30
	mul	x1, x1, x26
	eor	x1, x1, x1, lsr #27
	mul	x1, x1, x24
	eor	x1, x1, x1, lsr #31
	eor	x2, x1, x13
	add	x2, x2, x19
	eor	x2, x2, x2, lsr #30
	mul	x2, x2, x26
	eor	x2, x2, x2, lsr #27
	mul	x2, x2, x24
	lsr	x3, x2, #42
	eor	x2, x3, x2, lsr #11
	ucvtf	d0, x2, #53
	eor	x1, x1, x14
	add	x1, x1, x19
	eor	x1, x1, x1, lsr #30
	mul	x1, x1, x26
	eor	x1, x1, x1, lsr #27
	mul	x1, x1, x24
	lsr	x2, x1, #42
	eor	x1, x2, x1, lsr #11
	ucvtf	d1, x1, #53
	ldr	d2, [x22, x16, lsl #3]
	fcmp	d0, d2
	cset	w1, mi
	ldr	d0, [x22, x15, lsl #3]
	fcmp	d1, d0
	csinc	w1, w1, wzr, pl
	.p2align	6, , 4
; %bb.66:                               ;   in Loop: Header=BB0_64 Depth=2
	cmp	w1, #0
	csel	w0, w20, w0, ne
	b	LBB0_63
LBB0_67:                                ;   in Loop: Header=BB0_22 Depth=1
	stp	w10, w9, [sp, #224]
	stp	w11, w12, [sp, #232]
	ldp	x8, x9, [x27, #8]
	sub	x10, x29, #168
	stp	x8, x10, [x29, #-168]
	add	x10, sp, #224
	stp	x10, x27, [x29, #-152]
	cmp	x8, x9
	b.eq	LBB0_69
; %bb.68:                               ;   in Loop: Header=BB0_22 Depth=1
	ldr	q0, [sp, #224]
	str	q0, [x8], #16
	str	x8, [x27, #8]
	add	x25, x25, #1
	ldur	w8, [x29, #-212]
	str	x25, [sp, #144]                 ; 8-byte Spill
	cmp	x25, x8
	b.lo	LBB0_22
	b	LBB0_71
LBB0_69:                                ;   in Loop: Header=BB0_22 Depth=1
Ltmp20:                                 ; EH_LABEL
	sub	x0, x29, #160
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev
Ltmp21:                                 ; EH_LABEL
; %bb.70:                               ;   in Loop: Header=BB0_22 Depth=1
	ldur	x8, [x29, #-168]
	str	x8, [x27, #8]
	add	x25, x25, #1
	ldur	w8, [x29, #-212]
	str	x25, [sp, #144]                 ; 8-byte Spill
	cmp	x25, x8
	b.lo	LBB0_22
LBB0_71:
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	ldr	x8, [sp, #16]                   ; 8-byte Reload
	sub	x8, x0, x8
	scvtf	d0, x8
	mov	x8, #225833675390976            ; =0xcd6500000000
	movk	x8, #16845, lsl #48
	fmov	d1, x8
	fdiv	d0, d0, d1
	str	d0, [x27, #24]
	cbz	x22, LBB0_73
; %bb.72:
	ldr	x8, [sp]                        ; 8-byte Reload
	sub	x1, x8, x22
	mov	x0, x22
	bl	__ZdlPvm
LBB0_73:
	cbz	x21, LBB0_75
; %bb.74:
	ldr	x8, [sp, #8]                    ; 8-byte Reload
	sub	x1, x8, x21
	mov	x0, x21
	bl	__ZdlPvm
LBB0_75:
	ldr	x0, [sp, #264]
	cbz	x0, LBB0_77
; %bb.76:
	str	x0, [sp, #272]
	ldr	x8, [sp, #280]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB0_77:
	ldr	x0, [sp, #240]
	cbz	x0, LBB0_79
; %bb.78:
	str	x0, [sp, #248]
	ldr	x8, [sp, #256]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB0_79:
	ldr	x0, [sp, #360]
	cbz	x0, LBB0_81
; %bb.80:
	str	x0, [sp, #368]
	ldr	x8, [sp, #376]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB0_81:
	ldr	x0, [sp, #336]
	cbz	x0, LBB0_83
; %bb.82:
	str	x0, [sp, #344]
	ldr	x8, [sp, #352]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB0_83:
	ldr	x0, [sp, #312]
	cbz	x0, LBB0_85
; %bb.84:
	str	x0, [sp, #320]
	ldr	x8, [sp, #328]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB0_85:
	ldr	x0, [sp, #288]
	cbz	x0, LBB0_87
; %bb.86:
	str	x0, [sp, #296]
	ldr	x8, [sp, #304]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB0_87:
	ldur	x8, [x29, #-128]
Lloh5:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh6:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh7:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB0_89
; %bb.88:
	add	sp, sp, #496
	ldp	x29, x30, [sp, #112]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #96]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #80]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #64]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #48]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #32]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #16]               ; 16-byte Folded Reload
	ldp	d11, d10, [sp], #128            ; 16-byte Folded Reload
	ret
LBB0_89:
	bl	___stack_chk_fail
LBB0_90:
Ltmp17:                                 ; EH_LABEL
	bl	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe230105Ev
Ltmp18:                                 ; EH_LABEL
	b	LBB0_92
LBB0_91:
Ltmp14:                                 ; EH_LABEL
	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe230105Ev
Ltmp15:                                 ; EH_LABEL
LBB0_92:
	brk	#0x1
LBB0_93:
Ltmp22:                                 ; EH_LABEL
	mov	x20, x0
	cbnz	x22, LBB0_97
; %bb.94:
	cbnz	x21, LBB0_100
LBB0_95:
	ldr	x8, [sp, #80]                   ; 8-byte Reload
	ldr	x0, [x8]
	cbnz	x0, LBB0_102
LBB0_96:
	add	x0, sp, #240
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #288
	bl	__ZN10PopulationD1Ev
	mov	x0, x20
	bl	__Unwind_Resume
LBB0_97:
	ldr	x8, [sp]                        ; 8-byte Reload
	sub	x1, x8, x22
	mov	x0, x22
	bl	__ZdlPvm
	cbz	x21, LBB0_95
	b	LBB0_100
LBB0_98:
Ltmp9:                                  ; EH_LABEL
	mov	x20, x0
	ldr	x8, [sp, #80]                   ; 8-byte Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_96
	b	LBB0_102
LBB0_99:
Ltmp16:                                 ; EH_LABEL
	mov	x20, x0
LBB0_100:
	ldr	x8, [sp, #8]                    ; 8-byte Reload
	sub	x1, x8, x21
	mov	x0, x21
	bl	__ZdlPvm
	ldr	x8, [sp, #80]                   ; 8-byte Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_96
	b	LBB0_102
LBB0_101:
Ltmp19:                                 ; EH_LABEL
	mov	x20, x0
	ldr	x8, [sp, #80]                   ; 8-byte Reload
	ldr	x0, [x8]
	cbz	x0, LBB0_96
LBB0_102:
	ldr	x8, [sp, #80]                   ; 8-byte Reload
	str	x0, [x8, #8]
	ldr	x8, [x8, #16]
	sub	x1, x8, x0
	bl	__ZdlPvm
	add	x0, sp, #240
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #288
	bl	__ZN10PopulationD1Ev
	mov	x0, x20
	bl	__Unwind_Resume
LBB0_103:
Ltmp4:                                  ; EH_LABEL
	mov	x20, x0
	add	x0, sp, #240
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #288
	bl	__ZN10PopulationD1Ev
	mov	x0, x20
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
	ldr	x8, [x19, #40]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB1_2:
	ldr	x0, [x19]
	cbz	x0, LBB1_4
; %bb.3:
	str	x0, [x19, #8]
	ldr	x8, [x19, #16]
	sub	x1, x8, x0
	bl	__ZdlPvm
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
	ldr	x8, [x19, #88]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB2_2:
	ldr	x0, [x19, #48]
	cbz	x0, LBB2_4
; %bb.3:
	str	x0, [x19, #56]
	ldr	x8, [x19, #64]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB2_4:
	ldr	x0, [x19, #24]
	cbz	x0, LBB2_6
; %bb.5:
	str	x0, [x19, #32]
	ldr	x8, [x19, #40]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB2_6:
	ldr	x0, [x19]
	cbz	x0, LBB2_8
; %bb.7:
	str	x0, [x19, #8]
	ldr	x8, [x19, #16]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB2_8:
	mov	x0, x19
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev ; -- Begin function _ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev
	.globl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev
	.weak_def_can_be_hidden	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev
	.p2align	2
__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev: ; @_ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev
	.cfi_startproc
; %bb.0:
	stp	x28, x27, [sp, #-96]!           ; 16-byte Folded Spill
	stp	x26, x25, [sp, #16]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #32]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #48]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #64]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #80]             ; 16-byte Folded Spill
	add	x29, sp, #80
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
	ldr	x24, [x0, #16]
	ldp	x20, x8, [x24]
	sub	x21, x8, x20
	asr	x25, x21, #4
	add	x8, x25, #1
	lsr	x9, x8, #60
	cbnz	x9, LBB3_5
; %bb.1:
	ldr	x9, [x24, #16]
	mov	x10, #9223372036854775792       ; =0x7ffffffffffffff0
	sub	x22, x9, x20
	asr	x9, x22, #3
	cmp	x9, x8
	csel	x8, x9, x8, hi
	cmp	x22, x10
	mov	x9, #1152921504606846975        ; =0xfffffffffffffff
	csel	x8, x8, x9, lo
	lsr	x9, x8, #60
	cbnz	x9, LBB3_6
; %bb.2:
	mov	x19, x0
	ldr	x26, [x0, #8]
	lsl	x23, x8, #4
	mov	x0, x23
	bl	__Znwm
	add	x8, x0, x21
	add	x27, x0, x23
	ldr	q0, [x26]
	str	q0, [x8]
	add	x26, x8, #16
	sub	x23, x8, x25, lsl #4
	mov	x0, x23
	mov	x1, x20
	mov	x2, x21
	bl	_memcpy
	stp	x23, x26, [x24]
	str	x27, [x24, #16]
	cbz	x20, LBB3_4
; %bb.3:
	mov	x0, x20
	mov	x1, x22
	bl	__ZdlPvm
LBB3_4:
	ldr	x8, [x19]
	str	x26, [x8]
	ldp	x29, x30, [sp, #80]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #64]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #48]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #32]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #16]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp], #96             ; 16-byte Folded Reload
	ret
LBB3_5:
	bl	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe230105Ev
LBB3_6:
	bl	__ZSt28__throw_bad_array_new_lengthB9nqe230105v
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe230105Ev ; -- Begin function _ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe230105Ev
	.globl	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe230105Ev
	.weak_def_can_be_hidden	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe230105Ev
	.p2align	2
__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe230105Ev: ; @_ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe230105Ev
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
	bl	__ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.loh AdrpAdd	Lloh8, Lloh9
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZNSt3__120__throw_length_errorB9nqe230105EPKc ; -- Begin function _ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.globl	__ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.weak_def_can_be_hidden	__ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.p2align	2
__ZNSt3__120__throw_length_errorB9nqe230105EPKc: ; @_ZNSt3__120__throw_length_errorB9nqe230105EPKc
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
Ltmp23:                                 ; EH_LABEL
	mov	x1, x20
	bl	__ZNSt12length_errorC1B9nqe230105EPKc
Ltmp24:                                 ; EH_LABEL
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
Ltmp25:                                 ; EH_LABEL
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
	.private_extern	__ZNSt12length_errorC1B9nqe230105EPKc ; -- Begin function _ZNSt12length_errorC1B9nqe230105EPKc
	.globl	__ZNSt12length_errorC1B9nqe230105EPKc
	.weak_def_can_be_hidden	__ZNSt12length_errorC1B9nqe230105EPKc
	.p2align	2
__ZNSt12length_errorC1B9nqe230105EPKc:  ; @_ZNSt12length_errorC1B9nqe230105EPKc
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
	.private_extern	__ZSt28__throw_bad_array_new_lengthB9nqe230105v ; -- Begin function _ZSt28__throw_bad_array_new_lengthB9nqe230105v
	.globl	__ZSt28__throw_bad_array_new_lengthB9nqe230105v
	.weak_def_can_be_hidden	__ZSt28__throw_bad_array_new_lengthB9nqe230105v
	.p2align	2
__ZSt28__throw_bad_array_new_lengthB9nqe230105v: ; @_ZSt28__throw_bad_array_new_lengthB9nqe230105v
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
	.private_extern	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe230105Ev ; -- Begin function _ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe230105Ev
	.globl	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe230105Ev
	.weak_def_can_be_hidden	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe230105Ev
	.p2align	2
__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe230105Ev: ; @_ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe230105Ev
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
	bl	__ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.loh AdrpAdd	Lloh20, Lloh21
	.cfi_endproc
                                        ; -- End function
	.private_extern	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe230105Ev ; -- Begin function _ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe230105Ev
	.globl	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe230105Ev
	.weak_def_can_be_hidden	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe230105Ev
	.p2align	2
__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe230105Ev: ; @_ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe230105Ev
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
	bl	__ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.loh AdrpAdd	Lloh22, Lloh23
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"vector"

.subsections_via_symbols
