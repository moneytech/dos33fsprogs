; The Stone Ship level

; by deater (Vince Weaver) <vince@deater.net>

; Zero Page
	.include "zp.inc"
	.include "hardware.inc"
	.include "common_defines.inc"
	.include "common_routines.inc"

stoney_start:
	;===================
	; init screen
	jsr	TEXT
	jsr	HOME
	bit	KEYRESET

	bit	SET_GR
	bit	PAGE0
	bit	LORES
	bit	FULLGR

	;=================
	; set up location
	;=================

	lda	#<locations
	sta	LOCATIONS_L
	lda	#>locations
	sta	LOCATIONS_H

	lda	#0
	sta	DRAW_PAGE
	sta	LEVEL_OVER

	; resets if you leave
	sta	BATTERY_CHARGE

	; init cursor

	lda	#20
	sta	CURSOR_X
	sta	CURSOR_Y

	; set up initial location

	jsr	change_location

	lda	#1
	sta	CURSOR_VISIBLE		; visible at first

	lda	#0
	sta	ANIMATE_FRAME

game_loop:
	;=================
	; reset things
	;=================

	lda	#0
	sta	IN_SPECIAL
	sta	IN_RIGHT
	sta	IN_LEFT

	;====================================
	; copy background to current page
	;====================================

	jsr	gr_copy_to_current

	;====================================
	; handle special-case forground logic
	;====================================

	lda	LOCATION
	cmp	#STONEY_BOOK_TABLE_OPEN
	beq	animate_mist_book
	cmp	#STONEY_RED_DRESSER_OPEN
	beq	fg_draw_red_page
	cmp	#STONEY_BLUE_ROOM
	beq	fg_draw_blue_page
	cmp	#STONEY_UMBRELLA
	beq	draw_umbrella_light
	cmp	#STONEY_LIGHTHOUSE_UPSTAIRS
	beq	draw_crank_handle
	cmp	#STONEY_LIGHTHOUSE_BATTERY
	beq	draw_battery_level
	cmp	#STONEY_BOOK_TABLE
	beq	animate_magic_table

	jmp	nothing_special

animate_magic_table:

	jsr	do_animate_magic_table
	jmp	nothing_special

animate_mist_book:
	lda     ANIMATE_FRAME
	cmp	#6
	bcc	mist_book_good			; blt

	lda	#0
	sta	ANIMATE_FRAME

mist_book_good:

	asl
	tay
	lda	mist_movie,Y
	sta	INL
	lda	mist_movie+1,Y
	sta	INH

	lda	#24
	sta	XPOS
	lda	#12
	sta	YPOS

	jsr	put_sprite_crop

	lda	FRAMEL
	and	#$f
	bne	done_animate_mist_book

	inc	ANIMATE_FRAME

done_animate_mist_book:
	jmp	nothing_special

fg_draw_red_page:
	jsr	draw_red_page
	jmp	nothing_special

fg_draw_blue_page:
	jsr     draw_blue_page
	jmp     nothing_special

draw_umbrella_light:
	jsr	do_draw_umbrella_light
	jmp	nothing_special

draw_crank_handle:
	jsr	do_draw_crank_handle
	jmp	nothing_special

draw_battery_level:
	jsr	do_draw_battery_level
	jmp	nothing_special


nothing_special:

	;====================================
	; draw pointer
	;====================================

	jsr	draw_pointer

	;====================================
	; page flip
	;====================================

	jsr	page_flip

	;====================================
	; handle keypress/joystick
	;====================================

	jsr	handle_keypress


	;====================================
	; inc frame count
	;====================================

	inc	FRAMEL
	bne	room_frame_no_oflo
	inc	FRAMEH
room_frame_no_oflo:

	;====================================
	; check level over
	;====================================

	lda	LEVEL_OVER
	bne	really_exit
	jmp	game_loop

really_exit:
	jmp	end_level

stoney_take_red_page:
	lda	#STONEY_PAGE
	jmp	take_red_page

stoney_take_blue_page:
	lda	#STONEY_PAGE
	jmp	take_blue_page


	;=============================
	; handle pages
	;=============================

draw_red_page:

	lda     RED_PAGES_TAKEN
	and	#STONEY_PAGE
	bne	no_draw_page

	lda	#14
	sta	XPOS
	lda	#36
	sta	YPOS

	lda	#<red_page_sprite
	sta	INL
	lda	#>red_page_sprite
	sta	INH

	jmp	put_sprite_crop		; tail call

draw_blue_page:

	lda	DIRECTION
	cmp	#DIRECTION_W
	bne	no_draw_page

	lda	BLUE_PAGES_TAKEN
	and	#STONEY_PAGE
	bne	no_draw_page

	lda	#18
	sta	XPOS
	lda	#30
	sta	YPOS

	lda	#<blue_page_sprite
	sta	INL
	lda	#>blue_page_sprite
	sta	INH

	jmp	put_sprite_crop         ; tail call

no_draw_page:
	rts

	;======================
	; handle half message
stoney_half_message:

	lda	#STONEY_BLUE_HALFMESSAGE
	sta	LOCATION

	jsr	change_location

	bit	SET_TEXT		; set text mode

	rts



	;==========================
	; includes
	;==========================

	; level graphics
	.include	"graphics_stoney/stoney_graphics.inc"

	; linking books
	.include	"link_book_mist.s"

	; puzzles
	.include	"stoney_puzzles.s"
	.include	"handle_pages.s"

	; level data
	.include	"leveldata_stoney.inc"
