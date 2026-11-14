	.build_version macos, 26, 0	sdk_version 27, 0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	__Z17apply_transitionsRK6ParamsR10PopulationRKNSt3__16vectorIhNS4_9allocatorIhEEEE ; -- Begin function _Z17apply_transitionsRK6ParamsR10PopulationRKNSt3__16vectorIhNS4_9allocatorIhEEEE
	.p2align	2
__Z17apply_transitionsRK6ParamsR10PopulationRKNSt3__16vectorIhNS4_9allocatorIhEEEE: ; @_Z17apply_transitionsRK6ParamsR10PopulationRKNSt3__16vectorIhNS4_9allocatorIhEEEE
	.cfi_startproc
; %bb.0:
	ldp	x12, x8, [x1]
	cmp	x8, x12
	b.eq	LBB0_13
; %bb.1:
	mov	x8, #0                          ; =0x0
	mov	w9, #3                          ; =0x3
	mov	w10, #2                         ; =0x2
	mov	w11, #1                         ; =0x1
	b	LBB0_5
LBB0_2:                                 ;   in Loop: Header=BB0_5 Depth=1
	strb	w11, [x12, x8]
	ldrh	w12, [x0, #44]
LBB0_3:                                 ;   in Loop: Header=BB0_5 Depth=1
	cmp	w12, #1
	csinc	w12, w12, wzr, hi
	ldr	x13, [x1, #24]
	strh	w12, [x13, x8, lsl #1]
LBB0_4:                                 ;   in Loop: Header=BB0_5 Depth=1
	add	x8, x8, #1
	ldp	x12, x13, [x1]
	sub	x13, x13, x12
	cmp	x8, x13
	b.hs	LBB0_13
LBB0_5:                                 ; =>This Inner Loop Header: Depth=1
	ldrb	w13, [x12, x8]
	cmp	w13, #2
	b.eq	LBB0_11
; %bb.6:                                ;   in Loop: Header=BB0_5 Depth=1
	cmp	w13, #1
	b.eq	LBB0_9
; %bb.7:                                ;   in Loop: Header=BB0_5 Depth=1
	cbnz	w13, LBB0_4
; %bb.8:                                ;   in Loop: Header=BB0_5 Depth=1
	ldr	x13, [x2]
	ldrb	w13, [x13, x8]
	cbnz	w13, LBB0_2
	b	LBB0_4
LBB0_9:                                 ;   in Loop: Header=BB0_5 Depth=1
	ldr	x13, [x1, #24]
	ldrh	w14, [x13, x8, lsl #1]
	sub	w14, w14, #1
	strh	w14, [x13, x8, lsl #1]
	tst	w14, #0xffff
	b.ne	LBB0_4
; %bb.10:                               ;   in Loop: Header=BB0_5 Depth=1
	strb	w10, [x12, x8]
	ldrh	w12, [x0, #46]
	b	LBB0_3
LBB0_11:                                ;   in Loop: Header=BB0_5 Depth=1
	ldr	x13, [x1, #24]
	ldrh	w14, [x13, x8, lsl #1]
	sub	w14, w14, #1
	strh	w14, [x13, x8, lsl #1]
	tst	w14, #0xffff
	b.ne	LBB0_4
; %bb.12:                               ;   in Loop: Header=BB0_5 Depth=1
	strb	w9, [x12, x8]
	b	LBB0_4
LBB0_13:
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
