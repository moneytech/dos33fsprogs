; Ootw for Apple II Lores
; Checkpoint-15 (arrival at the baths)

; by Vince "DEATER" Weaver	<vince@deater.net>

.include "zp.inc"
.include "hardware.inc"

; TODO:
;  die if not move and get shot by column (first screen)
;  die it try to go back into original room

; bath:
;  after crash, hop out of sphere.  move quickly as you can get lasered
;   right near the pod, but if you walk by the column you can stand
;   forever and not get shot
; walkway1:
;   does not appear you can re-enter bath?  lasers from behind come in
;   but don't hurt you unless you try to walk back in

	;============================
	; ENTRY POINT FOR LEVEL
	;============================

ootw_c15:
	; Initializing when entering level for first time


	;========================================================
	; RESTART: called when restarting level (after game over)
	;========================================================

ootw_c15_restart:

	;===================================
	; run bath intro
	;===================================

;	jsr	bath_intro

	;===================================
	; re-initialize level state
	;===================================

	jsr	ootw_c15_level_init

	;===========================
	; c15_new_room
	;===========================
	; enter new room on level 15

c15_new_room:
	lda	#0
	sta	GAME_OVER

	;====================================
	; Initialize room based on WHICH_ROOM
	; and then play until we exit
	;====================================

	jsr	ootw_c15_setup_room_and_play


	;====================================
	; we exited the room
	;====================================
c15_check_done:

	lda	GAME_OVER		; if died or quit, jump to quit level
	cmp	#$ff
	beq	quit_level

	;=====================================================
	; Check to see which room to enter next
	; If it's a special value, means we succesfully beat the level
c15_defeated:
	lda     WHICH_ROOM
	cmp	#$ff
	bne	c15_new_room

	; point to next level
	; and exit to the level loader
	lda	#16
	sta	WHICH_LOAD
	rts


;===========================
; quit_level
;===========================

quit_level:
	jsr	TEXT			; text mode
	jsr	HOME			; clear screen
	lda	KEYRESET		; clear keyboard state

	lda	#0			; set to PAGE0
	sta	DRAW_PAGE

	lda	#<end_message		; print the end message
	sta	OUTL
	lda	#>end_message
	sta	OUTH

	jsr	move_and_print
	jsr	move_and_print

wait_loop:
	lda	KEYPRESS		; wait for keypress
	bpl	wait_loop

	lda	KEYRESET		; clear strobe

	lda	#0
	sta	GAME_OVER

	jmp	ootw_c15_restart	; restart level


;=========================================
;=========================================
; Ootw Checkpoint 15 -- End of the game
;=========================================
;=========================================

	; call once before entering for first time
ootw_c15_level_init:
	lda	#0
	sta	NUM_DOORS
	sta	BROKEN_GLASS
	sta	BRIDGE_COLLAPSE

	lda	#2			; REMOVE
	sta	WHICH_ROOM


	lda	#1
	sta	HAVE_GUN
	sta	DIRECTION		; right

	lda	#2			; REMOVE
;	lda	#22
	sta	PHYSICIST_X
	lda	#10
	sta	PHYSICIST_Y

	lda	#P_STANDING
	sta	PHYSICIST_STATE

	; set up aliens

	jsr	clear_aliens

	lda	#1
	sta	ALIEN_OUT

	lda	#1
	sta	alien0_room
	lda	#36
	sta	alien0_x
	lda	#8
	sta	alien0_y
	lda	#A_STANDING
	sta	alien0_state
	lda	#0
	sta	alien0_direction

	rts


	;===========================
	;===========================
	; enter new room
	;===========================
	;===========================

ootw_c15_setup_room_and_play:

	;==============================
	; each room init

	jsr	clear_lasers

	lda	#0
	sta	LEFT_SHOOT_LIMIT
	lda	#39
	sta	RIGHT_SHOOT_LIMIT

	;==============================
	; setup per-room variables

	lda	WHICH_CAVE
	bne	room1

	jsr	init_shields

	;===============================
	; Room0 -- with the bathers
	;===============================
