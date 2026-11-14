	.build_version macos, 26, 0	sdk_version 27, 0
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
	.p2align	2
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
	sub	sp, sp, #576
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
	mov	x28, x1
Lloh0:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh1:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh2:
	ldr	x9, [x9]
	stur	x9, [x29, #-160]
	ldp	q1, q0, [x0, #16]
	stp	q1, q0, [sp, #464]
	ldr	q0, [x0]
	str	q0, [sp, #448]
	ldrh	w9, [sp, #492]
	cbz	w9, LBB1_12
; %bb.1:
	ldrh	w9, [sp, #494]
	cbz	w9, LBB1_13
LBB1_2:
	str	x8, [sp, #96]                   ; 8-byte Folded Spill
	movi.2d	v0, #0000000000000000
	stp	q0, q0, [sp, #416]
	stp	q0, q0, [sp, #384]
	stp	q0, q0, [sp, #352]
	stp	q0, q0, [sp, #320]
	str	q0, [sp, #304]
Ltmp0:
	add	x0, sp, #448
	add	x1, sp, #352
	add	x2, sp, #304
	bl	__Z18generate_syntheticRK6ParamsR10PopulationR9Locations
Ltmp1:
; %bb.3:
Ltmp2:
	add	x0, sp, #448
	add	x1, sp, #352
	bl	__Z15seed_infectionsRK6ParamsR10Population
Ltmp3:
; %bb.4:
	ldp	x26, x25, [sp, #352]
	ldp	x8, x9, [sp, #304]
	stp	x8, x9, [sp, #80]               ; 16-byte Folded Spill
	movi.2d	v0, #0000000000000000
	ldr	x19, [sp, #96]                  ; 8-byte Folded Reload
	stp	q0, q0, [x19]
Ltmp5:
	add	x0, sp, #352
	bl	__Z12count_statesRK10Population
Ltmp6:
; %bb.5:
	stp	x0, x1, [x29, #-184]
	ldp	x8, x9, [x19, #8]
	stur	x8, [x29, #-208]
	sub	x10, x29, #208
	sub	x11, x29, #184
	stp	x10, x11, [sp, #272]
	str	x19, [sp, #288]
	cmp	x8, x9
	b.hs	LBB1_14
; %bb.6:
	ldur	q0, [x29, #-184]
	str	q0, [x8], #16
	ldp	x11, x10, [sp, #80]             ; 16-byte Folded Reload
	sub	x19, x10, x11
	ldr	x9, [sp, #96]                   ; 8-byte Folded Reload
	str	x8, [x9, #8]
	cmp	x10, x11
	b.eq	LBB1_16
LBB1_7:
	lsr	x8, x19, #62
	cbnz	x8, LBB1_116
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
	cbnz	x8, LBB1_117
; %bb.10:
	lsl	x23, x19, #3
Ltmp12:
	mov	x0, x23
	bl	__Znwm
Ltmp13:
; %bb.11:
	mov	x21, x0
	add	x22, x20, x22
	mov	x1, x23
	bl	_bzero
	b	LBB1_17
LBB1_12:
	mov	w9, #1                          ; =0x1
	strh	w9, [sp, #492]
	ldrh	w9, [sp, #494]
	cbnz	w9, LBB1_2
LBB1_13:
	mov	w9, #1                          ; =0x1
	strh	w9, [sp, #494]
	b	LBB1_2
LBB1_14:
Ltmp7:
	add	x0, sp, #272
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
Ltmp8:
; %bb.15:
	ldur	x8, [x29, #-208]
	ldp	x11, x10, [sp, #80]             ; 16-byte Folded Reload
	sub	x19, x10, x11
	ldr	x9, [sp, #96]                   ; 8-byte Folded Reload
	str	x8, [x9, #8]
	cmp	x10, x11
	b.ne	LBB1_7
LBB1_16:
	mov	x20, #0                         ; =0x0
	mov	x22, #0                         ; =0x0
	mov	x21, #0                         ; =0x0
LBB1_17:
	sub	x27, x25, x26
	ldr	x8, [sp, #352]
	str	x8, [sp, #120]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #400]
	str	x8, [sp, #264]                  ; 8-byte Folded Spill
	ldr	x24, [sp, #424]
	cmp	x25, x26
	b.eq	LBB1_20
; %bb.18:
	mov	x8, x24
	ldr	x9, [sp, #264]                  ; 8-byte Folded Reload
	ldr	x10, [sp, #120]                 ; 8-byte Folded Reload
	mov	x11, x27
LBB1_19:                                ; =>This Inner Loop Header: Depth=1
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
	b.ne	LBB1_19
LBB1_20:
	mov	x9, #58809                      ; =0xe5b9
	movk	x9, #7396, lsl #16
	movk	x9, #18285, lsl #32
	movk	x9, #48984, lsl #48
	mov	x25, #31765                     ; =0x7c15
	movk	x25, #32586, lsl #16
	movk	x25, #31161, lsl #32
	movk	x25, #40503, lsl #48
	mov	x10, #4587                      ; =0x11eb
	movk	x10, #4913, lsl #16
	movk	x10, #18875, lsl #32
	movk	x10, #38096, lsl #48
	ldr	x26, [sp, #376]
	ldr	x8, [sp, #464]
	add	x8, x8, x25
	eor	x8, x8, x8, lsr #30
	mul	x8, x8, x9
	eor	x8, x8, x8, lsr #27
	mul	x8, x8, x10
	eor	x8, x8, x8, lsr #31
	str	x8, [sp, #272]
	ldrh	w8, [sp, #492]
	cmp	w8, #1
	csinc	w8, w8, wzr, hi
	strh	w8, [sp, #280]
	ldrh	w8, [sp, #494]
	cmp	w8, #1
	csinc	w8, w8, wzr, hi
	strh	w8, [sp, #282]
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	str	x0, [sp, #8]                    ; 8-byte Folded Spill
	ldr	w8, [sp, #460]
	ldr	x23, [sp, #96]                  ; 8-byte Folded Reload
	cbz	w8, LBB1_97
; %bb.21:
	str	xzr, [sp, #104]                 ; 8-byte Folded Spill
	sub	x8, x22, x20
	str	x8, [sp, #64]                   ; 8-byte Folded Spill
	cmp	x27, #15
	csel	w8, wzr, w28, ls
	str	w8, [sp, #60]                   ; 4-byte Folded Spill
	and	x8, x19, #0x7
	str	x8, [sp, #72]                   ; 8-byte Folded Spill
	ldp	x9, x8, [sp, #80]               ; 16-byte Folded Reload
	sub	x8, x9, x8
	str	x8, [sp, #40]                   ; 8-byte Folded Spill
	add	x8, sp, #272
	orr	x8, x8, #0xc
	str	x8, [sp, #48]                   ; 8-byte Folded Spill
	and	x8, x19, #0xfffffffffffffff8
	neg	x10, x8
	add	x9, x21, #32
	add	x8, x20, #16
	stp	x8, x9, [sp, #16]               ; 16-byte Folded Spill
Lloh3:
	adrp	x8, lCPI1_0@PAGE
Lloh4:
	ldr	q0, [x8, lCPI1_0@PAGEOFF]
	str	q0, [sp, #128]                  ; 16-byte Folded Spill
	dup.2d	v0, x25
	str	q0, [sp, #192]                  ; 16-byte Folded Spill
Lloh5:
	adrp	x28, __MergedGlobals@PAGE
Lloh6:
	add	x28, x28, __MergedGlobals@PAGEOFF
	str	x27, [sp, #112]                 ; 8-byte Folded Spill
	str	x26, [sp, #144]                 ; 8-byte Folded Spill
	str	x10, [sp, #32]                  ; 8-byte Folded Spill
LBB1_22:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_27 Depth 2
                                        ;     Child Loop BB1_46 Depth 2
                                        ;     Child Loop BB1_54 Depth 2
                                        ;       Child Loop BB1_57 Depth 3
                                        ;     Child Loop BB1_90 Depth 2
	ldp	x9, x8, [sp, #80]               ; 16-byte Folded Reload
	cmp	x8, x9
	b.eq	LBB1_48
; %bb.23:                               ;   in Loop: Header=BB1_22 Depth=1
	ldp	d10, d9, [sp, #472]
	ldr	x10, [sp, #328]
	ldr	x11, [sp, #304]
	ldr	x8, [sp, #40]                   ; 8-byte Folded Reload
	cmn	x8, #8
	b.ls	LBB1_25
; %bb.24:                               ;   in Loop: Header=BB1_22 Depth=1
	mov	x8, #0                          ; =0x0
	ldr	x9, [sp, #72]                   ; 8-byte Folded Reload
	cbnz	x9, LBB1_44
	b	LBB1_48
LBB1_25:                                ;   in Loop: Header=BB1_22 Depth=1
	mov	x22, #0                         ; =0x0
	str	x11, [sp, #240]                 ; 8-byte Folded Spill
	add	x27, x11, #3
	str	x10, [sp, #224]                 ; 8-byte Folded Spill
	add	x23, x10, #16
	ldp	x25, x26, [sp, #16]             ; 16-byte Folded Reload
	ldr	x19, [sp, #32]                  ; 8-byte Folded Reload
	b	LBB1_27
LBB1_26:                                ;   in Loop: Header=BB1_27 Depth=2
	sub	x22, x22, #8
	add	x27, x27, #8
	str	d8, [x26, #24]
	add	x26, x26, #64
	add	x25, x25, #32
	add	x23, x23, #32
	cmp	x19, x22
	b.eq	LBB1_43
LBB1_27:                                ;   Parent Loop BB1_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldur	w8, [x23, #-16]
	movi.2d	v8, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB1_29
; %bb.28:                               ;   in Loop: Header=BB1_27 Depth=2
	ldurb	w9, [x27, #-3]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x25, #-16]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
LBB1_29:                                ;   in Loop: Header=BB1_27 Depth=2
	stur	d0, [x26, #-32]
	ldur	w8, [x23, #-12]
	cbz	w8, LBB1_31
; %bb.30:                               ;   in Loop: Header=BB1_27 Depth=2
	ldurb	w9, [x27, #-2]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x25, #-12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d8, d1, d0
LBB1_31:                                ;   in Loop: Header=BB1_27 Depth=2
	stur	d8, [x26, #-24]
	ldur	w8, [x23, #-8]
	movi.2d	v8, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB1_33
; %bb.32:                               ;   in Loop: Header=BB1_27 Depth=2
	ldurb	w9, [x27, #-1]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x25, #-8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
LBB1_33:                                ;   in Loop: Header=BB1_27 Depth=2
	stur	d0, [x26, #-16]
	ldur	w8, [x23, #-4]
	cbz	w8, LBB1_35
; %bb.34:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x27]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldur	s1, [x25, #-4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d8, d1, d0
LBB1_35:                                ;   in Loop: Header=BB1_27 Depth=2
	stur	d8, [x26, #-8]
	ldr	w8, [x23]
	movi.2d	v8, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB1_37
; %bb.36:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x27, #1]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x25]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
LBB1_37:                                ;   in Loop: Header=BB1_27 Depth=2
	str	d0, [x26]
	ldr	w8, [x23, #4]
	cbz	w8, LBB1_39
; %bb.38:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x27, #2]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x25, #4]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d8, d1, d0
LBB1_39:                                ;   in Loop: Header=BB1_27 Depth=2
	str	d8, [x26, #8]
	ldr	w8, [x23, #8]
	movi.2d	v8, #0000000000000000
	movi.2d	v0, #0000000000000000
	cbz	w8, LBB1_41
; %bb.40:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x27, #3]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x25, #8]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
LBB1_41:                                ;   in Loop: Header=BB1_27 Depth=2
	str	d0, [x26, #16]
	ldr	w8, [x23, #12]
	cbz	w8, LBB1_26
; %bb.42:                               ;   in Loop: Header=BB1_27 Depth=2
	ldrb	w9, [x27, #4]
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x25, #12]
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d8, d1, d0
	b	LBB1_26
LBB1_43:                                ;   in Loop: Header=BB1_22 Depth=1
	neg	x8, x22
	ldr	x27, [sp, #112]                 ; 8-byte Folded Reload
	ldr	x10, [sp, #224]                 ; 8-byte Folded Reload
	ldr	x11, [sp, #240]                 ; 8-byte Folded Reload
	ldr	x9, [sp, #72]                   ; 8-byte Folded Reload
	cbz	x9, LBB1_48
LBB1_44:                                ;   in Loop: Header=BB1_22 Depth=1
	add	x19, x21, x8, lsl #3
	lsl	x9, x8, #2
	add	x22, x20, x9
	add	x23, x11, x8
	add	x25, x10, x9
	ldr	x26, [sp, #72]                  ; 8-byte Folded Reload
	b	LBB1_46
LBB1_45:                                ;   in Loop: Header=BB1_46 Depth=2
	ldrb	w9, [x23], #1
	cmp	w9, #0
	fcsel	d0, d10, d9, eq
	ldr	s1, [x22], #4
	ucvtf	d1, d1
	fnmul	d0, d0, d1
	ucvtf	d1, w8
	fdiv	d0, d0, d1
	bl	_exp
	fmov	d1, #1.00000000
	fsub	d0, d1, d0
	str	d0, [x19], #8
	subs	x26, x26, #1
	b.eq	LBB1_48
LBB1_46:                                ;   Parent Loop BB1_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldr	w8, [x25], #4
	cbnz	w8, LBB1_45
; %bb.47:                               ;   in Loop: Header=BB1_46 Depth=2
	movi.2d	v0, #0000000000000000
	str	d0, [x19], #8
	add	x22, x22, #4
	add	x23, x23, #1
	subs	x26, x26, #1
	b.ne	LBB1_46
LBB1_48:                                ;   in Loop: Header=BB1_22 Depth=1
	ldr	x1, [sp, #64]                   ; 8-byte Folded Reload
	cmp	x1, #1
	b.lt	LBB1_50
; %bb.49:                               ;   in Loop: Header=BB1_22 Depth=1
	mov	x0, x20
	bl	_bzero
LBB1_50:                                ;   in Loop: Header=BB1_22 Depth=1
	ldr	x8, [sp, #48]                   ; 8-byte Folded Reload
	stp	xzr, xzr, [x8]
	ldr	x7, [sp, #120]                  ; 8-byte Folded Reload
	ldr	w8, [sp, #60]                   ; 4-byte Folded Reload
	add	x14, sp, #272
	sub	x15, x29, #184
	cbz	w8, LBB1_84
; %bb.51:                               ;   in Loop: Header=BB1_22 Depth=1
	mov	x26, #0                         ; =0x0
	mov	w8, #3                          ; =0x3
	ldr	x9, [sp, #104]                  ; 8-byte Folded Reload
	bfi	x8, x9, #8, #55
	dup.2d	v1, x8
	mov	w8, #4                          ; =0x4
	orr	x8, x8, x9, lsl #8
	dup.2d	v0, x8
	stp	q0, q1, [sp, #208]              ; 32-byte Folded Spill
	mov	w8, #16                         ; =0x10
	movi.16b	v24, #1
	b	LBB1_54
LBB1_52:                                ;   in Loop: Header=BB1_54 Depth=2
	ldur	q0, [x29, #-208]
	movi.16b	v24, #1
	cmeq.16b	v0, v0, v24
	ldp	x27, x7, [sp, #112]             ; 16-byte Folded Reload
	add	x14, sp, #272
	ldr	x16, [sp, #152]                 ; 8-byte Folded Reload
LBB1_53:                                ;   in Loop: Header=BB1_54 Depth=2
	ldr	q26, [sp, #176]                 ; 16-byte Folded Reload
	cmeq.16b	v1, v26, v24
	movi.16b	v25, #2
	cmeq.16b	v2, v26, v25
	movi.2d	v3, #0xffffffffffffffff
	add.16b	v3, v26, v3
	cmhi.16b	v3, v25, v3
	ushll2.8h	v4, v3, #0
	shl.8h	v4, v4, #15
	cmlt.8h	v4, v4, #0
	ushll.8h	v5, v3, #0
	shl.8h	v5, v5, #15
	cmlt.8h	v5, v5, #0
	ldr	x8, [sp, #144]                  ; 8-byte Folded Reload
	add	x8, x8, x26, lsl #1
	ldp	q6, q7, [x8]
	saddw.8h	v16, v6, v3
	saddw2.8h	v3, v7, v3
	cmeq.8h	v17, v3, #0
	cmeq.8h	v18, v16, #0
	uzp1.16b	v19, v18, v17
	xtn.8b	v17, v17
	xtn.8b	v18, v18
	and.16b	v20, v1, v19
	and.16b	v2, v2, v19
	ldr	q19, [sp, #160]                 ; 16-byte Folded Reload
	and.16b	v0, v19, v0
	ushll2.8h	v19, v0, #0
	shl.8h	v19, v19, #15
	cmlt.8h	v19, v19, #0
	ushll.8h	v21, v0, #0
	shl.8h	v21, v21, #15
	cmlt.8h	v21, v21, #0
	shl.16b	v0, v0, #7
	cmlt.16b	v0, v0, #0
	orr.16b	v0, v2, v0
	orr.16b	v2, v0, v20
	sub.16b	v0, v26, v2
	orr	x9, x14, #0x8
	ld1r.8h	{ v20 }, [x9]
	add	x9, sp, #27
	ldur	q22, [x9, #255]
	dup.8h	v23, v22[0]
	str	q0, [x7, x26]
	and.8b	v18, v1, v18
	bsl.16b	v5, v16, v6
	sshll.8h	v6, v18, #0
	bit.16b	v5, v23, v6
	bit.16b	v5, v20, v21
	ext.16b	v1, v1, v1, #8
	and.8b	v1, v1, v17
	bif.16b	v3, v7, v4
	sshll.8h	v1, v1, #0
	bsl.16b	v1, v23, v3
	bit.16b	v1, v20, v19
	stp	q5, q1, [x8]
	cmeq.16b	v1, v26, v2
	ldr	q5, [sp, #128]                  ; 16-byte Folded Reload
	and.16b	v1, v1, v5
	ext.16b	v2, v1, v1, #8
	zip1.16b	v1, v1, v2
	addv.8h	h1, v1
	mov.d	x8, v22[1]
	fmov	x9, d22
	cmeq.16b	v2, v0, v24
	and.16b	v2, v2, v5
	ext.16b	v3, v2, v2, #8
	zip1.16b	v2, v2, v3
	addv.8h	h2, v2
	cmeq.16b	v3, v0, v25
	and.16b	v3, v3, v5
	ext.16b	v4, v3, v3, #8
	zip1.16b	v3, v3, v4
	addv.8h	h3, v3
	lsr	x10, x8, #16
	movi.16b	v4, #3
	cmeq.16b	v4, v0, v4
	and.16b	v4, v4, v5
	ext.16b	v5, v4, v4, #8
	zip1.16b	v4, v4, v5
	addv.8h	h4, v4
	add	x11, x14, #24
	extr	x8, x8, x9, #48
	fmov	d5, x8
	lsr	x8, x9, #16
	fmov	d6, x8
	zip1.2s	v5, v6, v5
	mov.h	v1[1], v2[0]
	mov.h	v1[2], v3[0]
	mov.h	v1[3], v4[0]
	cnt.8b	v1, v1
	fmov	s2, w10
	ld1.s	{ v2 }[1], [x11]
	mov.d	v5[1], v2[0]
	uaddlp.4h	v1, v1
	uaddw.4s	v1, v5, v1
	add	x8, sp, #29
	stur	q1, [x8, #255]
	umov.b	w9, v0[0]
	lsl	x8, x26, #2
	ldr	x13, [sp, #264]                 ; 8-byte Folded Reload
	ldr	w10, [x13, x8]
	ldr	w11, [x20, x10, lsl #2]
	cmp	w9, #2
	cinc	w9, w11, eq
	str	w9, [x20, x10, lsl #2]
	ldr	w9, [x24, x8]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[1]
	orr	x10, x8, #0x4
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[2]
	orr	x10, x8, #0x8
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[3]
	orr	x10, x8, #0xc
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[4]
	orr	x10, x8, #0x10
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[5]
	mov	w10, #20                        ; =0x14
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[6]
	orr	x10, x8, #0x18
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[7]
	orr	x10, x8, #0x1c
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[8]
	orr	x10, x8, #0x20
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[9]
	mov	w10, #36                        ; =0x24
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[10]
	mov	w10, #40                        ; =0x28
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[11]
	mov	w10, #44                        ; =0x2c
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[12]
	orr	x10, x8, #0x30
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[13]
	mov	w10, #52                        ; =0x34
	orr	x10, x8, x10
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[14]
	orr	x10, x8, #0x38
	ldr	w11, [x13, x10]
	ldr	w12, [x20, x11, lsl #2]
	cmp	w9, #2
	cinc	w9, w12, eq
	str	w9, [x20, x11, lsl #2]
	ldr	w9, [x24, x10]
	ldr	w10, [x20, x9, lsl #2]
	cinc	w10, w10, eq
	str	w10, [x20, x9, lsl #2]
	umov.b	w9, v0[15]
	orr	x8, x8, #0x3c
	ldr	w10, [x13, x8]
	ldr	w11, [x20, x10, lsl #2]
	cmp	w9, #2
	cinc	w9, w11, eq
	str	w9, [x20, x10, lsl #2]
	ldr	w8, [x24, x8]
	ldr	w9, [x20, x8, lsl #2]
	cinc	w9, w9, eq
	str	w9, [x20, x8, lsl #2]
	add	x8, x16, #16
	mov	x26, x16
	cmp	x8, x27
	b.hi	LBB1_85
LBB1_54:                                ;   Parent Loop BB1_22 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB1_57 Depth 3
	mov	x16, x8
	ldr	q0, [x7, x26]
	str	q0, [sp, #176]                  ; 16-byte Folded Spill
	cmeq.16b	v1, v0, #0
	and.16b	v0, v1, v24
	stp	xzr, xzr, [x29, #-208]
	sturb	wzr, [x29, #-184]
	umov.b	w8, v0[0]
	umov.b	w9, v0[0]
	mov	w10, #1                         ; =0x1
	strb	w10, [x15, x9]
	umov.b	w9, v0[1]
	umov.b	w10, v0[2]
	add	w8, w8, w9
	add	w9, w8, w10
	and	x8, x8, #0x3
	mov	w10, #2                         ; =0x2
	strb	w10, [x15, x8]
	and	x8, x9, #0x7
	mov	w10, #3                         ; =0x3
	strb	w10, [x15, x8]
	umov.b	w8, v0[3]
	umov.b	w10, v0[4]
	add	w8, w9, w8
	add	w9, w8, w10
	and	x8, x8, #0xff
	mov	w10, #4                         ; =0x4
	strb	w10, [x15, x8]
	and	x8, x9, #0xff
	mov	w10, #5                         ; =0x5
	strb	w10, [x15, x8]
	umov.b	w8, v0[5]
	add	w8, w9, w8
	and	x8, x8, #0xff
	mov	w9, #6                          ; =0x6
	strb	w9, [x15, x8]
	umov.b	w9, v1[6]
	umov.b	w10, v1[7]
	and	x9, x9, #0x1
	and	x10, x10, #0x1
	add	x8, x8, x9
	add	x9, x8, x10
	mov	w10, #7                         ; =0x7
	strb	w10, [x15, x8]
	mov	w8, #8                          ; =0x8
	strb	w8, [x15, x9]
	umov.b	w8, v1[8]
	umov.b	w10, v1[9]
	and	x8, x8, #0x1
	and	x10, x10, #0x1
	add	x8, x9, x8
	add	x9, x8, x10
	mov	w10, #9                         ; =0x9
	strb	w10, [x15, x8]
	mov	w8, #10                         ; =0xa
	strb	w8, [x15, x9]
	umov.b	w8, v1[10]
	umov.b	w10, v1[11]
	and	x8, x8, #0x1
	and	x10, x10, #0x1
	add	x8, x9, x8
	add	x9, x8, x10
	mov	w10, #11                        ; =0xb
	strb	w10, [x15, x8]
	mov	w8, #12                         ; =0xc
	strb	w8, [x15, x9]
	umov.b	w8, v1[12]
	and	x8, x8, #0x1
	add	x8, x8, w9, uxtw
	mov	w9, #13                         ; =0xd
	strb	w9, [x15, x8]
	umov.b	w9, v1[13]
	and	x9, x9, #0x1
	add	x8, x9, w8, uxtw
	mov	w9, #14                         ; =0xe
	strb	w9, [x15, x8]
	umov.b	w9, v1[14]
	and	x9, x9, #0x1
	add	x8, x9, w8, uxtw
	mov	w9, #15                         ; =0xf
	strb	w9, [x15, x8]
	str	q1, [sp, #160]                  ; 16-byte Folded Spill
	umov.b	w9, v1[15]
	and	x9, x9, #0x1
	add	x25, x9, w8, uxtw
	cbz	w25, LBB1_83
; %bb.55:                               ;   in Loop: Header=BB1_54 Depth=2
	str	x16, [sp, #152]                 ; 8-byte Folded Spill
	mov	x23, #0                         ; =0x0
	sub	w8, w25, #1
	ldrb	w8, [x15, w8, uxtw]
	strb	w8, [x15, x25]
	ld1r.2d	{ v0 }, [x14]
	str	q0, [sp, #240]                  ; 16-byte Folded Spill
	b	LBB1_57
LBB1_56:                                ;   in Loop: Header=BB1_57 Depth=3
	add	x23, x23, #2
	cmp	x23, x25
	b.hs	LBB1_52
LBB1_57:                                ;   Parent Loop BB1_22 Depth=1
                                        ;     Parent Loop BB1_54 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	add	x27, x15, x23
	ldrb	w22, [x27]
	ldrb	w19, [x27, #1]
Lloh7:
	adrp	x8, __MergedGlobals@PAGE+8
Lloh8:
	add	x8, x8, __MergedGlobals@PAGEOFF+8
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_71
LBB1_58:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh9:
	adrp	x8, __MergedGlobals@PAGE+24
Lloh10:
	add	x8, x8, __MergedGlobals@PAGEOFF+24
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_72
LBB1_59:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh11:
	adrp	x8, __MergedGlobals@PAGE+40
Lloh12:
	add	x8, x8, __MergedGlobals@PAGEOFF+40
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_73
LBB1_60:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh13:
	adrp	x8, __MergedGlobals@PAGE+56
Lloh14:
	add	x8, x8, __MergedGlobals@PAGEOFF+56
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_74
LBB1_61:                                ;   in Loop: Header=BB1_57 Depth=3
	ldr	d11, [x28]
	ldr	d12, [x28, #16]
	ldr	d9, [x28, #32]
	ldr	d10, [x28, #48]
	add	x8, x28, #8
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_75
LBB1_62:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh15:
	adrp	x8, __MergedGlobals@PAGE+24
Lloh16:
	add	x8, x8, __MergedGlobals@PAGEOFF+24
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_76
LBB1_63:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh17:
	adrp	x8, __MergedGlobals@PAGE+40
Lloh18:
	add	x8, x8, __MergedGlobals@PAGEOFF+40
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_77
LBB1_64:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh19:
	adrp	x8, __MergedGlobals@PAGE+56
Lloh20:
	add	x8, x8, __MergedGlobals@PAGEOFF+56
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_78
LBB1_65:                                ;   in Loop: Header=BB1_57 Depth=3
	ldr	d15, [x28]
	ldr	d8, [x28, #16]
	ldr	d13, [x28, #32]
	ldr	d14, [x28, #48]
	add	x8, x28, #8
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_79
LBB1_66:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh21:
	adrp	x8, __MergedGlobals@PAGE+24
Lloh22:
	add	x8, x8, __MergedGlobals@PAGEOFF+24
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_80
LBB1_67:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh23:
	adrp	x8, __MergedGlobals@PAGE+40
Lloh24:
	add	x8, x8, __MergedGlobals@PAGEOFF+40
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_81
LBB1_68:                                ;   in Loop: Header=BB1_57 Depth=3
Lloh25:
	adrp	x8, __MergedGlobals@PAGE+56
Lloh26:
	add	x8, x8, __MergedGlobals@PAGEOFF+56
	ldaprb	w8, [x8]
	tbz	w8, #0, LBB1_82
LBB1_69:                                ;   in Loop: Header=BB1_57 Depth=3
	add	x9, x26, x22
	mov	w8, w9
	add	x10, x26, x19
	mov	w11, w10
	fmov	d0, x8
	mov.d	v0[1], x11
	add	x8, x23, #1
	ldr	q1, [sp, #240]                  ; 16-byte Folded Reload
	eor.16b	v0, v0, v1
	ldr	q4, [sp, #192]                  ; 16-byte Folded Reload
	add.2d	v0, v0, v4
	ushr.2d	v1, v0, #30
	eor.16b	v0, v1, v0
	xtn.2s	v1, v0
	shrn.2s	v0, v0, #32
	umull.2d	v2, v1, v12
	umlal.2d	v2, v0, v11
	shl.2d	v0, v2, #32
	umlal.2d	v0, v1, v11
	ushr.2d	v1, v0, #27
	eor.16b	v0, v1, v0
	xtn.2s	v1, v0
	shrn.2s	v0, v0, #32
	umull.2d	v2, v1, v10
	umlal.2d	v2, v0, v9
	shl.2d	v0, v2, #32
	umlal.2d	v0, v1, v9
	ushr.2d	v1, v0, #31
	eor.16b	v2, v1, v0
	ldr	q3, [sp, #224]                  ; 16-byte Folded Reload
	eor3.16b	v0, v1, v0, v3
	add.2d	v0, v0, v4
	ushr.2d	v1, v0, #30
	eor.16b	v0, v1, v0
	xtn.2s	v1, v0
	shrn.2s	v0, v0, #32
	umull.2d	v3, v1, v8
	umlal.2d	v3, v0, v15
	shl.2d	v0, v3, #32
	umlal.2d	v0, v1, v15
	ushr.2d	v1, v0, #27
	eor.16b	v0, v1, v0
	xtn.2s	v1, v0
	shrn.2s	v0, v0, #32
	umull.2d	v3, v1, v14
	umlal.2d	v3, v0, v13
	shl.2d	v0, v3, #32
	umlal.2d	v0, v1, v13
	ldr	q1, [sp, #208]                  ; 16-byte Folded Reload
	eor.16b	v1, v2, v1
	add.2d	v1, v1, v4
	ushr.2d	v2, v1, #30
	eor.16b	v1, v2, v1
	ldr	d2, [x28]
	ldr	d3, [x28, #16]
	xtn.2s	v4, v1
	shrn.2s	v1, v1, #32
	umull.2d	v3, v4, v3
	umlal.2d	v3, v1, v2
	shl.2d	v1, v3, #32
	umlal.2d	v1, v4, v2
	ushr.2d	v2, v1, #27
	eor.16b	v1, v2, v1
	ldr	d2, [x28, #32]
	ldr	d3, [x28, #48]
	xtn.2s	v4, v1
	shrn.2s	v1, v1, #32
	umull.2d	v3, v4, v3
	ldr	x12, [sp, #264]                 ; 8-byte Folded Reload
	ldr	w11, [x12, x9, lsl #2]
	umlal.2d	v3, v1, v2
	ldr	w12, [x12, x10, lsl #2]
	add	x12, x21, x12, lsl #3
	ldr	d1, [x21, x11, lsl #3]
	ld1.d	{ v1 }[1], [x12]
	ldr	w9, [x24, x9, lsl #2]
	ldr	w10, [x24, x10, lsl #2]
	shl.2d	v3, v3, #32
	add	x10, x21, x10, lsl #3
	ldr	d5, [x21, x9, lsl #3]
	ld1.d	{ v5 }[1], [x10]
	umlal.2d	v3, v4, v2
	ushr.2d	v2, v0, #42
	ushr.2d	v0, v0, #11
	eor.16b	v0, v2, v0
	mov	x9, #4368491638549381120        ; =0x3ca0000000000000
	dup.2d	v2, x9
	ucvtf.2d	v0, v0
	fmul.2d	v0, v0, v2
	fcmgt.2d	v0, v1, v0
	ushr.2d	v1, v3, #42
	ushr.2d	v3, v3, #11
	eor.16b	v1, v1, v3
	ucvtf.2d	v1, v1
	fmul.2d	v1, v1, v2
	fcmgt.2d	v1, v5, v1
	orr.16b	v0, v0, v1
	umov.b	w9, v0[0]
	and	w9, w9, #0x1
	sub	x15, x29, #184
	ldrb	w10, [x15, x23]
	sub	x11, x29, #208
	strb	w9, [x11, x10]
	cmp	x8, x25
	b.hs	LBB1_56
; %bb.70:                               ;   in Loop: Header=BB1_57 Depth=3
	umov.b	w8, v0[8]
	and	w8, w8, #0x1
	ldrb	w9, [x27, #1]
	sub	x10, x29, #208
	strb	w8, [x10, x9]
	b	LBB1_56
LBB1_71:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp20:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.1
Ltmp21:
	b	LBB1_58
LBB1_72:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp22:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.2
Ltmp23:
	b	LBB1_59
LBB1_73:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp24:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.3
Ltmp25:
	b	LBB1_60
LBB1_74:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp26:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.4
Ltmp27:
	b	LBB1_61
LBB1_75:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp28:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.5
Ltmp29:
	b	LBB1_62
LBB1_76:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp30:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.6
Ltmp31:
	b	LBB1_63
LBB1_77:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp32:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.7
Ltmp33:
	b	LBB1_64
LBB1_78:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp34:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.8
Ltmp35:
	b	LBB1_65
LBB1_79:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp36:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.9
Ltmp37:
	b	LBB1_66
LBB1_80:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp38:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.10
Ltmp39:
	b	LBB1_67
LBB1_81:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp40:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.11
Ltmp41:
	b	LBB1_68
LBB1_82:                                ;   in Loop: Header=BB1_57 Depth=3
Ltmp42:
	bl	__Z17run_simulation_v3RK6Paramsb.cold.12
Ltmp43:
	b	LBB1_69
LBB1_83:                                ;   in Loop: Header=BB1_54 Depth=2
	movi.2d	v0, #0000000000000000
	movi.16b	v24, #1
	b	LBB1_53
LBB1_84:                                ;   in Loop: Header=BB1_22 Depth=1
	mov	w9, #0                          ; =0x0
	mov	w10, #0                         ; =0x0
	mov	w11, #0                         ; =0x0
	mov	x16, #0                         ; =0x0
	b	LBB1_86
LBB1_85:                                ;   in Loop: Header=BB1_22 Depth=1
	ldr	w11, [sp, #284]
	ldr	w10, [sp, #288]
	ldr	w9, [sp, #292]
	ldr	w8, [sp, #296]
LBB1_86:                                ;   in Loop: Header=BB1_22 Depth=1
	ldr	x26, [sp, #144]                 ; 8-byte Folded Reload
	cmp	x16, x27
	ldr	x23, [sp, #96]                  ; 8-byte Folded Reload
	mov	x19, #58809                     ; =0xe5b9
	movk	x19, #7396, lsl #16
	movk	x19, #18285, lsl #32
	movk	x19, #48984, lsl #48
	mov	x22, #31765                     ; =0x7c15
	movk	x22, #32586, lsl #16
	movk	x22, #31161, lsl #32
	movk	x22, #40503, lsl #48
	mov	x25, #4587                      ; =0x11eb
	movk	x25, #4913, lsl #16
	movk	x25, #18875, lsl #32
	movk	x25, #38096, lsl #48
	b.hs	LBB1_92
; %bb.87:                               ;   in Loop: Header=BB1_22 Depth=1
	mov	x30, x16
	ldrh	w12, [sp, #282]
	ldr	x13, [sp, #272]
	mov	w14, #3                         ; =0x3
	ldr	x15, [sp, #104]                 ; 8-byte Folded Reload
	bfi	x14, x15, #8, #55
	mov	w16, #4                         ; =0x4
	orr	x15, x16, x15, lsl #8
	ldrh	w16, [sp, #280]
	b	LBB1_90
LBB1_88:                                ;   in Loop: Header=BB1_90 Depth=2
	and	w2, w1, #0xff
	cmp	w2, #3
	cset	w4, lo
	sub	w5, w3, w4
	tst	w5, #0xffff
	cset	w6, eq
	cmp	w2, #3
	csel	w3, w5, w3, lo
	cmp	w2, #1
	and	w2, w5, #0xffff
	ccmp	w2, #0, #0, eq
	mov	w2, #1                          ; =0x1
	csel	w5, w2, w6, eq
	csel	w2, w2, w4, eq
	mov	w4, wzr
	csel	w3, w12, w3, eq
LBB1_89:                                ;   in Loop: Header=BB1_90 Depth=2
	and	w2, w5, w2
	orr	w2, w2, w4
	add	w1, w1, w2
	strb	w1, [x7, x30]
	strh	w3, [x26, x30, lsl #1]
	ands	w1, w1, #0xff
	cinc	w11, w11, eq
	cmp	w1, #1
	cinc	w10, w10, eq
	cmp	w1, #3
	cinc	w8, w8, eq
	ldr	w2, [x20, x0, lsl #2]
	cmp	w1, #2
	cinc	w1, w2, eq
	str	w1, [x20, x0, lsl #2]
	ldr	w0, [x20, x17, lsl #2]
	cinc	w9, w9, eq
	cinc	w0, w0, eq
	str	w0, [x20, x17, lsl #2]
	add	x30, x30, #1
	cmp	x30, x27
	b.hs	LBB1_92
LBB1_90:                                ;   Parent Loop BB1_22 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ldrb	w1, [x7, x30]
	ldrh	w3, [x26, x30, lsl #1]
	ldr	x17, [sp, #264]                 ; 8-byte Folded Reload
	ldr	w0, [x17, x30, lsl #2]
	ldr	w17, [x24, x30, lsl #2]
	tst	w1, #0xff
	b.ne	LBB1_88
; %bb.91:                               ;   in Loop: Header=BB1_90 Depth=2
	mov	w2, #0                          ; =0x0
	mov	w4, w30
	eor	x4, x13, x4
	add	x4, x4, x22
	eor	x4, x4, x4, lsr #30
	mul	x4, x4, x19
	eor	x4, x4, x4, lsr #27
	mul	x4, x4, x25
	eor	x4, x4, x4, lsr #31
	eor	x5, x4, x14
	add	x5, x5, x22
	eor	x5, x5, x5, lsr #30
	mul	x5, x5, x19
	eor	x5, x5, x5, lsr #27
	mul	x5, x5, x25
	lsr	x6, x5, #42
	eor	x5, x6, x5, lsr #11
	ucvtf	d0, x5, #53
	eor	x4, x4, x15
	add	x4, x4, x22
	eor	x4, x4, x4, lsr #30
	mul	x4, x4, x19
	eor	x4, x4, x4, lsr #27
	mul	x4, x4, x25
	lsr	x5, x4, #42
	eor	x4, x5, x4, lsr #11
	ucvtf	d1, x4, #53
	ldr	d2, [x21, x0, lsl #3]
	fcmp	d0, d2
	cset	w4, mi
	ldr	d0, [x21, x17, lsl #3]
	fcmp	d1, d0
	csinc	w4, w4, wzr, pl
	cmp	w3, #0
	cset	w5, eq
	cmp	w4, #0
	csel	w3, w16, w3, ne
	b	LBB1_89
LBB1_92:                                ;   in Loop: Header=BB1_22 Depth=1
	str	w11, [sp, #284]
	str	w10, [sp, #288]
	str	w9, [sp, #292]
	str	w8, [sp, #296]
	stp	w11, w10, [x29, #-208]
	stur	w9, [x29, #-200]
	lsr	w9, w8, #16
	sturh	w8, [x29, #-196]
	sturh	w9, [x29, #-194]
	ldp	x8, x9, [x23, #8]
	stur	x8, [x29, #-216]
	sub	x10, x29, #216
	stur	x10, [x29, #-184]
	sub	x10, x29, #208
	stp	x10, x23, [x29, #-176]
	cmp	x8, x9
	b.hs	LBB1_95
; %bb.93:                               ;   in Loop: Header=BB1_22 Depth=1
	ldur	q0, [x29, #-208]
	str	q0, [x8], #16
LBB1_94:                                ;   in Loop: Header=BB1_22 Depth=1
	str	x8, [x23, #8]
	ldr	x9, [sp, #104]                  ; 8-byte Folded Reload
	add	x9, x9, #1
	ldr	w8, [sp, #460]
	str	x9, [sp, #104]                  ; 8-byte Folded Spill
	cmp	x9, x8
	b.lo	LBB1_22
	b	LBB1_97
LBB1_95:                                ;   in Loop: Header=BB1_22 Depth=1
Ltmp45:
	sub	x0, x29, #184
	bl	__ZZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE12emplace_backIJS1_EEERS1_DpOT_ENKUlvE0_clEv
Ltmp46:
; %bb.96:                               ;   in Loop: Header=BB1_22 Depth=1
	ldur	x8, [x29, #-216]
	b	LBB1_94
LBB1_97:
	bl	__ZNSt3__16chrono12steady_clock3nowEv
	ldr	x8, [sp, #8]                    ; 8-byte Folded Reload
	sub	x8, x0, x8
	scvtf	d0, x8
	mov	x8, #225833675390976            ; =0xcd6500000000
	movk	x8, #16845, lsl #48
	fmov	d1, x8
	fdiv	d0, d0, d1
	str	d0, [x23, #24]
	cbz	x21, LBB1_99
; %bb.98:
	mov	x0, x21
	bl	__ZdlPv
LBB1_99:
	cbz	x20, LBB1_101
; %bb.100:
	mov	x0, x20
	bl	__ZdlPv
LBB1_101:
	ldr	x0, [sp, #328]
	cbz	x0, LBB1_103
; %bb.102:
	str	x0, [sp, #336]
	bl	__ZdlPv
LBB1_103:
	ldr	x0, [sp, #304]
	cbz	x0, LBB1_105
; %bb.104:
	str	x0, [sp, #312]
	bl	__ZdlPv
LBB1_105:
	ldr	x0, [sp, #424]
	cbz	x0, LBB1_107
; %bb.106:
	str	x0, [sp, #432]
	bl	__ZdlPv
LBB1_107:
	ldr	x0, [sp, #400]
	cbz	x0, LBB1_109
; %bb.108:
	str	x0, [sp, #408]
	bl	__ZdlPv
LBB1_109:
	ldr	x0, [sp, #376]
	cbz	x0, LBB1_111
; %bb.110:
	str	x0, [sp, #384]
	bl	__ZdlPv
LBB1_111:
	ldr	x0, [sp, #352]
	cbz	x0, LBB1_113
; %bb.112:
	str	x0, [sp, #360]
	bl	__ZdlPv
LBB1_113:
	ldur	x8, [x29, #-160]
Lloh27:
	adrp	x9, ___stack_chk_guard@GOTPAGE
Lloh28:
	ldr	x9, [x9, ___stack_chk_guard@GOTPAGEOFF]
Lloh29:
	ldr	x9, [x9]
	cmp	x9, x8
	b.ne	LBB1_115
; %bb.114:
	add	sp, sp, #576
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
LBB1_115:
	bl	___stack_chk_fail
LBB1_116:
Ltmp17:
	bl	__ZNSt3__16vectorIjNS_9allocatorIjEEE20__throw_length_errorB9nqe220106Ev
Ltmp18:
	b	LBB1_118
LBB1_117:
Ltmp14:
	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB9nqe220106Ev
Ltmp15:
LBB1_118:
	brk	#0x1
LBB1_119:
Ltmp47:
	mov	x22, x0
	cbnz	x21, LBB1_123
; %bb.120:
	cbnz	x20, LBB1_127
LBB1_121:
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbnz	x0, LBB1_129
LBB1_122:
	add	x0, sp, #304
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #352
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
	bl	__Unwind_Resume
LBB1_123:
	mov	x0, x21
	bl	__ZdlPv
	cbz	x20, LBB1_121
	b	LBB1_127
LBB1_124:
Ltmp44:
	bl	__Unwind_Resume
LBB1_125:
Ltmp9:
	mov	x22, x0
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB1_122
	b	LBB1_129
LBB1_126:
Ltmp16:
	mov	x22, x0
LBB1_127:
	mov	x0, x20
	bl	__ZdlPv
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB1_122
	b	LBB1_129
LBB1_128:
Ltmp19:
	mov	x22, x0
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	ldr	x0, [x8]
	cbz	x0, LBB1_122
LBB1_129:
	ldr	x8, [sp, #96]                   ; 8-byte Folded Reload
	str	x0, [x8, #8]
	bl	__ZdlPv
	add	x0, sp, #304
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #352
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
	bl	__Unwind_Resume
LBB1_130:
Ltmp4:
	mov	x22, x0
	add	x0, sp, #304
	bl	__ZN9LocationsD1Ev
	add	x0, sp, #352
	bl	__ZN10PopulationD1Ev
	mov	x0, x22
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
	.loh AdrpLdrGotLdr	Lloh27, Lloh28, Lloh29
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
	.uleb128 Ltmp43-Ltmp20                  ;   Call between Ltmp20 and Ltmp43
	.uleb128 Ltmp44-Lfunc_begin0            ;     jumps to Ltmp44
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp45-Lfunc_begin0            ; >> Call Site 10 <<
	.uleb128 Ltmp46-Ltmp45                  ;   Call between Ltmp45 and Ltmp46
	.uleb128 Ltmp47-Lfunc_begin0            ;     jumps to Ltmp47
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp46-Lfunc_begin0            ; >> Call Site 11 <<
	.uleb128 Ltmp17-Ltmp46                  ;   Call between Ltmp46 and Ltmp17
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp17-Lfunc_begin0            ; >> Call Site 12 <<
	.uleb128 Ltmp18-Ltmp17                  ;   Call between Ltmp17 and Ltmp18
	.uleb128 Ltmp19-Lfunc_begin0            ;     jumps to Ltmp19
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp14-Lfunc_begin0            ; >> Call Site 13 <<
	.uleb128 Ltmp15-Ltmp14                  ;   Call between Ltmp14 and Ltmp15
	.uleb128 Ltmp16-Lfunc_begin0            ;     jumps to Ltmp16
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp15-Lfunc_begin0            ; >> Call Site 14 <<
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
	bl	__ZdlPv
LBB2_2:
	ldr	x0, [x19]
	cbz	x0, LBB2_4
; %bb.3:
	str	x0, [x19, #8]
	bl	__ZdlPv
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
	bl	__ZdlPv
LBB3_2:
	ldr	x0, [x19, #48]
	cbz	x0, LBB3_4
; %bb.3:
	str	x0, [x19, #56]
	bl	__ZdlPv
LBB3_4:
	ldr	x0, [x19, #24]
	cbz	x0, LBB3_6
; %bb.5:
	str	x0, [x19, #32]
	bl	__ZdlPv
LBB3_6:
	ldr	x0, [x19]
	cbz	x0, LBB3_8
; %bb.7:
	str	x0, [x19, #8]
	bl	__ZdlPv
LBB3_8:
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
	cbnz	x9, LBB4_5
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
	cbnz	x9, LBB4_6
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
	cbz	x20, LBB4_4
; %bb.3:
	mov	x0, x20
	bl	__ZdlPv
LBB4_4:
	ldr	x8, [x19]
	str	x25, [x8]
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp], #80             ; 16-byte Folded Reload
	ret
LBB4_5:
	bl	__ZNSt3__16vectorI6CountsNS_9allocatorIS1_EEE20__throw_length_errorB9nqe220106Ev
LBB4_6:
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
Lloh30:
	adrp	x0, l_.str@PAGE
Lloh31:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh30, Lloh31
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
Ltmp48:
	mov	x1, x20
	bl	__ZNSt12length_errorC1B9nqe220106EPKc
Ltmp49:
; %bb.1:
Lloh32:
	adrp	x1, __ZTISt12length_error@GOTPAGE
Lloh33:
	ldr	x1, [x1, __ZTISt12length_error@GOTPAGEOFF]
Lloh34:
	adrp	x2, __ZNSt12length_errorD1Ev@GOTPAGE
Lloh35:
	ldr	x2, [x2, __ZNSt12length_errorD1Ev@GOTPAGEOFF]
	mov	x0, x19
	bl	___cxa_throw
LBB6_2:
Ltmp50:
	mov	x20, x0
	mov	x0, x19
	bl	___cxa_free_exception
	mov	x0, x20
	bl	__Unwind_Resume
	.loh AdrpLdrGot	Lloh34, Lloh35
	.loh AdrpLdrGot	Lloh32, Lloh33
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
	.uleb128 Ltmp48-Lfunc_begin1            ;   Call between Lfunc_begin1 and Ltmp48
	.byte	0                               ;     has no landing pad
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp48-Lfunc_begin1            ; >> Call Site 2 <<
	.uleb128 Ltmp49-Ltmp48                  ;   Call between Ltmp48 and Ltmp49
	.uleb128 Ltmp50-Lfunc_begin1            ;     jumps to Ltmp50
	.byte	0                               ;   On action: cleanup
	.uleb128 Ltmp49-Lfunc_begin1            ; >> Call Site 3 <<
	.uleb128 Lfunc_end1-Ltmp49              ;   Call between Ltmp49 and Lfunc_end1
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
Lloh36:
	adrp	x8, __ZTVSt12length_error@GOTPAGE
Lloh37:
	ldr	x8, [x8, __ZTVSt12length_error@GOTPAGEOFF]
	add	x8, x8, #16
	str	x8, [x0]
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.loh AdrpLdrGot	Lloh36, Lloh37
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
Lloh38:
	adrp	x1, __ZTISt20bad_array_new_length@GOTPAGE
Lloh39:
	ldr	x1, [x1, __ZTISt20bad_array_new_length@GOTPAGEOFF]
Lloh40:
	adrp	x2, __ZNSt20bad_array_new_lengthD1Ev@GOTPAGE
Lloh41:
	ldr	x2, [x2, __ZNSt20bad_array_new_lengthD1Ev@GOTPAGEOFF]
	bl	___cxa_throw
	.loh AdrpLdrGot	Lloh40, Lloh41
	.loh AdrpLdrGot	Lloh38, Lloh39
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
Lloh42:
	adrp	x0, l_.str@PAGE
Lloh43:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh42, Lloh43
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
Lloh44:
	adrp	x0, l_.str@PAGE
Lloh45:
	add	x0, x0, l_.str@PAGEOFF
	bl	__ZNSt3__120__throw_length_errorB9nqe220106EPKc
	.loh AdrpAdd	Lloh44, Lloh45
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.1
__Z17run_simulation_v3RK6Paramsb.cold.1: ; @_Z17run_simulation_v3RK6Paramsb.cold.1
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_6
	cbz	w0, LBB11_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_3
LBB11_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.2
__Z17run_simulation_v3RK6Paramsb.cold.2: ; @_Z17run_simulation_v3RK6Paramsb.cold.2
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_5
	cbz	w0, LBB12_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_0
LBB12_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.3
__Z17run_simulation_v3RK6Paramsb.cold.3: ; @_Z17run_simulation_v3RK6Paramsb.cold.3
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_7
	cbz	w0, LBB13_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_1
LBB13_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.4
__Z17run_simulation_v3RK6Paramsb.cold.4: ; @_Z17run_simulation_v3RK6Paramsb.cold.4
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_4
	cbz	w0, LBB14_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_2
LBB14_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.5
__Z17run_simulation_v3RK6Paramsb.cold.5: ; @_Z17run_simulation_v3RK6Paramsb.cold.5
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_6
	cbz	w0, LBB15_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_3
LBB15_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.6
__Z17run_simulation_v3RK6Paramsb.cold.6: ; @_Z17run_simulation_v3RK6Paramsb.cold.6
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_5
	cbz	w0, LBB16_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_0
LBB16_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.7
__Z17run_simulation_v3RK6Paramsb.cold.7: ; @_Z17run_simulation_v3RK6Paramsb.cold.7
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_7
	cbz	w0, LBB17_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_1
LBB17_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.8
__Z17run_simulation_v3RK6Paramsb.cold.8: ; @_Z17run_simulation_v3RK6Paramsb.cold.8
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_4
	cbz	w0, LBB18_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_2
LBB18_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.9
__Z17run_simulation_v3RK6Paramsb.cold.9: ; @_Z17run_simulation_v3RK6Paramsb.cold.9
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_6
	cbz	w0, LBB19_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_3
LBB19_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.10
__Z17run_simulation_v3RK6Paramsb.cold.10: ; @_Z17run_simulation_v3RK6Paramsb.cold.10
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_5
	cbz	w0, LBB20_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_0
LBB20_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.11
__Z17run_simulation_v3RK6Paramsb.cold.11: ; @_Z17run_simulation_v3RK6Paramsb.cold.11
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_7
	cbz	w0, LBB21_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_1
LBB21_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function _Z17run_simulation_v3RK6Paramsb.cold.12
__Z17run_simulation_v3RK6Paramsb.cold.12: ; @_Z17run_simulation_v3RK6Paramsb.cold.12
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_OUTLINED_FUNCTION_4
	cbz	w0, LBB22_2
; %bb.1:
	bl	_OUTLINED_FUNCTION_2
LBB22_2:
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function OUTLINED_FUNCTION_0
_OUTLINED_FUNCTION_0:                   ; @OUTLINED_FUNCTION_0 Thunk
	.cfi_startproc
; %bb.0:
	mov	w8, #18285                      ; =0x476d
	movk	w8, #48984, lsl #16
	dup.2s	v0, w8
	adrp	x0, __MergedGlobals@PAGE+16
	add	x0, x0, __MergedGlobals@PAGEOFF+16
	str	d0, [x0], #8
	b	___cxa_guard_release
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function OUTLINED_FUNCTION_1
_OUTLINED_FUNCTION_1:                   ; @OUTLINED_FUNCTION_1 Thunk
	.cfi_startproc
; %bb.0:
	mov	w8, #4587                       ; =0x11eb
	movk	w8, #4913, lsl #16
	dup.2s	v0, w8
	adrp	x0, __MergedGlobals@PAGE+32
	add	x0, x0, __MergedGlobals@PAGEOFF+32
	str	d0, [x0], #8
	b	___cxa_guard_release
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function OUTLINED_FUNCTION_2
_OUTLINED_FUNCTION_2:                   ; @OUTLINED_FUNCTION_2 Thunk
	.cfi_startproc
; %bb.0:
	mov	w8, #18875                      ; =0x49bb
	movk	w8, #38096, lsl #16
	dup.2s	v0, w8
	adrp	x0, __MergedGlobals@PAGE+48
	add	x0, x0, __MergedGlobals@PAGEOFF+48
	str	d0, [x0], #8
	b	___cxa_guard_release
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function OUTLINED_FUNCTION_3
_OUTLINED_FUNCTION_3:                   ; @OUTLINED_FUNCTION_3 Thunk
	.cfi_startproc
; %bb.0:
	mov	w8, #58809                      ; =0xe5b9
	movk	w8, #7396, lsl #16
	dup.2s	v0, w8
	adrp	x0, __MergedGlobals@PAGE
	add	x0, x0, __MergedGlobals@PAGEOFF
	str	d0, [x0], #8
	b	___cxa_guard_release
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function OUTLINED_FUNCTION_4
_OUTLINED_FUNCTION_4:                   ; @OUTLINED_FUNCTION_4 Thunk
	.cfi_startproc
; %bb.0:
	adrp	x0, __MergedGlobals@PAGE+56
	add	x0, x0, __MergedGlobals@PAGEOFF+56
	b	___cxa_guard_acquire
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function OUTLINED_FUNCTION_5
_OUTLINED_FUNCTION_5:                   ; @OUTLINED_FUNCTION_5 Thunk
	.cfi_startproc
; %bb.0:
	adrp	x0, __MergedGlobals@PAGE+24
	add	x0, x0, __MergedGlobals@PAGEOFF+24
	b	___cxa_guard_acquire
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function OUTLINED_FUNCTION_6
_OUTLINED_FUNCTION_6:                   ; @OUTLINED_FUNCTION_6 Thunk
	.cfi_startproc
; %bb.0:
	adrp	x0, __MergedGlobals@PAGE+8
	add	x0, x0, __MergedGlobals@PAGEOFF+8
	b	___cxa_guard_acquire
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function OUTLINED_FUNCTION_7
_OUTLINED_FUNCTION_7:                   ; @OUTLINED_FUNCTION_7 Thunk
	.cfi_startproc
; %bb.0:
	adrp	x0, __MergedGlobals@PAGE+40
	add	x0, x0, __MergedGlobals@PAGEOFF+40
	b	___cxa_guard_acquire
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
	.asciz	"vector"

.zerofill __DATA,__bss,__MergedGlobals,64,3 ; @_MergedGlobals
.subsections_via_symbols
