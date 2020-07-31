; The Channely Wood level

; by deater (Vince Weaver) <vince@deater.net>

; Zero Page
	.include "zp.inc"
	.include "hardware.inc"
	.include "common_defines.inc"
	.include "common_routines.inc"

channel_start:
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

	; reset elevators and bridges at start
	; actual game does this too?
	; do this in the linking book otherwise this happens
	; when we take the elevator back down

;	lda	CHANNEL_SWITCHES
;	; hack to avoid "RANGE ERROR" on some versions of ca65
;	and	#<(~(CHANNEL_BRIDGE_UP|CHANNEL_PIPE_EXTENDED|CHANNEL_BOOK_ELEVATOR_UP))
;	sta	CHANNEL_SWITCHES

	; set up bridges

	jsr	adjust_after_changes


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

	cmp	#CHANNEL_TANK_CLOSE
	beq	fg_draw_faucet

	cmp	#CHANNEL_WINDMILL
	beq	fg_draw_windmill_handle

	cmp	#CHANNEL_BOOK_OPEN
	beq	animate_mist_book

	jmp	nothing_special

fg_draw_windmill_handle:
	jsr	draw_windmill_handle
	jmp	nothing_special

fg_draw_faucet:
	jsr	draw_water_faucet
	jmp	nothing_special

animate_mist_book:
	lda	DIRECTION
	cmp	#DIRECTION_S
	bne	done_animate_book

	lda	ANIMATE_FRAME
	cmp     #6
        bcc     mist_book_good                  ; blt

        lda     #0
        sta     ANIMATE_FRAME

mist_book_good:

        asl
        tay
        lda     mist_movie,Y
        sta     INL
        lda     mist_movie+1,Y
        sta     INH

        lda     #24
        sta     XPOS

        lda     #12
        sta     YPOS

        jsr     put_sprite_crop

        lda     FRAMEL
        and     #$f
	bne     done_animate_book

        inc     ANIMATE_FRAME

done_animate_book:
        jmp     nothing_special

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


look_at_faucet:
	lda	#CHANNEL_TANK_CLOSE
	sta	LOCATION
	jmp	change_location

toggle_windmill:
	lda	CHANNEL_SWITCHES
	eor	#CHANNEL_SW_WINDMILL
	sta	CHANNEL_SWITCHES
	rts

toggle_faucet:
	lda	CHANNEL_SWITCHES
	eor	#CHANNEL_SW_FAUCET
	sta	CHANNEL_SWITCHES
	rts


	;==========================
	; includes
	;==========================

	; level graphics
	.include	"graphics_channel/channel_graphics.inc"

	; sound
	.include	"simple_sounds.s"

	; puzzles
	.include	"channel_switches.s"

	; level data
	.include	"leveldata_channel.inc"

	; linking books
	.include	"link_book_mist.s"