room0:
	lda	#(20+128)
	sta	LEFT_LIMIT
	lda	#(39+128)
	sta	RIGHT_LIMIT

	; set right exit
	lda     #1
	sta     cer_smc+1

	; set left exit
	lda     #0
	sta     cel_smc+1

	lda	#20
	sta	PHYSICIST_Y

	; load background
	lda	#>(bath_end_rle)
	sta	GBASH
	lda	#<(bath_end_rle)

	jmp	room_setup_done

	;===============================
	; Room1 -- first walkway
	;===============================
room1:
	cmp	#1
	bne	room2


	;
first_shield:
        lda     #0
        sta     FIRST_SHIELD
        sta     shield_count

        lda     #1
        sta     shield_out
        lda     #34
        sta     shield_x

        lda     #8
        sta     shield_y

        inc     SHIELD_OUT


	; reset for animation
	lda	#0
	sta	FOREGROUND_COUNT
	sta	FRAMEL
	sta	FRAMEH

	lda	#(-4+128)
	sta	LEFT_LIMIT
	lda	#(39+128)
	sta	RIGHT_LIMIT

	; set right exit
	lda     #2
	sta     cer_smc+1

	; set left exit
	lda     #0
	sta     cel_smc+1

	lda	#8
	sta	PHYSICIST_Y

	; load background
	lda	#>(walkway1_rle)
	sta	GBASH
	lda	#<(walkway1_rle)

	jmp	room_setup_done

	;===============================
	; Room2 -- second walkway
	;===============================
room2:
	cmp	#2
	bne	room3

	lda	#(-4+128)
	sta	LEFT_LIMIT
	lda	#(39+128)
	sta	RIGHT_LIMIT

	; set right exit
	lda     #3
	sta     cer_smc+1

	; set left exit
	lda     #1
	sta     cel_smc+1

	lda	#8
	sta	PHYSICIST_Y

	lda	BROKEN_GLASS
	beq	unbroken_background

	; load background
	lda	#>(walkway2_after_rle)
	sta	GBASH
	lda	#<(walkway2_after_rle)

	jmp	room_setup_done

unbroken_background:
	; load background
	lda	#>(walkway2_rle)
	sta	GBASH
	lda	#<(walkway2_rle)

	jmp	room_setup_done

	;===============================
	; Room3 -- third walkway
	;===============================
room3:
	cmp	#3
	bne	room4

	lda	#(-4+128)
	sta	LEFT_LIMIT
	lda	#(39+128)
	sta	RIGHT_LIMIT

	; set right exit
	lda     #4
	sta     cer_smc+1

	; set left exit
	lda     #2
	sta     cel_smc+1

	lda	#8
	sta	PHYSICIST_Y

	; load background
	lda	#>(walkway3_rle)
	sta	GBASH
	lda	#<(walkway3_rle)

	jmp	room_setup_done

	;===============================
	; Room4 -- above pit
	;===============================
room4:
	cmp	#4
	bne	room5

	lda	#(-4+128)
	sta	LEFT_LIMIT
	lda	#(39+128)
	sta	RIGHT_LIMIT

	; set right exit
	lda     #5
	sta     cer_smc+1

	; set left exit
	lda     #3
	sta     cel_smc+1

	lda	#24
	sta	PHYSICIST_Y

	; load background
	lda	#>(above_pit_rle)
	sta	GBASH
	lda	#<(above_pit_rle)

	jmp	room_setup_done

	;===============================
	; Room5 -- final scene
	;===============================
room5:
;	cmp	#4
;	bne	room5

	lda	#(-4+128)
	sta	LEFT_LIMIT
	lda	#(39+128)
	sta	RIGHT_LIMIT

	; set right exit
	lda     #$ff		; exit level when done
	sta     cer_smc+1

	; set left exit
	lda     #4
	sta     cel_smc+1

	lda	#24
	sta	PHYSICIST_Y

	; load background
	lda	#>(final_rle)
	sta	GBASH
	lda	#<(final_rle)

;	jmp	room_setup_done







room_setup_done:

	sta	GBASL
	lda	#$c				; load to page $c00
	jsr	load_rle_gr			; tail call

	;=====================
	; setup walk collision
	jsr	recalc_walk_collision



