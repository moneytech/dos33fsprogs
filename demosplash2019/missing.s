; Missing scene

; Uses the 40x48d page1/page2 every-1-scanline pageflip mode

; by deater (Vince Weaver) <vince@deater.net>

missing_intro:

	; we come into this at the very end of vblank
	; we should be playing a frame of music every
	; 17030 - 1243 = 15787 cycles or so

	;===================
	; init vars

;	lda	#0
;	sta	DRAW_PAGE

	;=============================
	; setup graphics code

	jsr	create_update_type1		; now calls play_frame_compressed

	; setup_rasterbars_page_smc=4
;	lda	#0
;	sta	setup_rasterbars_page_smc+1
	; setup_rasterbars_offset_smc=2
	lda	#2
	sta	setup_rasterbars_offset_smc+1
	; setup_rasterbars_bars_start_smc=16
	lda	#13
	sta	setup_rasterbars_bars_start_smc+1
	; setup_rasterbars_bars_end_smc=48
	lda	#48
	sta	setup_rasterbars_bars_end_smc+1
	; setup_rasterbars_start_addr1_smc:=#<(UPDATE_START+(13*49))
	lda	#<(UPDATE_START+(12*49))
	sta	setup_rasterbars_start_addr1_smc+1
	; setup_rasterbars_start_addr2_smc:=#<(UPDATE_START+(13*49))
	lda	#>(UPDATE_START+(12*49))
	sta	setup_rasterbars_start_addr2_smc+1

	jsr	setup_rasterbars

	; setup_rasterbars_page_smc=4
;	lda	#0
;	sta	setup_rasterbars_page_smc+1
	; setup_rasterbars_offset_smc=2
	lda	#2
	sta	setup_rasterbars_offset_smc+1
	; setup_rasterbars_bars_start_smc=16
	lda	#149
	sta	setup_rasterbars_bars_start_smc+1
	; setup_rasterbars_bars_end_smc=48
	lda	#187
	sta	setup_rasterbars_bars_end_smc+1
	; setup_rasterbars_start_addr1_smc:=#<(UPDATE_START+(149*49))
	lda	#<(UPDATE_START+(148*49))
	sta	setup_rasterbars_start_addr1_smc+1
	; setup_rasterbars_start_addr2_smc:=#<(UPDATE_START+(149*49))
	lda	#>(UPDATE_START+(148*49))
	sta	setup_rasterbars_start_addr2_smc+1

	jsr	setup_rasterbars


	jsr	make_bars

	;=============================
	; Load graphic page0

	lda	#<k_low
	sta	GBASL
	lda	#>k_low
	sta	GBASH
	lda	#$c			; load to $c00
	jsr	load_rle_gr					; 2000

	lda	#4
	sta	DRAW_PAGE

	jsr	gr_copy_to_current	; copy to page1		; 9292

	; GR part
	bit	PAGE1
	bit	LORES							; 4
	bit	SET_GR							; 4
	bit	FULLGR							; 4

;	jsr	wait_until_keypressed

	jsr	play_frame_compressed

	;=============================
	; Load graphic page1

	lda	#<k_high
	sta	GBASL
	lda	#>k_high
	sta	GBASH

	lda	#$c

	jsr	load_rle_gr					; 2000

	lda	#0
	sta	DRAW_PAGE

	jsr	gr_copy_to_current				; 9292

	; GR part
	bit	PAGE0

;	jsr	wait_until_keypressed


	jsr	play_frame_compressed

	;==============================
	; setup graphics for vapor lock
	;==============================

	jsr	vapor_lock

	; vapor lock returns with us at beginning of hsync in line
	; 114 (7410 cycles), so with 5070 lines to go

	; GR part
;	bit	LORES							; 4
	bit	SET_GR							; 4
;	bit	FULLGR							; 4

	jsr	gr_copy_to_current			; 6+ 9292

	; 5070 + 4550 = 9620
	;		9292
	;		  12
	;		   6
	;		====
	;		 310

	; Try X=9 Y=6 cycles=307R3

	lda	TEMP

	ldy	#6							; 2
