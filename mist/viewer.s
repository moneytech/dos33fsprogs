; Viewer in the room by the dock

; by deater (Vince Weaver) <vince@deater.net>

; Zero Page
	.include "zp.inc"
	.include "hardware.inc"
	.include "common_defines.inc"
	.include "common_routines.inc"

viewer_start:
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
	cmp	#VIEWER_CONTROL_PANEL
	beq	control_panel
	cmp	#VIEWER_POOL_CLOSE
	beq	look_at_pool
	jmp	reset_animation

look_at_pool:
	jsr	display_viewer

	jmp	nothing_special

control_panel:
	jsr	display_panel_code

	jmp	reset_animation

reset_animation:
	lda	#0
	sta	ANIMATE_FRAME

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



back_to_mist:

	lda	#$ff
	sta	LEVEL_OVER

	lda     #MIST_ARRIVAL_DOCK		; the dock
	sta	LOCATION
	lda	#DIRECTION_E
	sta	DIRECTION

	lda	#LOAD_MIST
	sta	WHICH_LOAD

	rts


	;==========================
	; includes
	;==========================

.if 0
	.include	"gr_copy.s"
	.include	"gr_offsets.s"
	.include	"gr_pageflip.s"
	.include	"gr_putsprite_crop.s"
	.include	"text_print.s"
	.include	"gr_fast_clear.s"
	.include	"decompress_fast_v2.s"
	.include	"keyboard.s"
	.include	"draw_pointer.s"
	.include	"end_level.s"
	.include	"common_sprites.inc"
	.include	"page_sprites.inc"

.endif

	; graphics
	.include	"graphics_viewer/viewer_graphics.inc"

	; puzzles
	.include	"viewer_controls.s"

	; leveldata
	.include	"leveldata_viewer.inc"