ootw_room_already_set:
	;===========================
	; Enable graphics

	bit	LORES
	bit	SET_GR
	bit	FULLGR

	;===========================
	; Setup pages (is this necessary?)

	lda	#0
	sta	DRAW_PAGE
	lda	#1
	sta	DISP_PAGE

	;=================================
	; setup vars

	lda	#0
	sta	GAIT
	sta	GAME_OVER

	;============================
	;============================
	; Room Loop
	;============================
	;============================
room_loop:

	;================================
	; copy background to current page

	jsr	gr_copy_to_current

	;==================================
	; draw background action

;	lda	WHICH_ROOM

bg_room0:

;	cmp	#0
;	bne	c15_no_bg_action

;	lda	FRAMEL
;	and	#$c
;	lsr
;	tay


;	lda	#11
;	sta	XPOS
;	lda	#24
;	sta	YPOS

;	lda	recharge_bg_progression,Y
;	sta	INL
;	lda	recharge_bg_progression+1,Y
;	sta	INH

;	jsr	put_sprite

c15_no_bg_action:

	;===============================
	; check keyboard
	;===============================

	jsr	handle_keypress

	;===============================
	; move physicist
	;===============================

	jsr	move_physicist

	;===============================
	; move friend
	;===============================

	jsr	move_friend


	;===============================
	; check room limits
	;===============================

	jsr	check_screen_limit

	;===============================
	; adjust floor if necessary
	;===============================
	; no sloped floors in c15

	;=====================================
	; draw physicist
	;=====================================

	jsr	draw_physicist

	;=====================================
	; draw friend
	;=====================================

	jsr	draw_friend


	;=====================================
	; draw alien
	;=====================================
	lda	ALIEN_OUT
	beq	no_draw_alien

	jsr	move_alien
	jsr	draw_alien
no_draw_alien:

	;=====================================
	; handle gun
	;=====================================

	jsr	handle_gun

	;=====================================
	; draw foreground action
	;=====================================

	lda	WHICH_ROOM
	cmp	#0
	beq	c15_room0_foreground
	jmp	c15_room1_foreground

c15_room0_foreground:
	; Room 0 laser fire

	lda	laser1_out
	bne	handle_laser2

handle_laser1:
	jsr	random16
	lda	SEEDL
	and	#$7			; 0..7 (+1 carry)
	adc	#20			; make random
	sta	laser1_y

	lda	#1			; right
	sta	laser1_direction

	lda	#0
	sta	laser1_start
	sta	laser1_count

	lda	#10
	sta	laser1_end

	lda	#$ff
	sta	laser1_out

	jmp	done_handle_laser

handle_laser2:
	lda	laser2_out
	bne	done_handle_laser

done_handle_laser:

	; Room 0 draw guard
c15_draw_fg_guard:

	; real game it's not quite so regular, double shot eventually

	; every so often, shoots
	; for frames 0 and 1 every 32 ($1F)

	lda	FRAMEL
	and	#$1f
	cmp	#3
	bcs	fg_guard_noshoot	; bgt

fg_guard_shoot:
	lda	#$ff
	bne	fg_guard_draw

fg_guard_noshoot:
	lda	#$00

fg_guard_draw:
	sta	XPOS
	lda	#22
	sta	YPOS
	lda	#<guard_sprite
	sta	INL
	lda	#>guard_sprite
	sta	INH
	jsr	put_sprite_crop


	; draw forground lasers

	lda	FRAMEL
	and	#$1f
	cmp	#3
	bcs	fg_guard_no_laser		; bge

	lda	#9
	sta	XPOS
	lda	#20
	sta	YPOS
	lda	#<guard_laser
	sta	INL
	lda	#>guard_laser
	sta	INH
	jsr	put_sprite

fg_guard_no_laser:

	; draw from-bottom-laser


	lda	FRAMEL
	and	#$20
	beq	skip_this

	lda	FRAMEL
	and	#$18
	lsr
	lsr
	tay

	lda	shot_lookup1,Y
	sta	INL
	lda	shot_lookup1+1,Y
	sta	INH

	jsr	draw_trapezoid
skip_this:

	jmp	c15_no_fg_action

	;=====================================
	; Room 1 foreground
	;=====================================

c15_room1_foreground:
	cmp	#1
	beq	actual_room1_foreground
	jmp	c15_room2_foreground