mloopA:	ldx	#9							; 2
mloopB:	dex								; 2
	bne	mloopB							; 2nt/3
	dey								; 2
	bne	mloopA							; 2nt/3

;	jmp	missing_display_loop					; 3

;.align  $100

	;================================================
	; Display Loop
	;================================================
	; each scan line 65 cycles
	;       1 cycle each byte (40cycles) + 25 for horizontal
	;       Total of 12480 cycles to draw screen
	; Vertical blank = 4550 cycles (70 scan lines)
	; Total of 17030 cycles to get back to where was

	; We want to alternate between page1 and page2 every 65 cycles
        ;       vblank = 4550 cycles to do scrolling



	; want colors 01234567
	; line 0: $X0 to $800
	; line 1: $X1 to $400
	; line 2: $X2
	; line 3: $X3
	; line 4: $4X
	; line 5: $5X
	; line 6: $6X
	; line 7: $7X

missing_display_loop:

	jsr	$9800		; update_type1

	;======================================================
	; We have 4550 cycles in the vblank, use them wisely
	;======================================================
	; do_nothing should be
	;	4550
	;	 -12 jsr/ret to update_type1
	;        - 8 check keypress
	;      -1243
	;=============
	;       3287


	; blah, current code the tight loops are right at a page boundary

	jsr	play_frame_compressed		; 6+1237

do_nothing_missing:

	; want 3287

	; Try X=163 Y=4 cycles=3285R2

	nop

	ldy	#4							; 2
gloop1:	ldx	#163							; 2
gloop2:	dex								; 2
	bne	gloop2							; 2nt/3
	dey								; 2
	bne	gloop1							; 2nt/3


	lda	FRAME_PLAY_PAGE			; 3
	cmp	#4				; 2
	bne	missing_display_loop		; 3

;	lda	KEYPRESS			; 4
;	bpl	missing_display_loop		; 3

;	lda	TEMP			; 3
;	nop				; 2
;	jmp	missing_display_loop	; 3

	rts

;BAR_START = 2*8
BAR_START = (2*8)-3	; 13
BAR_START2 = 152-3

; $9800 + (49*18) + 4 = $9800+886 = $9800+$376=$9b76 (9b72)
; $9800 + (49*152) = $9800+7448 = $9800+$1d18=$b518

make_bars:

	lda	#<bar_colors_top
	sta	INL
	lda	#>bar_colors_top
	sta	INH

	lda	#<(UPDATE_START+49*(BAR_START+2)+4)
	sta	OUTL
	lda	#>(UPDATE_START+49*(BAR_START+2)+4)
	sta	OUTH



	jsr	make_bars_entry

	lda	#<bar_colors_bottom
	sta	INL
	lda	#>bar_colors_bottom
	sta	INH

	lda	#<(UPDATE_START+49*(BAR_START2+2)+4)
	sta	OUTL
	lda	#>(UPDATE_START+49*(BAR_START2+2)+4)
	sta	OUTH

	jsr	make_bars_entry

	rts

make_bars_entry:

	ldy	#0

make_bars_loop:
	lda	(INL),Y
	sta	(OUTL),Y

	iny
	lda	OUTL
	clc
	adc	#48	; because y++
	sta	OUTL
	lda	OUTH
	adc	#0
	sta	OUTH

;	cpy	#32
	tya
	and	#$1f
	bne	make_bars_loop

	rts

bar_colors_top:
	.byte $03,$0b,$0f,$0b,$30,$00,$00
	.byte $00,$02,$06,$0f,$06,$20,$00,$00
	.byte $00,$04,$0c,$0f,$0c,$40,$00,$00
	.byte $00,$05,$07,$0f,$07,$50,$00,$00,$00,$00,$00

bar_colors_bottom:
	.byte $01,$03,$0f,$03,$10,$00,$00
	.byte $00,$08,$0d,$0f,$0d,$80,$00,$00
	.byte $00,$0c,$0e,$0f,$0e,$c0,$00,$00
	.byte $00,$09,$0d,$0f,$0d,$90,$00,$00,$00,$00,$00
