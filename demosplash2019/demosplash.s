; Demosplash 2019
; by Vince "Deater" Weaver	<vince@deater.net>

.include "zp.inc"
.include "hardware.inc"

demosplash2019:



	;==================================================
	; clear zp
	; shouldn't have to do this, but uninit memory bugs
	;==================================================

	lda	#$38
	ldy	#$0
zp_clear_loop:
	sta	$0,y
	iny
	bne	zp_clear_loop

	;=========================
	; set up sound
	;=========================
	lda	#0
	sta	DONE_PLAYING
	sta	FRAME_PLAY_OFFSET
	sta	FRAME_PLAY_PAGE
	sta	FRAME_OFFSET
	sta	FRAME_PAGE
	sta	SOUND_WHILE_DECODE
	jsr	update_pt3_play
	jsr	pt3_set_pages

	jsr	mockingboard_init
	jsr	pt3_setup_interrupt
	jsr	reset_ay_both
	jsr	clear_ay_both
	jsr	pt3_init_song

	lda	#1
	sta	LOOP

	;====================================
	; turn on language card
	; enable read/write, use 1st 4k bank
	lda	$C08B
	lda	$C08B

	;====================================
	; generate 4 patterns worth of music
	; at address $D000-$FC00

	jsr	pt3_write_lc_4

	;===========================
	; Enable graphics
	;===========================

	bit	LORES
	bit	SET_GR
	bit	FULLGR
	bit	KEYRESET

	jmp	main_body


; Pictures (no need to align)
.include "appleII_40_96.inc"
.include "k_40_48d.inc"
.include "graphics/book_open/book_open.inc"
.include "graphics/starbase/starbase.inc"
.include "graphics/starbase/ship_flames.inc"
.include "graphics/starbase/star_wipe.inc"

; Apple II intro
.include "appleII_intro.s"

; missing
.include "missing.s"

; missing
.include "open_book.s"

; Starbase
.include "starbase.s"

; UP UNTIL THIS POINT CAN BE WIPED BY SOUND AT END

main_body:
	;===========================
	; apple II intro
	;============================

;	nop
;	nop
;	nop
	jsr	appleII_intro

	;===========================
	; missing scene
	;===========================

;blarh:	jmp	blarh

;	nop
;	nop
;	nop
	jsr	missing_intro


	;========================
	; start irq music
	;========================

;	nop

	cli	; enable interrupts

	;===========================
	; opening book scene
	;============================

;	nop
;	nop
;	nop

	jsr	open_book

	;===========================
	; starbase scene
	;===========================

;	nop
;	nop
;	nop

	jsr	starbase

	;============================
	; disable irq music

;	nop
	sei


	;===========================
	; escape scene
	;===========================

	jsr	escape

	;===========================
	; book scene
	;===========================

	jsr	end_book

	;===========================
	; credits
	;===========================

	jsr	credits

	; wait wait wait

;	jsr	wait_until_keypressed
repeat_ending:
	jmp	repeat_ending



	;======================
	; wait until keypressed
	;======================
;wait_until_keypressed:
;	lda	KEYPRESS
;	bpl	wait_until_keypressed
;	bit	KEYRESET
;	rts



; FIXME: put at end after music?
;.include "earth.inc"
.include "book_40_48d.inc"
.include "credits_bg.inc"


.include "delay_a.s"	; critical

; things that are exactly 1 page in size
.align $100
.include "offsets_table.s"
.include "movement_table.s"
random_values:
.incbin "random.data"
.include "offsets_table2.s"
.include "font.s"
; things that need to not cross pages
.include "vapor_lock.s"
.include "gr_copy.s"
.include "gr_unrle.s"
.include "gr_offsets.s"
.include "gr_pageflip.s"
.include "gr_clear_bottom.s"
;.align	$100
.include "gr_overlay.s"		; not critical
.include "gr_fast_clear.s"
.include "gr_run_sequence.s"	; not critical

; escape
.include "escape.s"

; reading
.include "reading.s"

; credits
.include "credits.s"

; Music player
.include "pt3_lib_core.s"
.include "pt3_lib_init.s"
.include "pt3_lib_mockingboard.s"
.include "interrupt_handler.s"
.include "pt3_lib_play_frame.s"
.include "pt3_lib_write_frame.s"
.include "pt3_lib_write_lc.s"

.include "create_update_type1.s"
.include "create_update_type2.s"


PT3_LOC = song

; must be page aligned
.align 256
song:
.incbin "dya_space_demo2.pt3"

end_of_line:
