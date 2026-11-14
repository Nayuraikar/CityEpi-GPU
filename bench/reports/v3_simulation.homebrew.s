	.build_version macos, 26, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	__Z15v3_neon_enabledv           ; -- Begin function _Z15v3_neon_enabledv
	.p2align	2
__Z15v3_neon_enabledv:                  ; @_Z15v3_neon_enabledv
	.cfi_startproc
; %bb.0:
	mov	w0, #1                          ; =0x1
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4, 0x0                          ; -- Begin function _Z17run_simulation_v3RK6Paramsb
lCPI1_0:
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
	.globl	__Z17run_simulation_v3RK6Paramsb
	.p2align	6
__Z17run_simulation_v3RK6Paramsb:       ; @_Z17run_simulation_v3RK6Paramsb
Lfunc_begin0:
	.cfi_startproc
	.cfi_personality 155, ___gxx_personality_v0
	.cfi_lsda 16, Lexception0
; %bb.0:
	stp	d15, d14, [sp, #-160]!          ; 16-byte Folded Spill
	stp	d13, d12, [sp, #16]             ; 16-byte Folded Spill
	stp	d11, d10, [sp, #32]             ; 16-byte Folded Spill
	stp	d9, d8, [sp, #48]               ; 16-byte Folded Spill
	stp	x28, x27, [sp, #64]             ; 16-byte Folded Spill
	stp	x26, x25, [sp, #80]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #96]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #112]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #128]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #144]            ; 16-byte Folded Spill
	add	x29, sp, #144
	sub	sp, sp, #592
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
	.cfi_offset b14, -152
	.cfi_offset b15, -160
	str	w1, [sp, #172]                  ; 4-byte Spill
	mov	x19, x8
Lloh0:
	adrp	x8, ___stack_chk_guard@GOTPAGE
Lloh1:
	ldr	x8, [x8, ___stack_chk_guard@GOTPAGEOFF]
Lloh2:
	ldr	x8, [x8]
	stur	x8, [x29, #-160]
	ldp	q1, q0, [x0, #16]
	stp	q1, q0, [sp, #480]
	ldr	q0, [x0]
	str	q0, [sp, #464]
	ldrh	w8, [sp, #508]
	cbz	w8, LBB1_12
; %bb.1:
	ldrh	w8, [sp, #510]
	cbz	w8, LBB1_13
LBB1_2:
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [sp, #432]
	stp	q0, q0, [sp, #400]
	stp	q0, q0, [sp, #368]
	stp	q0, q0, [sp, #336]
	str	q0, [sp, #320]
Ltmp0:                                  ; EH_LABEL
	add	x0, sp, #464
	add	x1, sp, #368
	add	x2, sp, #320
	bl	__Z18generate_syntheticRK6ParamsR10PopulationR9Locations
Ltmp1:                                  ; EH_LABEL
; %bb.3:
Ltmp2:                                  ; EH_LABEL
	add	x0, sp, #464
	add	x1, sp, #368
	bl	__Z15seed_infectionsRK6ParamsR10Population
Ltmp3:                                  ; EH_LABEL
; %bb.4:
	ldp	x26, x25, [sp, #368]
	ldp	x8, x9, [sp, #320]
	stp	x8, x9, [sp, #184]              ; 16-byte Folded Spill
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [x19]
Ltmp5:                                  ; EH_LABEL
	add	x0, sp, #368
	str	x19, [sp, #176]                 ; 8-byte Spill
	bl	__Z12count_statesRK10Population
Ltmp6:                                  ; EH_LABEL
; %bb.5:
	stp	x0, x1, [x29, #-208]
	ldp	x8, x9, [x19, #8]
	stur	x8, [x29, #-216]
	sub	x10, x29, #216
	sub	x11, x29, #208
	stp	x10, x11, [x29, #-184]
	stur	x19, [x29, #-168]
	cmp	x8, x9
	b.eq	LBB1_14
; %bb.6:
	ldur	q0, [x29, #-208]
	str	q0, [x8], #16
	ldp	x10, x9, [sp, #184]             ; 16-byte Folded Reload
	sub	x20, x9, x10
	str	x8, [x19, #8]
	cmp	x9, x10
	b.eq	LBB1_16
LBB1_7:
	lsr	x8, x20, #62
	cbnz	x8, LBB1_129
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
	str	x9, [sp, #80]                   ; 8-byte Spill
	cbnz	x8, LBB1_130
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
	str	x8, [sp, #72]                   ; 8-byte Spill
	mov	x1, x24
	bl	_bzero
	b	LBB1_17
LBB1_12:
	mov	w8, #1                          ; =0x1
	strh	w8, [sp, #508]
	ldrh	w8, [sp, #510]
	cbnz	w8, LBB1_2
LBB1_13:
	mov	w8, #1                          ; =0x1
	strh	w8, [sp, #510]
	b	LBB1_2
LBB1_14:
Ltmp7:                                  ; EH_LABEL
	sub	x0, x29, #184
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev
Ltmp8:                                  ; EH_LABEL
; %bb.15:
	ldur	x8, [x29, #-216]
	ldp	x10, x9, [sp, #184]             ; 16-byte Folded Reload
	sub	x20, x9, x10
	str	x8, [x19, #8]
	cmp	x9, x10
	b.ne	LBB1_7
LBB1_16:
	mov	x21, #0                         ; =0x0
	mov	x23, #0                         ; =0x0
	stp	xzr, xzr, [sp, #72]             ; 16-byte Folded Spill
	mov	x22, #0                         ; =0x0
LBB1_17:
	sub	x28, x25, x26
	ldr	x27, [sp, #368]
	ldr	x8, [sp, #416]
	str	x8, [sp, #312]                  ; 8-byte Spill
	ldr	x19, [sp, #440]
	cmp	x25, x26
	b.eq	LBB1_20
; %bb.18:
	mov	x8, x19
	ldr	x9, [sp, #312]                  ; 8-byte Reload
	mov	x10, x27
	mov	x11, x28
LBB1_19:                                ; =>This Inner Loop Header: Depth=1
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
	b.ne	LBB1_19
LBB1_20:
	ldr	x26, [sp, #392]
	ldr	x24, [sp, #480]
	ldrh	w8, [sp, #508]
	cmp	w8, #1
	csinc	w9, w8, wzr, hi
	ldrh	w8, [sp, #510]
	cmp	w8, #1
	csinc	w8, w8, wzr, hi
	stp	w8, w9, [sp, #136]              ; 8-byte Folded Spill
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	str	x0, [sp, #88]                   ; 8-byte Spill
	ldr	w8, [sp, #476]
	cbz	w8, LBB1_110
; %bb.21:
	str	xzr, [sp, #200]                 ; 8-byte Spill
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
	eor	x8, x8, x8, lsr #31
	sub	x9, x23, x21
	mov	x23, x8
	dup.2d	v1, x8
	ldp	w8, w10, [sp, #136]             ; 8-byte Folded Reload
	dup.8h	v0, w10
	stp	q0, q1, [sp, #272]              ; 32-byte Folded Spill
	dup.8h	v0, w8
	str	q0, [sp, #256]                  ; 16-byte Spill
	and	x8, x20, #0x7
	stp	x8, x9, [sp, #152]              ; 16-byte Folded Spill
	ldp	x9, x8, [sp, #184]              ; 16-byte Folded Reload
	sub	x8, x9, x8
	str	x8, [sp, #144]                  ; 8-byte Spill
	and	x8, x20, #0xfffffffffffffff8
	neg	x8, x8
	str	x8, [sp, #208]                  ; 8-byte Spill
Lloh3:
	adrp	x8, lCPI1_0@PAGE
Lloh4:
	ldr	q0, [x8, lCPI1_0@PAGEOFF]
	str	q0, [sp, #240]                  ; 16-byte Spill
Lloh5:
	adrp	x25, __MergedGlobals@PAGE
Lloh6:
	add	x25, x25, __MergedGlobals@PAGEOFF
	stp	x28, x26, [sp, #216]            ; 16-byte Folded Spill
	str	x27, [sp, #232]                 ; 8-byte Spill
	str	x23, [sp, #128]                 ; 8-byte Spill
LBB1_22:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_27 Depth 2
                                        ;     Child Loop BB1_47 Depth 2
                                        ;     Child Loop BB1_56 Depth 2
                                        ;       Child Loop BB1_59 Depth 3
                                        ;     Child Loop BB1_101 Depth 2
	ldp	x9, x8, [sp, #184]              ; 16-byte Folded Reload
	cmp	x8, x9
	b.eq	LBB1_49
; %bb.23:                               ;   in Loop: Header=BB1_22 Depth=1
	ldp	d10, d9, [sp, #488]
	ldr	x10, [sp, #344]
	ldr	x11, [sp, #320]
	ldr	x8, [sp, #144]                  ; 8-byte Reload
	cmn	x8, #8
	b.ls	LBB1_25
; %bb.24:                               ;   in Loop: Header=BB1_22 Depth=1
	mov	x8, #0                          ; =0x0
	b	LBB1_45
LBB1_25:                                ;   in Loop: Header=BB1_22 Depth=1
	mov	x24, #0                         ; =0x0
	str	x11, [sp, #96]                  ; 8-byte Spill
	add	x26, x11, #3
	str	x10, [sp, #120]                 ; 8-byte Spill
	add	x20, x10, #16
	add	x27, x21, #16
	add	x28, x22, #32
	b	LBB1_27
LBB1_26:                                ;   in Loop: Header=BB1_27 Depth=2
	sub	x24, x24, #8
	add	x26, x26, #8
	str	d8, [x28, #24]
	add	x28, x28, #64
	add	x27, x27, #32
	mov	x20, x23
	ldr	x8, [sp, #208]                  ; 8-byte Reload
	cmp	x8, x24
	b.eq	LBB1_43
LBB1_27:                                ;   Parent Loop BB1_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldur	w8, [x20, #-16]
	movi.2d	v8, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB1_29
; %bb.28:                               ;   in Loop: Header=BB1_27 Depth=2
	ldurb	w9, [x26, #-3]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x27, #-16]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
LBB1_29:                                ;   in Loop: Header=BB1_27 Depth=2
	stur	d0, [x28, #-32]
	ldur	w8, [x20, #-12]
	cbz	w8, LBB1_31
; %bb.30:                               ;   in Loop: Header=BB1_27 Depth=2
	ldurb	w9, [x26, #-2]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x27, #-12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d8, d1, d0
LBB1_31:                                ;   in Loop: Header=BB1_27 Depth=2
	stur	d8, [x28, #-24]
	ldur	w8, [x20, #-8]
	movi.2d	v8, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB1_33
; %bb.32:                               ;   in Loop: Header=BB1_27 Depth=2
	ldurb	w9, [x26, #-1]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x27, #-8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
LBB1_33:                                ;   in Loop: Header=BB1_27 Depth=2
	stur	d0, [x28, #-16]
	ldur	w8, [x20, #-4]
	cbz	w8, LBB1_35
; %bb.34:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x26]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x27, #-4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d8, d1, d0
LBB1_35:                                ;   in Loop: Header=BB1_27 Depth=2
	stur	d8, [x28, #-8]
	mov	x23, x20
	ldr	w8, [x23], #32
	movi.2d	v8, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB1_37
; %bb.36:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x26, #1]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x27]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
LBB1_37:                                ;   in Loop: Header=BB1_27 Depth=2
	str	d0, [x28]
	ldr	w8, [x20, #4]
	cbz	w8, LBB1_39
; %bb.38:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x26, #2]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x27, #4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d8, d1, d0
LBB1_39:                                ;   in Loop: Header=BB1_27 Depth=2
	str	d8, [x28, #8]
	ldr	w8, [x20, #8]
	movi.2d	v8, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB1_41
; %bb.40:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x26, #3]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x27, #8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
LBB1_41:                                ;   in Loop: Header=BB1_27 Depth=2
	str	d0, [x28, #16]
	ldr	w8, [x20, #12]
	cbz	w8, LBB1_26
; %bb.42:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x26, #4]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x27, #12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d8, d1, d0
	b	LBB1_26
LBB1_43:                                ;   in Loop: Header=BB1_22 Depth=1
	ldr	x28, [sp, #216]                 ; 8-byte Reload
	ldr	x8, [sp, #152]                  ; 8-byte Reload
	cbz	x8, LBB1_49
; %bb.44:                               ;   in Loop: Header=BB1_22 Depth=1
	neg	x8, x24
	ldr	x10, [sp, #120]                 ; 8-byte Reload
	ldr	x11, [sp, #96]                  ; 8-byte Reload
LBB1_45:                                ;   in Loop: Header=BB1_22 Depth=1
	add	x20, x22, x8, lsl #3
	lsl	x9, x8, #2
	add	x23, x21, x9
	add	x24, x11, x8
	add	x26, x10, x9
	ldr	x27, [sp, #152]                 ; 8-byte Reload
	b	LBB1_47
LBB1_46:                                ;   in Loop: Header=BB1_47 Depth=2
	ldrb	w9, [x24], #1
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x23], #4
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
	str	d0, [x20], #8
	subs	x27, x27, #1
	b.eq	LBB1_49
LBB1_47:                                ;   Parent Loop BB1_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	w8, [x26], #4
	cbnz	w8, LBB1_46
; %bb.48:                               ;   in Loop: Header=BB1_47 Depth=2
	movi.2d	v0, #0000000000000000
	str	d0, [x20], #8
	add	x23, x23, #4
	add	x24, x24, #1
	subs	x27, x27, #1
	b.ne	LBB1_47
LBB1_49:                                ;   in Loop: Header=BB1_22 Depth=1
	ldr	x1, [sp, #160]                  ; 8-byte Reload
	cmp	x1, #1
	b.lt	LBB1_51
; %bb.50:                               ;   in Loop: Header=BB1_22 Depth=1
	mov	x0, x21
	bl	_bzero
LBB1_51:                                ;   in Loop: Header=BB1_22 Depth=1
	mov	x30, #0                         ; =0x0
	movi.2d	v23, #0000000000000000
	ldr	w8, [sp, #172]                  ; 4-byte Reload
	ldp	x26, x27, [sp, #224]            ; 16-byte Folded Reload
	sub	x14, x29, #184
	cbz	w8, LBB1_97
; %bb.52:                               ;   in Loop: Header=BB1_22 Depth=1
	cmp	x28, #16
	movi.16b	v21, #1
	b.lo	LBB1_97
; %bb.53:                               ;   in Loop: Header=BB1_22 Depth=1
	mov	x20, #0                         ; =0x0
	mov	w8, #3                          ; =0x3
	ldr	x9, [sp, #200]                  ; 8-byte Reload
	bfi	x8, x9, #8, #55
	dup.2d	v24, x8
	mov	w8, #4                          ; =0x4
	orr	x8, x8, x9, lsl #8
	dup.2d	v25, x8
	mov	w8, #16                         ; =0x10
	b	LBB1_56
LBB1_54:                                ;   in Loop: Header=BB1_56 Depth=2
	ldur	q0, [x29, #-208]
	movi.16b	v21, #1
	cmeq.16b	v0, v0, v21
	and.16b	v1, v5, v0
	ldp	x28, x26, [sp, #216]            ; 16-byte Folded Reload
	ldr	x27, [sp, #232]                 ; 8-byte Reload
LBB1_55:                                ;   in Loop: Header=BB1_56 Depth=2
	cmeq.16b	v2, v26, v21
	movi.16b	v22, #2
	cmeq.16b	v0, v26, v22
	movi.2d	v3, #0xffffffffffffffff
	add.16b	v3, v26, v3
	cmhi.16b	v3, v22, v3
	ushll2.8h	v4, v3, #0
	shl.8h	v4, v4, #15
	cmlt.8h	v4, v4, #0
	ushll.8h	v5, v3, #0
	shl.8h	v5, v5, #15
	cmlt.8h	v5, v5, #0
	add	x8, x26, x20, lsl #1
	ldp	q6, q7, [x8]
	saddw.8h	v16, v6, v3
	saddw2.8h	v3, v7, v3
	cmeq.8h	v17, v3, #0
	cmeq.8h	v18, v16, #0
	uzp1.16b	v19, v18, v17
	xtn.8b	v17, v17
	xtn.8b	v18, v18
	and.16b	v20, v2, v19
	and.16b	v0, v0, v19
	orr.16b	v0, v0, v1
	orr.16b	v19, v0, v20
	sub.16b	v0, v26, v19
	str	q0, [x27, x20]
	and.8b	v18, v2, v18
	bsl.16b	v5, v16, v6
	sshll.8h	v6, v18, #0
	ldp	q18, q16, [sp, #256]            ; 32-byte Folded Reload
	bit.16b	v5, v18, v6
	ushll.8h	v6, v1, #0
	shl.8h	v6, v6, #15
	cmlt.8h	v6, v6, #0
	bit.16b	v5, v16, v6
	mov	d2, v2[1]
	and.8b	v2, v2, v17
	bif.16b	v3, v7, v4
	sshll.8h	v2, v2, #0
	bsl.16b	v2, v18, v3
	ushll2.8h	v1, v1, #0
	shl.8h	v1, v1, #15
	cmlt.8h	v1, v1, #0
	bsl.16b	v1, v16, v2
	stp	q5, q1, [x8]
	cmeq.16b	v1, v26, v19
	ldr	q5, [sp, #240]                  ; 16-byte Reload
	and.16b	v1, v1, v5
	addp.16b	v1, v1, v1
	addp.16b	v1, v1, v1
	addp.16b	v1, v1, v1
	cmeq.16b	v2, v0, v21
	and.16b	v2, v2, v5
	addp.16b	v2, v2, v2
	addp.16b	v2, v2, v2
	addp.16b	v2, v2, v2
	cmeq.16b	v3, v0, v22
	and.16b	v3, v3, v5
	addp.16b	v3, v3, v3
	addp.16b	v3, v3, v3
	addp.16b	v3, v3, v3
	movi.16b	v4, #3
	cmeq.16b	v4, v0, v4
	and.16b	v4, v4, v5
	addp.16b	v4, v4, v4
	addp.16b	v4, v4, v4
	addp.16b	v4, v4, v4
	zip1.4h	v4, v3, v4
	ext.8b	v3, v3, v4, #4
	zip1.4h	v1, v1, v2
	mov.s	v1[1], v3[1]
	cnt.8b	v1, v1
	uaddlp.4h	v1, v1
	uaddw.4s	v23, v23, v1
	umov.b	w9, v0[0]
	lsl	x8, x20, #2
	ldr	x13, [sp, #312]                 ; 8-byte Reload
	ldr	w10, [x13, x8]
	ldr	w11, [x21, x10, lsl #2]
	cmp	w9, #2
	cinc	w9, w11, eq
	str	w9, [x21, x10, lsl #2]
	ldr	w9, [x19, x8]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[1]
	orr	x10, x8, #0x4
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[2]
	orr	x10, x8, #0x8
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[3]
	orr	x10, x8, #0xc
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[4]
	orr	x10, x8, #0x10
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[5]
	mov	w10, #20                        ; =0x14
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[6]
	orr	x10, x8, #0x18
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[7]
	orr	x10, x8, #0x1c
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[8]
	orr	x10, x8, #0x20
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[9]
	mov	w10, #36                        ; =0x24
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[10]
	mov	w10, #40                        ; =0x28
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[11]
	mov	w10, #44                        ; =0x2c
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[12]
	orr	x10, x8, #0x30
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[13]
	mov	w10, #52                        ; =0x34
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[14]
	orr	x10, x8, #0x38
	ldr	w11, [x13, x10]
	ldr	w12, [x21, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x21, x11, lsl #2]
	ldr	w9, [x19, x10]
	ldr	w10, [x21, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x21, x9, lsl #2]
	umov.b	w9, v0[15]
	orr	x8, x8, #0x3c
	ldr	w10, [x13, x8]
	ldr	w11, [x21, x10, lsl #2]
	cmp	w9, #2
	cinc	w9, w11, eq
	str	w9, [x21, x10, lsl #2]
	ldr	w8, [x19, x8]
	ldr	w9, [x21, x8, lsl #2]
	cinc	w9, w9, eq
	str	w9, [x21, x8, lsl #2]
	add	x8, x30, #16
	mov	x20, x30
	cmp	x8, x28
	b.hi	LBB1_97
LBB1_56:                                ;   Parent Loop BB1_22 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB1_59 Depth 3
	ldr	q26, [x27, x20]
	cmeq.16b	v5, v26, #0
	and.16b	v0, v5, v21
	sturb	wzr, [x29, #-184]
	umov.b	w9, v0[0]
	umov.b	w10, v0[0]
	mov	w11, #1                         ; =0x1
	strb	w11, [x14, x10]
	umov.b	w10, v0[1]
	umov.b	w11, v0[2]
	add	w9, w9, w10
	add	w10, w9, w11
	and	x9, x9, #0x3
	mov	w11, #2                         ; =0x2
	strb	w11, [x14, x9]
	and	x9, x10, #0x7
	mov	w11, #3                         ; =0x3
	strb	w11, [x14, x9]
	umov.b	w9, v0[3]
	umov.b	w11, v0[4]
	add	w9, w10, w9
	add	w10, w9, w11
	and	x9, x9, #0xff
	mov	w11, #4                         ; =0x4
	strb	w11, [x14, x9]
	and	x9, x10, #0xff
	mov	w11, #5                         ; =0x5
	strb	w11, [x14, x9]
	umov.b	w9, v0[5]
	add	w9, w10, w9
	and	x9, x9, #0xff
	mov	w10, #6                         ; =0x6
	strb	w10, [x14, x9]
	umov.b	w10, v5[6]
	and	x10, x10, #0x1
	umov.b	w11, v5[7]
	and	x11, x11, #0x1
	add	x9, x9, x10
	add	x10, x9, x11
	mov	w11, #7                         ; =0x7
	strb	w11, [x14, x9]
	mov	w9, #8                          ; =0x8
	strb	w9, [x14, x10]
	umov.b	w9, v5[8]
	and	x9, x9, #0x1
	umov.b	w11, v5[9]
	and	x11, x11, #0x1
	add	x9, x10, x9
	add	x10, x9, x11
	mov	w11, #9                         ; =0x9
	strb	w11, [x14, x9]
	mov	w9, #10                         ; =0xa
	strb	w9, [x14, x10]
	umov.b	w9, v5[10]
	and	x9, x9, #0x1
	umov.b	w11, v5[11]
	and	x11, x11, #0x1
	add	x9, x10, x9
	add	x10, x9, x11
	mov	w11, #11                        ; =0xb
	strb	w11, [x14, x9]
	mov	w9, #12                         ; =0xc
	strb	w9, [x14, x10]
	umov.b	w9, v5[12]
	and	x9, x9, #0x1
	add	x9, x9, w10, uxtw
	mov	w10, #13                        ; =0xd
	strb	w10, [x14, x9]
	umov.b	w10, v5[13]
	and	x10, x10, #0x1
	add	x9, x10, w9, uxtw
	mov	w10, #14                        ; =0xe
	strb	w10, [x14, x9]
	umov.b	w10, v5[14]
	mov	x30, x8
	and	x8, x10, #0x1
	add	x8, x8, w9, uxtw
	mov	w9, #15                         ; =0xf
	strb	w9, [x14, x8]
	stp	xzr, xzr, [x29, #-208]
	umov.b	w9, v5[15]
	and	x9, x9, #0x1
	add	x23, x9, w8, uxtw
	movi.2d	v1, #0000000000000000
	cbz	w23, LBB1_55
; %bb.57:                               ;   in Loop: Header=BB1_56 Depth=2
	mov	x26, #0                         ; =0x0
	add	x8, x14, x23
	ldurb	w9, [x8, #-1]
	strb	w9, [x8]
	b	LBB1_59
LBB1_58:                                ;   in Loop: Header=BB1_59 Depth=3
	add	x26, x26, #2
	cmp	x26, x23
	b.hs	LBB1_54
LBB1_59:                                ;   Parent Loop BB1_22 Depth=1
                                        ;     Parent Loop BB1_56 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	add	x27, x14, x26
	ldrb	w24, [x27]
	ldrb	w28, [x27, #1]
Lloh7:
	adrp	x8, __MergedGlobals@PAGE+8
Lloh8:
	add	x8, x8, __MergedGlobals@PAGEOFF+8
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_73
LBB1_60:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh9:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh10:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	ldaprb	w8, [x9]
	tbz	w8, #0, LBB1_75
LBB1_61:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh11:
	adrp	x8, __MergedGlobals@PAGE+40
Lloh12:
	add	x8, x8, __MergedGlobals@PAGEOFF+40
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_77
LBB1_62:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh13:
	adrp	x8, __MergedGlobals@PAGE+56
Lloh14:
	add	x8, x8, __MergedGlobals@PAGEOFF+56
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_79
LBB1_63:                                ;   in Loop: Header=BB1_59 Depth=3
	ldr	d11, [x25]
	ldr	d12, [x25, #16]
	ldr	d9, [x25, #32]
	ldr	d10, [x25, #48]
	ldapurb	w8, [x25, #8]
	tbz	w8, #0, LBB1_81
LBB1_64:                                ;   in Loop: Header=BB1_59 Depth=3
	ldaprb	w8, [x9]
	tbz	w8, #0, LBB1_83
LBB1_65:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh15:
	adrp	x8, __MergedGlobals@PAGE+40
Lloh16:
	add	x8, x8, __MergedGlobals@PAGEOFF+40
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_85
LBB1_66:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh17:
	adrp	x8, __MergedGlobals@PAGE+56
Lloh18:
	add	x8, x8, __MergedGlobals@PAGEOFF+56
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_87
LBB1_67:                                ;   in Loop: Header=BB1_59 Depth=3
	ldr	d15, [x25]
	ldr	d8, [x25, #16]
	ldr	d13, [x25, #32]
	ldr	d14, [x25, #48]
	ldapurb	w8, [x25, #8]
	tbz	w8, #0, LBB1_89
LBB1_68:                                ;   in Loop: Header=BB1_59 Depth=3
	ldaprb	w8, [x9]
	tbz	w8, #0, LBB1_91
LBB1_69:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh19:
	adrp	x8, __MergedGlobals@PAGE+40
Lloh20:
	add	x8, x8, __MergedGlobals@PAGEOFF+40
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_93
LBB1_70:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh21:
	adrp	x8, __MergedGlobals@PAGE+56
Lloh22:
	add	x8, x8, __MergedGlobals@PAGEOFF+56
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_95
LBB1_71:                                ;   in Loop: Header=BB1_59 Depth=3
	add	x8, x26, #1
	add	x9, x20, x24
	mov	w10, w9
	fmov	d0, x10
	add	x10, x20, x28
	mov	w11, w10
	mov.d	v0[1], x11
	ldr	q1, [sp, #288]                  ; 16-byte Reload
	eor.16b	v0, v0, v1
	mov	x11, #31765                     ; =0x7c15
	movk	x11, #32586, lsl #16
	movk	x11, #31161, lsl #32
	movk	x11, #40503, lsl #48
	dup.2d	v1, x11
	add.2d	v0, v0, v1
	ushr.2d	v2, v0, #30
	eor.16b	v0, v2, v0
	xtn.2s	v2, v0
	shrn.2s	v0, v0, #32
	umull.2d	v3, v2, v12
	umlal.2d	v3, v0, v11
	shl.2d	v0, v3, #32
	umlal.2d	v0, v2, v11
	ushr.2d	v2, v0, #27
	eor.16b	v0, v2, v0
	xtn.2s	v2, v0
	shrn.2s	v0, v0, #32
	umull.2d	v3, v2, v10
	umlal.2d	v3, v0, v9
	shl.2d	v0, v3, #32
	umlal.2d	v0, v2, v9
	ushr.2d	v2, v0, #31
	eor.16b	v3, v2, v0
	eor3.16b	v0, v2, v0, v24
	add.2d	v0, v0, v1
	ushr.2d	v2, v0, #30
	eor.16b	v0, v2, v0
	xtn.2s	v2, v0
	shrn.2s	v0, v0, #32
	umull.2d	v4, v2, v8
	umlal.2d	v4, v0, v15
	shl.2d	v0, v4, #32
	umlal.2d	v0, v2, v15
	ushr.2d	v2, v0, #27
	eor.16b	v0, v2, v0
	xtn.2s	v2, v0
	shrn.2s	v0, v0, #32
	umull.2d	v4, v2, v14
	umlal.2d	v4, v0, v13
	shl.2d	v0, v4, #32
	umlal.2d	v0, v2, v13
	eor.16b	v2, v3, v25
	add.2d	v1, v2, v1
	ushr.2d	v2, v1, #30
	eor.16b	v1, v2, v1
	ldr	d2, [x25]
	ldr	d3, [x25, #16]
	xtn.2s	v4, v1
	shrn.2s	v1, v1, #32
	umull.2d	v3, v4, v3
	umlal.2d	v3, v1, v2
	shl.2d	v1, v3, #32
	umlal.2d	v1, v4, v2
	ushr.2d	v2, v1, #27
	eor.16b	v1, v2, v1
	ldr	d2, [x25, #32]
	ldr	d3, [x25, #48]
	xtn.2s	v4, v1
	shrn.2s	v1, v1, #32
	umull.2d	v3, v4, v3
	umlal.2d	v3, v1, v2
	shl.2d	v1, v3, #32
	ldr	x12, [sp, #312]                 ; 8-byte Reload
	ldr	w11, [x12, x9, lsl #2]
	umlal.2d	v1, v4, v2
	ldr	w12, [x12, x10, lsl #2]
	add	x12, x22, x12, lsl #3
	ldr	d2, [x22, x11, lsl #3]
	ld1.d	{ v2 }[1], [x12]
	ldr	w9, [x19, x9, lsl #2]
	ldr	w10, [x19, x10, lsl #2]
	add	x10, x22, x10, lsl #3
	ldr	d3, [x22, x9, lsl #3]
	ld1.d	{ v3 }[1], [x10]
	ushr.2d	v4, v0, #42
	ushr.2d	v0, v0, #11
	eor.16b	v0, v4, v0
	ucvtf.2d	v0, v0, #53
	fcmgt.2d	v0, v2, v0
	ushr.2d	v2, v1, #42
	ushr.2d	v1, v1, #11
	eor.16b	v1, v2, v1
	ucvtf.2d	v1, v1, #53
	fcmgt.2d	v1, v3, v1
	orr.16b	v0, v0, v1
	umov.b	w9, v0[0]
	and	w9, w9, #0x1
	sub	x14, x29, #184
	ldrb	w10, [x14, x26]
	sub	x11, x29, #208
	strb	w9, [x11, x10]
	cmp	x8, x23
	b.hs	LBB1_58
; %bb.72:                               ;   in Loop: Header=BB1_59 Depth=3
	umov.b	w8, v0[8]
	and	w8, w8, #0x1
	ldrb	w9, [x27, #1]
	sub	x10, x29, #208
	strb	w8, [x10, x9]
	b	LBB1_58
LBB1_73:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh23:
	adrp	x0, __MergedGlobals@PAGE+8
Lloh24:
	add	x0, x0, __MergedGlobals@PAGEOFF+8
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
	cbz	w0, LBB1_60
; %bb.74:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #58809                      ; =0xe5b9
	movk	w8, #7396, lsl #16
	dup.2s	v0, w8
	mov	x0, x25
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
	b	LBB1_60
LBB1_75:                                ;   in Loop: Header=BB1_59 Depth=3
	mov	x0, x9
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh25:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh26:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	cbz	w0, LBB1_61
; %bb.76:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #18285                      ; =0x476d
	movk	w8, #48984, lsl #16
	dup.2s	v0, w8
Lloh27:
	adrp	x0, __MergedGlobals@PAGE+16
Lloh28:
	add	x0, x0, __MergedGlobals@PAGEOFF+16
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh29:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh30:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	b	LBB1_61
LBB1_77:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh31:
	adrp	x0, __MergedGlobals@PAGE+40
Lloh32:
	add	x0, x0, __MergedGlobals@PAGEOFF+40
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh33:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh34:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	cbz	w0, LBB1_62
; %bb.78:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #4587                       ; =0x11eb
	movk	w8, #4913, lsl #16
	dup.2s	v0, w8
Lloh35:
	adrp	x0, __MergedGlobals@PAGE+32
Lloh36:
	add	x0, x0, __MergedGlobals@PAGEOFF+32
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh37:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh38:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	b	LBB1_62
LBB1_79:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh39:
	adrp	x0, __MergedGlobals@PAGE+56
Lloh40:
	add	x0, x0, __MergedGlobals@PAGEOFF+56
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh41:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh42:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	cbz	w0, LBB1_63
; %bb.80:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #18875                      ; =0x49bb
	movk	w8, #38096, lsl #16
	dup.2s	v0, w8
Lloh43:
	adrp	x0, __MergedGlobals@PAGE+48
Lloh44:
	add	x0, x0, __MergedGlobals@PAGEOFF+48
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh45:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh46:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	b	LBB1_63
LBB1_81:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh47:
	adrp	x0, __MergedGlobals@PAGE+8
Lloh48:
	add	x0, x0, __MergedGlobals@PAGEOFF+8
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh49:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh50:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	cbz	w0, LBB1_64
; %bb.82:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #58809                      ; =0xe5b9
	movk	w8, #7396, lsl #16
	dup.2s	v0, w8
	mov	x0, x25
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh51:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh52:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	b	LBB1_64
LBB1_83:                                ;   in Loop: Header=BB1_59 Depth=3
	mov	x0, x9
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh53:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh54:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	cbz	w0, LBB1_65
; %bb.84:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #18285                      ; =0x476d
	movk	w8, #48984, lsl #16
	dup.2s	v0, w8
Lloh55:
	adrp	x0, __MergedGlobals@PAGE+16
Lloh56:
	add	x0, x0, __MergedGlobals@PAGEOFF+16
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh57:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh58:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	b	LBB1_65
LBB1_85:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh59:
	adrp	x0, __MergedGlobals@PAGE+40
Lloh60:
	add	x0, x0, __MergedGlobals@PAGEOFF+40
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh61:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh62:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	cbz	w0, LBB1_66
; %bb.86:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #4587                       ; =0x11eb
	movk	w8, #4913, lsl #16
	dup.2s	v0, w8
Lloh63:
	adrp	x0, __MergedGlobals@PAGE+32
Lloh64:
	add	x0, x0, __MergedGlobals@PAGEOFF+32
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh65:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh66:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	b	LBB1_66
LBB1_87:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh67:
	adrp	x0, __MergedGlobals@PAGE+56
Lloh68:
	add	x0, x0, __MergedGlobals@PAGEOFF+56
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh69:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh70:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	cbz	w0, LBB1_67
; %bb.88:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #18875                      ; =0x49bb
	movk	w8, #38096, lsl #16
	dup.2s	v0, w8
Lloh71:
	adrp	x0, __MergedGlobals@PAGE+48
Lloh72:
	add	x0, x0, __MergedGlobals@PAGEOFF+48
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh73:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh74:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	b	LBB1_67
LBB1_89:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh75:
	adrp	x0, __MergedGlobals@PAGE+8
Lloh76:
	add	x0, x0, __MergedGlobals@PAGEOFF+8
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh77:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh78:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	cbz	w0, LBB1_68
; %bb.90:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #58809                      ; =0xe5b9
	movk	w8, #7396, lsl #16
	dup.2s	v0, w8
	mov	x0, x25
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
Lloh79:
	adrp	x9, __MergedGlobals@PAGE+24
Lloh80:
	add	x9, x9, __MergedGlobals@PAGEOFF+24
	b	LBB1_68
LBB1_91:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh81:
	adrp	x0, __MergedGlobals@PAGE+24
Lloh82:
	add	x0, x0, __MergedGlobals@PAGEOFF+24
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
	cbz	w0, LBB1_69
; %bb.92:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #18285                      ; =0x476d
	movk	w8, #48984, lsl #16
	dup.2s	v0, w8
Lloh83:
	adrp	x0, __MergedGlobals@PAGE+16
Lloh84:
	add	x0, x0, __MergedGlobals@PAGEOFF+16
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
	b	LBB1_69
LBB1_93:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh85:
	adrp	x0, __MergedGlobals@PAGE+40
Lloh86:
	add	x0, x0, __MergedGlobals@PAGEOFF+40
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
	cbz	w0, LBB1_70
; %bb.94:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #4587                       ; =0x11eb
	movk	w8, #4913, lsl #16
	dup.2s	v0, w8
Lloh87:
	adrp	x0, __MergedGlobals@PAGE+32
Lloh88:
	add	x0, x0, __MergedGlobals@PAGEOFF+32
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
	b	LBB1_70
LBB1_95:                                ;   in Loop: Header=BB1_59 Depth=3
Lloh89:
	adrp	x0, __MergedGlobals@PAGE+56
Lloh90:
	add	x0, x0, __MergedGlobals@PAGEOFF+56
	str	x30, [sp, #120]                 ; 8-byte Spill
	str	q23, [sp, #96]                  ; 16-byte Spill
	stp	q25, q24, [sp, #32]             ; 32-byte Folded Spill
	stp	q5, q26, [sp]                   ; 32-byte Folded Spill
	bl	___cxa_guard_acquire
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
	cbz	w0, LBB1_71
; %bb.96:                               ;   in Loop: Header=BB1_59 Depth=3
	mov	w8, #18875                      ; =0x49bb
	movk	w8, #38096, lsl #16
	dup.2s	v0, w8
Lloh91:
	adrp	x0, __MergedGlobals@PAGE+48
Lloh92:
	add	x0, x0, __MergedGlobals@PAGEOFF+48
	str	d0, [x0], #8
	bl	___cxa_guard_release
	ldp	q5, q26, [sp]                   ; 32-byte Folded Reload
	ldp	q25, q24, [sp, #32]             ; 32-byte Folded Reload
	ldr	q23, [sp, #96]                  ; 16-byte Reload
	ldr	x30, [sp, #120]                 ; 8-byte Reload
	b	LBB1_71
LBB1_97:                                ;   in Loop: Header=BB1_22 Depth=1
	mov.s	w8, v23[1]
	fmov	w9, s23
	mov.s	w10, v23[2]
	mov.s	w11, v23[3]
	cmp	x30, x28
	b.hs	LBB1_104
; %bb.98:                               ;   in Loop: Header=BB1_22 Depth=1
	mov	w12, #3                         ; =0x3
	ldr	x13, [sp, #200]                 ; 8-byte Reload
	bfi	x12, x13, #8, #55
	mov	w14, #4                         ; =0x4
	orr	x13, x14, x13, lsl #8
	ldr	x20, [sp, #176]                 ; 8-byte Reload
	ldp	w4, w3, [sp, #136]              ; 8-byte Folded Reload
	mov	x5, #58809                      ; =0xe5b9
	movk	x5, #7396, lsl #16
	movk	x5, #18285, lsl #32
	movk	x5, #48984, lsl #48
	mov	x7, #4587                       ; =0x11eb
	movk	x7, #4913, lsl #16
	movk	x7, #18875, lsl #32
	movk	x7, #38096, lsl #48
	ldr	x23, [sp, #128]                 ; 8-byte Reload
	b	LBB1_101
LBB1_99:                                ;   in Loop: Header=BB1_101 Depth=2
	cmp	w16, #3
	sbc	w0, w17, wzr
	csel	w17, w0, w17, lo
	cset	w1, lo
	tst	w0, #0xffff
	csel	w1, wzr, w1, ne
	cmp	w16, #1
	and	w0, w0, #0xffff
	ccmp	w0, #0, #0, eq
	csel	w17, w4, w17, eq
	csinc	w0, w1, wzr, ne
LBB1_100:                               ;   in Loop: Header=BB1_101 Depth=2
	add	w16, w16, w0
	strb	w16, [x27, x30]
	strh	w17, [x26, x30, lsl #1]
	ands	w16, w16, #0xff
	cinc	w9, w9, eq
	cmp	w16, #1
	cinc	w8, w8, eq
	cmp	w16, #3
	cinc	w11, w11, eq
	ldr	w17, [x21, x15, lsl #2]
	cmp	w16, #2
	cinc	w16, w17, eq
	str	w16, [x21, x15, lsl #2]
	ldr	w15, [x21, x14, lsl #2]
	cinc	w10, w10, eq
	cinc	w15, w15, eq
	str	w15, [x21, x14, lsl #2]
	add	x30, x30, #1
	cmp	x30, x28
	b.hs	LBB1_105
LBB1_101:                               ;   Parent Loop BB1_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w16, [x27, x30]
	ldrh	w17, [x26, x30, lsl #1]
	ldr	x14, [sp, #312]                 ; 8-byte Reload
	ldr	w15, [x14, x30, lsl #2]
	ldr	w14, [x19, x30, lsl #2]
	cbnz	w16, LBB1_99
; %bb.102:                              ;   in Loop: Header=BB1_101 Depth=2
	mov	w0, w30
	eor	x0, x0, x23
	mov	x6, #31765                      ; =0x7c15
	movk	x6, #32586, lsl #16
	movk	x6, #31161, lsl #32
	movk	x6, #40503, lsl #48
	add	x0, x0, x6
	eor	x0, x0, x0, lsr #30
	mul	x0, x0, x5
	eor	x0, x0, x0, lsr #27
	mul	x0, x0, x7
	eor	x0, x0, x0, lsr #31
	eor	x1, x0, x12
	add	x1, x1, x6
	eor	x1, x1, x1, lsr #30
	mul	x1, x1, x5
	eor	x1, x1, x1, lsr #27
	mul	x1, x1, x7
	lsr	x2, x1, #42
	eor	x1, x2, x1, lsr #11
	ucvtf	d0, x1, #53
	eor	x0, x0, x13
	add	x0, x0, x6
	eor	x0, x0, x0, lsr #30
	mul	x0, x0, x5
	eor	x0, x0, x0, lsr #27
	mul	x0, x0, x7
	lsr	x1, x0, #42
	eor	x0, x1, x0, lsr #11
	ucvtf	d1, x0, #53
	ldr	d2, [x22, x15, lsl #3]
	fcmp	d0, d2
	cset	w0, mi
	ldr	d0, [x22, x14, lsl #3]
	fcmp	d1, d0
	csinc	w0, w0, wzr, pl
	.p2align	6, , 4
; %bb.103:                              ;   in Loop: Header=BB1_101 Depth=2
	cmp	w0, #0
	csel	w17, w3, w17, ne
	b	LBB1_100
LBB1_104:                               ;   in Loop: Header=BB1_22 Depth=1
	ldr	x20, [sp, #176]                 ; 8-byte Reload
LBB1_105:                               ;   in Loop: Header=BB1_22 Depth=1
	stp	w9, w8, [x29, #-208]
	stp	w10, w11, [x29, #-200]
	ldp	x8, x9, [x20, #8]
	stur	x8, [x29, #-216]
	sub	x10, x29, #216
	stur	x10, [x29, #-184]
	sub	x10, x29, #208
	stp	x10, x20, [x29, #-176]
	cmp	x8, x9
	b.eq	LBB1_108
; %bb.106:                              ;   in Loop: Header=BB1_22 Depth=1
	ldur	q0, [x29, #-208]
	str	q0, [x8], #16
LBB1_107:                               ;   in Loop: Header=BB1_22 Depth=1
	str	x8, [x20, #8]
	ldr	x9, [sp, #200]                  ; 8-byte Reload
	add	x9, x9, #1
	ldr	w8, [sp, #476]
	str	x9, [sp, #200]                  ; 8-byte Spill
	cmp	x9, x8
	b.lo	LBB1_22
	b	LBB1_110
LBB1_108:                               ;   in Loop: Header=BB1_22 Depth=1
Ltmp20:                                 ; EH_LABEL
	sub	x0, x29, #184
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backB9nqe230105IJS1_EEERS1_DpOT_ENKUlvE0_clB9nqe230105Ev
Ltmp21:                                 ; EH_LABEL
; %bb.109:                              ;   in Loop: Header=BB1_22 Depth=1
	ldur	x8, [x29, #-216]
	b	LBB1_107
LBB1_110:
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	ldr	x8, [sp, #88]                   ; 8-byte Reload
	sub	x8, x0, x8
	scvtf	d0, x8
	mov	x8, #225833675390976            ; =0xcd6500000000
	movk	x8, #16845, lsl #48
	fmov	d1, x8
	fdiv	d0, d0, d1
	ldr	x8, [sp, #176]                  ; 8-byte Reload
	str	d0, [x8, #24]
	cbz	x22, LBB1_112
; %bb.111:
	ldr	x8, [sp, #72]                   ; 8-byte Reload
	sub	x1, x8, x22
	mov	x0, x22
	bl	__ZdlPvm
LBB1_112:
	cbz	x21, LBB1_114
; %bb.113:
	ldr	x8, [sp, #80]                   ; 8-byte Reload
	sub	x1, x8, x21
	mov	x0, x21
	bl	__ZdlPvm
LBB1_114:
	ldr	x0, [sp, #344]
	cbz	x0, LBB1_116
; %bb.115:
	str	x0, [sp, #352]
	ldr	x8, [sp, #360]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB1_116:
	ldr	x0, [sp, #320]
	cbz	x0, LBB1_118
; %bb.117:
	str	x0, [sp, #328]
	ldr	x8, [sp, #336]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB1_118:
	ldr	x0, [sp, #440]
	cbz	x0, LBB1_120
; %bb.119:
	str	x0, [sp, #448]
	ldr	x8, [sp, #456]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB1_120:
	ldr	x0, [sp, #416]
	cbz	x0, LBB1_122
; %bb.121:
	str	x0, [sp, #424]
	ldr	x8, [sp, #432]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB1_122:
	ldr	x0, [sp, #392]
	cbz	x0, LBB1_124
; %bb.123:
	str	x0, [sp, #400]
	ldr	x8, [sp, #408]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB1_124:
	ldr	x0, [sp, #368]
	cbz	x0, LBB1_126
; %bb.125:
	str	x0, [sp, #376]
	ldr	x8, [sp, #384]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB1_126:
	ldur	x8, [x29, #-160]
Lloh93:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh94:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh95:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB1_128
; %bb.127:
	add	sp, sp, #592
	ldp	x29, x30, [sp, #144]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #128]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #112]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #96]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #80]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #64]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #48]               ; 16-byte Folded Reload
	ldp	d11, d10, [sp, #32]             ; 16-byte Folded Reload
	ldp	d13, d12, [sp, #16]             ; 16-byte Folded Reload
	ldp	d15, d14, [sp], #160            ; 16-byte Folded Reload
	ret
LBB1_128:
	bl	___stack_chk_fail
LBB1_129:
Ltmp17:                                 ; EH_LABEL
	bl	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe230105Ev
Ltmp18:                                 ; EH_LABEL
	b	LBB1_131
LBB1_130:
Ltmp14:                                 ; EH_LABEL
	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe230105Ev
Ltmp15:                                 ; EH_LABEL
LBB1_131:
	brk	#0x1
LBB1_132:
Ltmp22:                                 ; EH_LABEL
	mov	x20, x0
	cbnz	x22, LBB1_136
; %bb.133:
	cbnz	x21, LBB1_139
LBB1_134:
	ldr	x8, [sp, #176]                  ; 8-byte Reload
	ldr	x0, [x8]
	cbnz	x0, LBB1_141
LBB1_135:
	add	x0, sp, #320
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #368
	bl	__ZN10PopulationD1Ev
	mov	x0, x20
	bl	__Unwind_Resume
LBB1_136:
	ldr	x8, [sp, #72]                   ; 8-byte Reload
	sub	x1, x8, x22
	mov	x0, x22
	bl	__ZdlPvm
	cbz	x21, LBB1_134
	b	LBB1_139
LBB1_137:
Ltmp9:                                  ; EH_LABEL
	mov	x20, x0
	ldr	x8, [sp, #176]                  ; 8-byte Reload
	ldr	x0, [x8]
	cbz	x0, LBB1_135
	b	LBB1_141
LBB1_138:
Ltmp16:                                 ; EH_LABEL
	mov	x20, x0
LBB1_139:
	ldr	x8, [sp, #80]                   ; 8-byte Reload
	sub	x1, x8, x21
	mov	x0, x21
	bl	__ZdlPvm
	ldr	x8, [sp, #176]                  ; 8-byte Reload
	ldr	x0, [x8]
	cbz	x0, LBB1_135
	b	LBB1_141
LBB1_140:
Ltmp19:                                 ; EH_LABEL
	mov	x20, x0
	ldr	x8, [sp, #176]                  ; 8-byte Reload
	ldr	x0, [x8]
	cbz	x0, LBB1_135
LBB1_141:
	ldr	x8, [sp, #176]                  ; 8-byte Reload
	str	x0, [x8, #8]
	ldr	x8, [x8, #16]
	sub	x1, x8, x0
	bl	__ZdlPvm
	add	x0, sp, #320
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #368
	bl	__ZN10PopulationD1Ev
	mov	x0, x20
	bl	__Unwind_Resume
LBB1_142:
Ltmp4:                                  ; EH_LABEL
	mov	x20, x0
	add	x0, sp, #320
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #368
	bl	__ZN10PopulationD1Ev
	mov	x0, x20
	bl	__Unwind_Resume
	.loh AdrpLdrGotLdr	Lloh0, Lloh1, Lloh2
	.loh AdrpAdd	Lloh5, Lloh6
	.loh AdrpLdr	Lloh3, Lloh4
	.loh AdrpAdd	Lloh7, Lloh8
	.loh AdrpAdd	Lloh9, Lloh10
	.loh AdrpAdd	Lloh11, Lloh12
	.loh AdrpAdd	Lloh13, Lloh14
	.loh AdrpAdd	Lloh15, Lloh16
	.loh AdrpAdd	Lloh17, Lloh18
	.loh AdrpAdd	Lloh19, Lloh20
	.loh AdrpAdd	Lloh21, Lloh22
	.loh AdrpAdd	Lloh23, Lloh24
	.loh AdrpAdd	Lloh25, Lloh26
	.loh AdrpAdd	Lloh29, Lloh30
	.loh AdrpAdd	Lloh27, Lloh28
	.loh AdrpAdd	Lloh33, Lloh34
	.loh AdrpAdd	Lloh31, Lloh32
	.loh AdrpAdd	Lloh37, Lloh38
	.loh AdrpAdd	Lloh35, Lloh36
	.loh AdrpAdd	Lloh41, Lloh42
	.loh AdrpAdd	Lloh39, Lloh40
	.loh AdrpAdd	Lloh45, Lloh46
	.loh AdrpAdd	Lloh43, Lloh44
	.loh AdrpAdd	Lloh49, Lloh50
	.loh AdrpAdd	Lloh47, Lloh48
	.loh AdrpAdd	Lloh51, Lloh52
	.loh AdrpAdd	Lloh53, Lloh54
	.loh AdrpAdd	Lloh57, Lloh58
	.loh AdrpAdd	Lloh55, Lloh56
	.loh AdrpAdd	Lloh61, Lloh62
	.loh AdrpAdd	Lloh59, Lloh60
	.loh AdrpAdd	Lloh65, Lloh66
	.loh AdrpAdd	Lloh63, Lloh64
	.loh AdrpAdd	Lloh69, Lloh70
	.loh AdrpAdd	Lloh67, Lloh68
	.loh AdrpAdd	Lloh73, Lloh74
	.loh AdrpAdd	Lloh71, Lloh72
	.loh AdrpAdd	Lloh77, Lloh78
	.loh AdrpAdd	Lloh75, Lloh76
	.loh AdrpAdd	Lloh79, Lloh80
	.loh AdrpAdd	Lloh81, Lloh82
	.loh AdrpAdd	Lloh83, Lloh84
	.loh AdrpAdd	Lloh85, Lloh86
	.loh AdrpAdd	Lloh87, Lloh88
	.loh AdrpAdd	Lloh89, Lloh90
	.loh AdrpAdd	Lloh91, Lloh92
	.loh AdrpLdrGotLdr	Lloh93, Lloh94, Lloh95
Lfunc_end0:
	.cfi_endproc
	.section	__TEXT,__gcc_except_tab
	.p2align	2, 0x0
GCC_except_table1:
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
	cbz	x0, LBB2_2
; %bb.1:
	str	x0, [x19, #32]
	ldr	x8, [x19, #40]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB2_2:
	ldr	x0, [x19]
	cbz	x0, LBB2_4
; %bb.3:
	str	x0, [x19, #8]
	ldr	x8, [x19, #16]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB2_4:
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
	cbz	x0, LBB3_2
; %bb.1:
	str	x0, [x19, #80]
	ldr	x8, [x19, #88]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB3_2:
	ldr	x0, [x19, #48]
	cbz	x0, LBB3_4
; %bb.3:
	str	x0, [x19, #56]
	ldr	x8, [x19, #64]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB3_4:
	ldr	x0, [x19, #24]
	cbz	x0, LBB3_6
; %bb.5:
	str	x0, [x19, #32]
	ldr	x8, [x19, #40]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB3_6:
	ldr	x0, [x19]
	cbz	x0, LBB3_8
; %bb.7:
	str	x0, [x19, #8]
	ldr	x8, [x19, #16]
	sub	x1, x8, x0
	bl	__ZdlPvm
LBB3_8:
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
	cbnz	x9, LBB4_5
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
	cbnz	x9, LBB4_6
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
	cbz	x20, LBB4_4
; %bb.3:
	mov	x0, x20
	mov	x1, x22
	bl	__ZdlPvm
LBB4_4:
	ldr	x8, [x19]
	str	x26, [x8]
	ldp	x29, x30, [sp, #80]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #64]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #48]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #32]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #16]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp], #96             ; 16-byte Folded Reload
	ret
LBB4_5:
	bl	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe230105Ev
LBB4_6:
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
Lloh96:
	adrp	x0, l_.str@PAGE
Lloh97:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.loh AdrpAdd	Lloh96, Lloh97
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
Lloh98:
	adrp	x1, __ZTISt12length_error@GOTPAGE
Lloh99:
	ldr	x1, [x1, __ZTISt12length_error@GOTPAGEOFF]
Lloh100:
	adrp	x2, __ZNSt12length_errorD1Ev@GOTPAGE
Lloh101:
	ldr	x2, [x2, __ZNSt12length_errorD1Ev@GOTPAGEOFF]
	mov	x0, x19
	bl	___cxa_throw
LBB6_2:
Ltmp25:                                 ; EH_LABEL
	mov	x20, x0
	mov	x0, x19
	bl	___cxa_free_exception
	mov	x0, x20
	bl	__Unwind_Resume
	.loh AdrpLdrGot	Lloh100, Lloh101
	.loh AdrpLdrGot	Lloh98, Lloh99
Lfunc_end1:
	.cfi_endproc
	.section	__TEXT,__gcc_except_tab
	.p2align	2, 0x0
GCC_except_table6:
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
Lloh102:
	adrp	x8, __ZTVSt12length_error@GOTPAGE
Lloh103:
	ldr	x8, [x8, __ZTVSt12length_error@GOTPAGEOFF]
	add	x8, x8, #16
	str	x8, [x0]
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.loh AdrpLdrGot	Lloh102, Lloh103
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
Lloh104:
	adrp	x1, __ZTISt20bad_array_new_length@GOTPAGE
Lloh105:
	ldr	x1, [x1, __ZTISt20bad_array_new_length@GOTPAGEOFF]
Lloh106:
	adrp	x2, __ZNSt20bad_array_new_lengthD1Ev@GOTPAGE
Lloh107:
	ldr	x2, [x2, __ZNSt20bad_array_new_lengthD1Ev@GOTPAGEOFF]
	bl	___cxa_throw
	.loh AdrpLdrGot	Lloh106, Lloh107
	.loh AdrpLdrGot	Lloh104, Lloh105
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
Lloh108:
	adrp	x0, l_.str@PAGE
Lloh109:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.loh AdrpAdd	Lloh108, Lloh109
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
Lloh110:
	adrp	x0, l_.str@PAGE
Lloh111:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe230105EPKc
	.loh AdrpAdd	Lloh110, Lloh111
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"vector"

.zerofill __DATA,__bss,__MergedGlobals,64,3 ; @_MergedGlobals
.subsections_via_symbols