actual_room1_foreground:

	; run soldier/laser in the front

	; every 256 frames start a laser
	; if 1024 start a soldier

	lda	FRAMEL
	bne	not_new_walk

	lda	FRAMEH
	and	#$3
	beq	start_soldier

start_blast:

	ldy	#26
	sty	FOREGROUND_COUNT
	bne	not_new_walk

start_soldier:

	ldy	#2
	sty	FOREGROUND_COUNT


not_new_walk:

	ldy	FOREGROUND_COUNT
	beq	skip_enemy_walk

	cpy	#24
	beq	reset_walk
	cpy	#34
	beq	reset_walk

	bne	do_enemy_walk

reset_walk:
	ldy	#0
	sty	FOREGROUND_COUNT
	beq	skip_enemy_walk

do_enemy_walk:

	lda	FRAMEL
	and	#$3
	bne	no_update_enemy_walk

	lda     enemy_walking_sequence,y
        sta     GBASL
        lda     enemy_walking_sequence+1,y
        sta     GBASH

	iny
	iny
	sty	FOREGROUND_COUNT

	lda     #$10                    ; load to $1000
        jsr     load_rle_gr

no_update_enemy_walk:

	; can we only overlay bottom half of screen?
	; current overlay code starts at CV and counts to zero :(

	jsr	gr_overlay_noload


skip_enemy_walk:

	; occasional laser

	; FRAMEL: every 8th frame (111) update, draw 4-long animation

	; cycle through 4 possible shots
	; FIXME: we could randomly adjust some of the parameters?

	lda	FRAMEL
	and	#$18
	lsr
	lsr
	tay

	lda	FRAMEL
	and	#$60
	beq	shot4_base
	cmp	#$20
	beq	shot3_base
	cmp	#$40
	beq	shot2_base

shot1_base:
	lda	shot_lookup1,Y
	sta	INL
	lda	shot_lookup1+1,Y
	jmp	draw_shot

shot2_base:
	lda	shot_lookup2,Y
	sta	INL
	lda	shot_lookup2+1,Y
	jmp	draw_shot

shot3_base:
	lda	shot_lookup3,Y
	sta	INL
	lda	shot_lookup3+1,Y
	jmp	draw_shot

shot4_base:
	lda	shot_lookup4,Y
	sta	INL
	lda	shot_lookup4+1,Y

draw_shot:
	sta	INH
	jsr	draw_trapezoid


	jmp	c15_no_fg_action


	;=====================================
	; Room 2 foreground
	;=====================================

c15_room2_foreground:
	cmp	#2
	beq	actual_room2_foreground
	jmp	c15_room3_foreground

actual_room2_foreground:

	; after trigger, have some shooting

	; if already triggered, skip
	lda	BROKEN_GLASS
	cmp	#14
	bne	not_broken
	jmp	c15_no_fg_action

not_broken:
	cmp	#0
	bne	break_glass

	; once physicist past 5, start breakout

	lda	PHYSICIST_X
	cmp	#5
	bcs	break_glass
	jmp	c15_no_fg_action

break_glass:

	ldy	BROKEN_GLASS
	lda     glass_breaking_sequence,y
        sta     GBASL
        lda     glass_breaking_sequence+1,y
        sta     GBASH


	lda	FRAMEL
	and	#$3
	bne	no_inc_break_glass

	iny
	iny
	sty	BROKEN_GLASS
no_inc_break_glass:

	lda	#$10		; load to $1000
	jsr	load_rle_gr

	jsr	gr_overlay_noload

	ldy	BROKEN_GLASS
	cpy	#14
	bne	no_update_break_glass

	; load new background at end

	lda	#>(walkway2_after_rle)
	sta	GBASH
	lda	#<(walkway2_after_rle)
	sta	GBASL
	lda	#$c		; load to $c00
	jsr	load_rle_gr

	; activate friend
	lda	#2
	sta	friend_room
	lda	#FAI_RUNTO_PANEL
	sta	friend_ai_state
	lda	#F_RUNNING
	sta	friend_state
	lda     #16
        sta     friend_x
        lda     #8
        sta     friend_y
	lda	#1
	sta	friend_direction


no_update_break_glass:


	;=====================================
	; Room 3 foreground
	;=====================================

c15_room3_foreground:
	cmp	#3
	beq	actual_room3_foreground
	jmp	c15_draw_friend_cliff

actual_room3_foreground:

	; after trigger, have some shooting

	; if already triggered, skip
	lda	BRIDGE_COLLAPSE
	cmp	#12
	bcs	draw_bridge			; bge

	cmp	#0
	bne	collapse_bridge

	; once physicist past 20, start breakout

	lda	PHYSICIST_X
	cmp	#16
	bcc	c15_no_fg_action		; blt

collapse_bridge:

	ldy	BRIDGE_COLLAPSE
	lda     bridge_sequence,y
        sta     GBASL
        lda     bridge_sequence+1,y
        sta     GBASH

	lda	FRAMEL
	and	#$3
	bne	no_inc_bridge_collapse

	iny
	iny
	sty	BRIDGE_COLLAPSE
no_inc_bridge_collapse:

	lda	#$10		; load to $1000
	jsr	load_rle_gr

draw_bridge:
	jsr	gr_overlay_noload

	ldy	BRIDGE_COLLAPSE
	cpy	#12
	bne	no_update_bridge_collapse

	lda	#P_FALLING_DOWN
	sta	PHYSICIST_STATE

	lda	#48
	sta	fall_down_destination_smc+1

	iny
	sty	BRIDGE_COLLAPSE

no_update_bridge_collapse:

	; Room 5 friend slowly working to left
c15_draw_friend_cliff:


c15_no_fg_action:

	;====================
	; activate fg objects
	;====================
;c2_fg_check_jail1:
;	lda	WHICH_JAIL
;	cmp	#1
;	bne	c2_fg_check_jail2
;
;	lda	CART_OUT
;	bne	c2_fg_check_jail2
;
;	inc	CART_OUT


	;================
	; move fg objects
	;================
c15_move_fg_objects:

;	lda	CART_OUT
;	cmp	#1
;	bne	cart_not_out

	; move cart

;	lda	FRAMEL
;	and	#$3
;	bne	cart_not_out
;
;	inc	CART_X
;	lda	CART_X
;	cmp	#39
;	bne	cart_not_out
;	inc	CART_OUT


	;====================================
	; page flip
	;====================================

	jsr	page_flip

	;====================================
	; inc frame count
	;====================================

	inc	FRAMEL
	bne	room_frame_no_oflo
	inc	FRAMEH
room_frame_no_oflo:

	;==========================
	; check if done this level
	;==========================

	lda	GAME_OVER
	beq	still_in_room

	cmp	#$ff			; if $ff, we died
	beq	done_room

	;===============================
	; check if exited room to right
	cmp	#1
	beq	room_exit_left

	;=================
	; exit to right

room_right_yes_exit:

	lda	#0
	sta	PHYSICIST_X
cer_smc:
	lda	#$0			; smc+1 = exit location
	sta	WHICH_ROOM
	jmp	done_room

	;=====================
	; exit to left

room_exit_left:

	lda	#37
	sta	PHYSICIST_X
cel_smc:
	lda	#0		; smc+1
	sta	WHICH_ROOM
	jmp	done_room

	; loop forever
still_in_room:
	lda	#0
	sta	GAME_OVER

	jmp	room_loop

done_room:
	rts

end_message:
.byte	8,10,"PRESS RETURN TO CONTINUE",0
.byte	11,20,"ACCESS CODE: ANKD",0

.include "text_print.s"
.include "gr_pageflip.s"
.include "gr_unrle.s"
.include "gr_vlin.s"
;.include "gr_fast_clear.s"
.include "gr_copy.s"
;.include "gr_copy_offset.s"
.include "gr_putsprite.s"
;.include "gr_putsprite_flipped.s"
.include "gr_putsprite_crop.s"
.include "gr_offsets.s"
;.include "gr_offsets_hl.s"
.include "gr_hlin.s"
.include "keyboard.s"
.include "gr_overlay.s"
.include "gr_run_sequence.s"
.include "random16.s"
.include "gr_trapezoid.s"

.include "physicist.s"
.include "alien.s"
.include "friend.s"

.include "gun.s"
.include "laser.s"
.include "alien_laser.s"
.include "blast.s"
.include "shield.s"

.include "door.s"
.include "collision.s"

; room backgrounds
.include "ootw_graphics/l15final/ootw_c15_bath.inc"
.include "ootw_graphics/l15final/ootw_c15_final.inc"
; sprites
.include "ootw_graphics/sprites/physicist.inc"
.include "ootw_graphics/sprites/alien.inc"
.include "ootw_graphics/sprites/friend.inc"
; animations
.include "ootw_graphics/l15final/ootw_c15_walk.inc"
.include "ootw_graphics/l15final/ootw_c15_walkway.inc"
.include "ootw_graphics/l15final/ootw_c15_bridge.inc"
.include "ootw_graphics/l15final/ootw_c15_fall.inc"


;=======================
; Bath intro

bath_intro:
	;===========================
	; Enable graphics

	bit	LORES
	bit	SET_GR
	bit	FULLGR

	bit	KEYRESET

	;===========================
	; Setup pages (is this necessary?)

	lda	#0
	sta	DRAW_PAGE
	lda	#1
	sta	DISP_PAGE

	lda	#<bath_arrival_sequence
	sta	INTRO_LOOPL
	lda	#>bath_arrival_sequence
	sta	INTRO_LOOPH

        jmp	run_sequence

;	rts

;=======================
; Bath Arrival Sequence

bath_arrival_sequence:
	.byte 255
	.word bath_00_rle
	.byte 25
	.word bath_01_rle
	.byte 25
	.word bath_02_rle
	.byte 25
	.word bath_03_rle
	.byte 25
	.word bath_04_rle
	.byte 25
	.word bath_05_rle
	.byte 25
	.word bath_06_rle
	.byte 25
	.word bath_07_rle
	.byte 25
	.word bath_08_rle
	.byte 25
	.word bath_09_rle
	.byte 25
	.word bath_10_rle
	.byte 25
	.word bath_11_rle
	.byte 25
	.word bath_12_rle
	.byte 25
	.word bath_13_rle
	.byte 25
	.word bath_14_rle
	.byte 25
	.word bath_15_rle
	.byte 25
	.word bath_16_rle
	.byte 25
	.word bath_17_rle
	.byte 25
	.word bath_18_rle
	.byte 25
	.word bath_19_rle
	.byte 25
	.word bath_20_rle
	.byte 25
	.word bath_21_rle
	.byte 25
	.word bath_22_rle
	.byte 25
	.word bath_23_rle
	.byte 25
	.word bath_24_rle
	.byte 25
	.word bath_25_rle
	.byte 25
	.word bath_26_rle
	.byte 25
	.word bath_27_rle
	.byte 25
	.word bath_28_rle
	.byte 25
	.word bath_29_rle
	.byte 25
	.word bath_30_rle
	.byte 25
	.word bath_31_rle
	.byte 25
	.word bath_32_rle
	.byte 25
	.word bath_33_rle
	.byte 25
	.word bath_34_rle
	.byte 25
	.word bath_35_rle
	.byte 25
	.word bath_35_rle
	.byte 0


;=======================
; guard sprite
guard_sprite:
	.byte 10,13
	.byte $7A,$7A,$7A,$7A,$AA,$AA,$AA,$AA,$AA,$AA
	.byte $77,$77,$77,$77,$77,$AA,$AA,$AA,$AA,$AA
	.byte $77,$77,$77,$77,$77,$AA,$AA,$AA,$0A,$00
	.byte $00,$00,$00,$77,$A7,$AA,$AA,$7A,$70,$AA
	.byte $00,$00,$00,$00,$AA,$7A,$77,$77,$77,$7A
	.byte $00,$00,$00,$70,$77,$77,$77,$77,$77,$77
	.byte $00,$00,$70,$77,$77,$77,$77,$77,$AA,$AA
	.byte $00,$00,$07,$77,$77,$77,$A7,$AA,$AA,$AA
	.byte $00,$00,$00,$07,$A7,$A7,$AA,$AA,$AA,$AA
	.byte $00,$00,$00,$00,$AA,$AA,$AA,$AA,$AA,$AA
	.byte $00,$00,$00,$00,$AA,$AA,$AA,$AA,$AA,$AA
	.byte $00,$00,$00,$00,$AA,$AA,$AA,$AA,$AA,$AA
	.byte $00,$00,$00,$00,$AA,$AA,$AA,$AA,$AA,$AA

;=======================
; guard laser
guard_laser:
;	.byte 15,4
;	.byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$1A,$1A,$A1
;	.byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$1A,$1A,$A1,$A1,$AA,$AA,$AA
;	.byte $AA,$AA,$AA,$AA,$1A,$1A,$11,$A1,$A1,$AA,$AA,$AA,$AA,$AA,$AA
;	.byte $1A,$1A,$11,$A1,$A1,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA

	.byte 15,3
	.byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$1A,$1A,$1A
	.byte $AA,$AA,$AA,$AA,$AA,$AA,$1A,$1A,$1A,$11,$A1,$A1,$A1,$AA,$AA
	.byte $1A,$1A,$1A,$11,$A1,$A1,$A1,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA


shot_lookup1:
	.word shot1_frame1
	.word shot1_frame2
	.word shot1_frame3
	.word shot1_hole

shot_lookup2:
	.word shot2_frame1
	.word shot2_frame2
	.word shot2_frame3
	.word shot2_hole

shot_lookup3:
	.word shot3_frame1
	.word shot3_frame2
	.word shot3_frame3
	.word shot3_hole

shot_lookup4:
	.word shot4_frame1
	.word shot4_frame2
	.word shot4_frame3
	.word shot4_hole


shot1_frame1:
	.byte	2,128	; LEFT SLOPE H/L
	.byte	0,128	; RIGHT SLOPE H/L
	.byte	4,0	; STARTX H/L
	.byte	17,0	; ENDX H/L
	.byte	36,46	; ENDY/STARTY
shot1_frame2:
	.byte	2,0	; LEFT SLOPE H/L
	.byte	0,$80	; RIGHT SLOPE H/L
	.byte	5,0	; STARTX H/L
	.byte	16,128	; ENDX H/L
	.byte	30,46	; ENDY/STARTY
shot1_frame3:
	.byte	2,0	; LEFT SLOPE H/L
	.byte	2,0	; RIGHT SLOPE H/L
	.byte	19,0	; STARTX H/L
	.byte	21,9	; ENDX H/L
	.byte	28,32	; ENDY/STARTY
shot1_hole:
	.byte	21,28	; LEFT SLOPE H/L
	.byte	0,0	; RIGHT SLOPE H/L
	.byte	0,0	; STARTX H/L
	.byte	0,0	; ENDX H/L
	.byte	0,$ff	; ENDY/STARTY

	; shot 2

shot2_frame1:
	.byte	$ff,00	; LEFT SLOPE H/L
	.byte	$fe,00	; RIGHT SLOPE H/L
	.byte	19,0	; STARTX H/L
	.byte	32,0	; ENDX H/L
	.byte	28,46	; ENDY/STARTY
shot2_frame2:
	.byte	$ff,00	; LEFT SLOPE H/L
	.byte	$fe,$80	; RIGHT SLOPE H/L	; approximately 1/3?
	.byte	17,0	; STARTX H/L
	.byte	23,0	; ENDX H/L
	.byte	18,36	; ENDY/STARTY

shot2_frame3:
	.byte	0,0	; LEFT SLOPE H/L
	.byte	0,0	; RIGHT SLOPE H/L
	.byte	7,0	; STARTX H/L
	.byte	9,0	; ENDX H/L
	.byte	18,20	; ENDY/STARTY
shot2_hole:
	.byte	6,20	; LEFT SLOPE H/L
	.byte	0,0	; RIGHT SLOPE H/L
	.byte	0,0	; STARTX H/L
	.byte	0,0	; ENDX H/L
	.byte	0,$ff	; ENDY/STARTY

	; shot3
shot3_frame1:
	.byte	$FE,0	; LEFT SLOPE H/L
	.byte	$FE,$80	; RIGHT SLOPE H/L
	.byte	37,0	; STARTX H/L
	.byte	40,0	; ENDX H/L
	.byte	18,24	; ENDY/STARTY
shot3_frame2:
	.byte	$FD,0	; LEFT SLOPE H/L
	.byte	$FD,0	; RIGHT SLOPE H/L
	.byte	19,0	; STARTX H/L
	.byte	23,0	; ENDX H/L
	.byte	12,16	; ENDY/STARTY
shot3_frame3:
	.byte	0,0	; LEFT SLOPE H/L
	.byte	0,0	; RIGHT SLOPE H/L
	.byte	9,0	; STARTX H/L
	.byte	10,0	; ENDX H/L
	.byte	10,12	; ENDY/STARTY
shot3_hole:
	.byte	7,12	; LEFT SLOPE H/L
	.byte	0,0	; RIGHT SLOPE H/L
	.byte	0,0	; STARTX H/L
	.byte	0,0	; ENDX H/L
	.byte	0,$ff	; ENDY/STARTY


	; shot4

shot4_frame1:
	.byte	$FD,$00	; LEFT SLOPE H/L
	.byte	$FF,$80	; RIGHT SLOPE H/L
	.byte	13,0	; STARTX H/L
	.byte	18,0	; ENDX H/L
	.byte	$FE,6	; ENDY/STARTY
shot4_frame2:
	.byte	$FD,$00	; LEFT SLOPE H/L
	.byte	$FF,$00	; RIGHT SLOPE H/L
	.byte	22,0	; STARTX H/L
	.byte	24,0	; ENDX H/L
	.byte	0,10	; ENDY/STARTY
shot4_frame3:
	.byte	0,0	; LEFT SLOPE H/L
	.byte	0,0	; RIGHT SLOPE H/L
	.byte	24,0	; STARTX H/L
	.byte	25,9	; ENDX H/L
	.byte	10,12	; ENDY/STARTY
shot4_hole:
	.byte	23,12	; LEFT SLOPE H/L
	.byte	0,0	; RIGHT SLOPE H/L
	.byte	0,0	; STARTX H/L
	.byte	0,0	; ENDX H/L
	.byte	0,$ff	; ENDY/STARTY




; shot notes
; + from bottom-right to mid-left
; + from top-center to mid-right
; + from mid-right to mid-left
; + straight across bottom
; + from top-left to mid-right
; + from center-right to mid-left
;    

enemy_walking_sequence:
	.word 0			; makes code easier
	.word walk00_rle
	.word walk01_rle
	.word walk02_rle
	.word walk03_rle
	.word walk04_rle
	.word walk05_rle
	.word walk06_rle
	.word walk07_rle
	.word walk08_rle
	.word walk09_rle
	.word walk10_rle
	.word 0
bigshot_sequence:
	.word bigshot01_rle
	.word bigshot02_rle
	.word bigshot03_rle
	.word bigshot04_rle

glass_breaking_sequence:
	.word crash1_rle	; 2
	.word crash2_rle	; 4
	.word crash3_rle	; 6
	.word crash4_rle	; 8
	.word crash5_rle	; 10
	.word crash6_rle	; 12
	.word crash7_rle	; 14

bridge_sequence:
	.word lshot1_rle	; 2
	.word lshot2_rle	; 4
	.word lshot3_rle	; 6
	.word lshot4_rle	; 8
	.word lshot5_rle	; 10
	.word lshot6_rle	; 12



; grab sequence
; note, in the actual game both the background and the falling is not
; 100% the same as the fall sequence, but it's close enough to not
; really be worth the trouble/space to do them separately

				; grab52 -> fall01
				; grab53 -> fall02 shifted right by 2?
				; grab54 -> fall03 shifted right by 4?
				; grab55 -> fall04 shifted right by 4?
				; grab56 -> fall05 shifted right by 4?
				; grab57 -> fall06 shifted right by 4?
				; grab58 -> fall07 shifted right by 4?
				; grab59 -> fall08 shifted right by 4?
				; grab60 -> fall09 shifted right by 4?
				; grab61 -> fall10 shifted right by 4?
				; grab62 -> fall11 shifted right by 4?
				; grab63 -> fall12 shifted right by 4?
				; grab64 -> fall13 shifted right by 4?
				; grab65 -> fall14 shifted right by 4?
				; grab66 -> fall15 shifted right by 4?
