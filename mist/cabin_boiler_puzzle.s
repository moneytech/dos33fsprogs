	; this is a painful one
	; mostly because the tree puzzle is sort of obscure in the original

	; in original you get a match, then light it
	;	the match will flicker and burn out if you go outside

	; light the pilot, it will turn red

	; boiler PSI starts at zero
	;	turn once clockwise, fire starts, nothing else?
	;	turn once counter-clockwise fire turns off
	;	turn twice CW -> ?
	;	turn 3 CW -> ?
	;	turn 4, 5, 6, 7, 8, 9, 10, 11, 12,  CW -> ?
	;		can turn up to 25
	;	at 12 starts gradually going up
	;		(needle swings hits end, waits like 5s, goes up)
	; PSI counts 0 to 24?
	;	0 - basement
	;	1 - down 1/2
	;	2 - down 1
	;	3 - half out
	;	4 - all out (can get on)    *
	;	5 -
	;	6 - *
	;	7 -
	;	8 - *
	;	9 -
	;	10 - *
	;	11 -
	;	12 - * (top)  (can look down at all spots)
	; button takes you down a level, but only to ground floor
	;	will actually  bump you back to Level 3 if you press on ground
	; button does nothing in basement
	; dial in basement does same as one upstairs

;     0123456789012345678901234
;	\ \ \ \ \ : / / / / /
;	        P S I
;      \

; BOILER_VALVE
; BOILER_LEVEL: high bit is if pilot lit, low bits are PSI
; BOILER_TOTAL:
;	0...128 warming up
;	then if valve>12 inc level, when hit 15 inc tree
;		if valve<12 dec level, when hit 0 dec tree
;	rate of adding is (valve-12)  0..12 / 4 = 0..3
;		0 = FRAMEL&7f==0
;		1 = FRAMEL&3f==0
;		2 = FRAMEL&1f==0
;		3 = FRAMEL&7==0
; Make noise when change tree level

update_boiler_state:

	; if pilot not lit, nothing to do
	lda	BOILER_LEVEL
	bpl	done_boiler_state

	lda	BOILER_VALVE
;	beq	done_boiler_state
	sec
	sbc	#12

	bpl	skip_abs

	eor	#$ff
	clc
	adc	#$1
skip_abs:

	; adjust speed based on valve position

	; div by 4
	lsr
	lsr
	tay
	lda	FRAMEL
	cpy	#0
	beq	speed_slowest
	cpy	#1
	beq	speed_slow
	cpy	#2
	beq	speed_fast
speed_fastest:
	and	#$f
speed_fast:
	and	#$1f
speed_slow:
	and	#$3f
speed_slowest:
	and	#$7f

	beq	actually_adjust_boiler

	rts

actually_adjust_boiler:
	lda	BOILER_VALVE
	cmp	#12
	bcs	valve_positive
	bcc	valve_negative

valve_positive:
	jsr	inc_boiler
	jmp	done_boiler_state

valve_negative:
	jsr	dec_boiler
done_boiler_state:

	rts

inc_boiler:
	lda	BOILER_LEVEL
	and	#$7f
	cmp	#25
	beq	inc_boiler_overflow
	inc	BOILER_LEVEL
	rts

inc_boiler_overflow:
	lda	TREE_LEVEL
	cmp	#6
	beq	tree_at_top

	lda	BOILER_LEVEL
	and	#$80
	sta	BOILER_LEVEL

	inc	TREE_LEVEL
	jsr	change_tree_level

tree_at_top:
	rts

dec_boiler:
	lda	BOILER_LEVEL
	and	#$1f
	cmp	#0
	beq	dec_boiler_overflow
	dec	BOILER_LEVEL
	rts

dec_boiler_overflow:
	lda	TREE_LEVEL
	beq	tree_at_bottom

	lda	#$80|24
	sta	BOILER_LEVEL

	dec	TREE_LEVEL
	jsr	change_tree_level

tree_at_bottom:
	rts


change_tree_level:
	jsr	cabin_update_state

	jsr	change_direction

	jsr	long_beep

	rts


tree_base_backgrounds:
	.word	tree_base_n_lzsa	; 0 basement
	.word	tree_base_n_lzsa	; 1 underground
	.word	tree_base_l4_n_lzsa	; 2 ground
	.word	tree_base_l6_n_lzsa	; 3 L6
	.word	tree_base_n_lzsa	; 4 L8
	.word	tree_base_n_lzsa	; 5 L10
	.word	tree_base_n_lzsa	; 6 TOP

tree_base_up_backgrounds:
	.word	tree_base_up_lzsa	; 0 basement
	.word	tree_base_up_l2_lzsa	; 1 underground
	.word	tree_base_up_l4_lzsa	; 2 ground
	.word	tree_base_up_l6_lzsa	; 3 L6
	.word	tree_base_up_l8_lzsa	; 4 L8
	.word	tree_base_up_l10_lzsa	; 5 L10
	.word	tree_base_up_l12_lzsa	; 6 TOP

tree_elevator_backgrounds:
	.word	tree_elevator_basement_s_lzsa	; 0 basement
	.word	tree_elevator_l2_lzsa	; 1 underground
	.word	tree_elevator_l4_lzsa	; 2 ground
	.word	tree_elevator_l6_lzsa	; 3 L6
	.word	tree_elevator_l8_lzsa	; 4 L8
	.word	tree_elevator_l10_lzsa	; 5 L10
	.word	tree_elevator_l12_lzsa	; 6 TOP

tree_basement_backgrounds:
	.word	tree_basement_n_lzsa	; 0 basement
	.word	tree_basement_noelev_n_lzsa	; 1 underground
	.word	tree_basement_noelev_n_lzsa	; 2 ground
	.word	tree_basement_noelev_n_lzsa	; 3 L6
	.word	tree_basement_noelev_n_lzsa	; 4 L8
	.word	tree_basement_noelev_n_lzsa	; 5 L10
	.word	tree_basement_noelev_n_lzsa	; 6 TOP


tree_elevator_exits:
	.byte	CABIN_TREE_BASEMENT	; 0 basement
	.byte	$ff			; 1 underground
	.byte	CABIN_BIG_TREE		; 2 ground
	.byte	$ff			; 3 L6
	.byte	$ff			; 4 L8
	.byte	$ff			; 5 L10
	.byte	CABIN_TREE_LOOK_DOWN	; 6 TOP

tree_entrance:
	.byte	CABIN_TREE_LOOK_UP	; 0 basement
	.byte	CABIN_TREE_LOOK_UP	; 1 underground
	.byte	CABIN_TREE_ELEVATOR	; 2 ground
	.byte	CABIN_TREE_LOOK_UP	; 3 L6
	.byte	CABIN_TREE_LOOK_UP	; 4 L8
	.byte	CABIN_TREE_LOOK_UP	; 5 L10
	.byte	CABIN_TREE_LOOK_UP	; 6 TOP

	; south if getting on elevator
	; north if looking up
tree_entrance_dir:
	.byte	DIRECTION_N		; 0 basement
	.byte	DIRECTION_N		; 1 underground
	.byte	DIRECTION_S		; 2 ground
	.byte	DIRECTION_N		; 3 L6
	.byte	DIRECTION_N		; 4 L8
	.byte	DIRECTION_N		; 5 L10
	.byte	DIRECTION_N		; 6 TOP

tree_basement_exit:
	.byte	CABIN_TREE_ELEVATOR	; 0 basement
	.byte	$ff			; 1 underground
	.byte	$ff			; 2 ground
	.byte	$ff			; 3 L6
	.byte	$ff			; 4 L8
	.byte	$ff			; 5 L10
	.byte	$ff			; 6 TOP



	;===================================
	; update backgrounds based on state
	;===================================
cabin_update_state:

	; update tree base background

	ldy	#LOCATION_NORTH_BG
	lda	TREE_LEVEL
	asl
	tax
	lda	tree_base_backgrounds,X
	sta	location7,Y				; CABIN_BIG_TREE
	lda	tree_base_backgrounds+1,X
	sta	location7+1,Y				; CABIN_BIG_TREE

	; update tree up background
	lda	tree_base_up_backgrounds,X
	sta	location14,Y				; CABIN_TREE_LOOK_UP
	lda	tree_base_up_backgrounds+1,X
	sta	location14+1,Y				; CABIN_TREE_LOOK_UP

	; update basement background
	lda	tree_basement_backgrounds,X
	sta	location9,Y				; CABIN_TREE_BASEMENT
	lda	tree_basement_backgrounds+1,X
	sta	location9+1,Y				; CABIN_TREE_BASEMENT

	; update tree elevator background

	ldy	#LOCATION_SOUTH_BG
	lda	tree_elevator_backgrounds,X
	sta	location8,Y				; CABIN_TREE_ELEVATOR
	lda	tree_elevator_backgrounds+1,X
	sta	location8+1,Y				; CABIN_TREE_ELEVATOR

	; update if you can get into tree
	lda	TREE_LEVEL
	tax
	ldy	#LOCATION_NORTH_EXIT
	lda	tree_entrance,X
	sta	location7,Y				; CABIN_BIG_TREE
	ldy	#LOCATION_NORTH_EXIT_DIR
	lda	tree_entrance_dir,X
	sta	location7,Y				; CABIN_BIG_TREE

	; update elevator exit

	ldy	#LOCATION_SOUTH_EXIT
	lda	tree_elevator_exits,X
	sta	location8,Y				; CABIN_TREE_ELEVATOR

	; update basement exit

	ldy	#LOCATION_NORTH_EXIT
	lda	tree_basement_exit,X
	sta	location9,Y				; CABIN_TREE_BASEMENT

	rts

	;==========================
	; valve clicked in basement

valve_clicked_basement:
	lda	CURSOR_X
	cmp	#8
	bcc	valve_dec
	bcs	valve_inc

	;==================================
	; goto safe or valve (cabin boiler)

goto_safe_or_valve:
	lda	DIRECTION
	and	#$f
	cmp	#DIRECTION_W
	beq	goto_safe

valve_clicked_cabin:
	lda	CURSOR_X
	cmp	#33
	bcc	valve_dec
	bcs	valve_inc

valve_dec:
	lda	BOILER_VALVE
	beq	done_valve
	dec	BOILER_VALVE
	jmp	done_valve

valve_inc:
	lda	BOILER_VALVE
	cmp	#25
	bcs	done_valve
	inc	BOILER_VALVE

done_valve:
	rts


	;====================
	; safe was clicked
	;====================
goto_safe:
	lda	#CABIN_SAFE
	sta	LOCATION
	jmp	change_location


	;====================
	; open safe was touched
	;====================
	; close safe or take/light match

	; how does this interact with holding a page?

touch_open_safe:

	lda	CURSOR_X
	cmp	#21
	bcc	handle_matches

	; touching door
touching_safe_door:
	lda	#CABIN_SAFE
	sta	LOCATION
	jmp	change_location

handle_matches:
	lda	CURSOR_Y
	cmp	#32
	bcc	not_matches
	cmp	#41
	bcs	not_matches

	lda	HOLDING_ITEM
	cmp	#HOLDING_LIT_MATCH
	beq	not_matches
	cmp	#HOLDING_MATCH
	beq	light_match

	; not a match yet
take_match:
	lda	#HOLDING_MATCH
	sta	HOLDING_ITEM
	bne	not_matches	; bra

light_match:
	lda	#HOLDING_LIT_MATCH
	sta	HOLDING_ITEM

not_matches:
	rts



	;====================
	; safe was touched
	;====================
touch_safe:

	lda	CURSOR_Y

	; check if buttons
	cmp	#26		; blt
	bcc	safe_buttons

	; check if handle
	cmp	#34
	bcs	pull_handle	; bge

	; else do nothing
	rts


pull_handle:

	lda	SAFE_HUNDREDS
	cmp	#7
	bne	wrong_combination
	lda	SAFE_TENS
	cmp	#2
	bne	wrong_combination
	lda	SAFE_ONES
	cmp	#4
	bne	wrong_combination

	lda	#CABIN_OPEN_SAFE
	sta	LOCATION

	lda	#DIRECTION_W|DIRECTION_ONLY_POINT
	sta	DIRECTION

	jmp	change_location

wrong_combination:
	rts

safe_buttons:
	jsr	click_speaker

	lda	CURSOR_X
	cmp	#13		; not a button
	bcc	no_button
	cmp	#19
	bcc	hundreds_inc
	cmp	#25
	bcc	tens_inc
	bcs	ones_inc

no_button:
	rts

hundreds_inc:
	sed
	lda	SAFE_HUNDREDS
	clc
	adc	#$1
	cld
	and	#$f
	sta	SAFE_HUNDREDS

	rts

tens_inc:
	sed
	lda	SAFE_TENS
	clc
	adc	#$1
	cld
	and	#$f
	sta	SAFE_TENS

	rts

ones_inc:
	sed
	lda	SAFE_ONES
	clc
	adc	#$1
	cld
	and	#$f
	sta	SAFE_ONES

	rts



	;==============================
	; draw the numbers on the safe
	;==============================
draw_safe_combination:

	; hundreds digit

	lda	SAFE_HUNDREDS
	and	#$f
	asl
	tay

	lda	number_sprites,Y
	sta	INL
	lda	number_sprites+1,Y
	sta	INH

	lda	#15
	sta	XPOS
	lda	#8
	sta	YPOS

	jsr	put_sprite_crop

	; tens digit

	lda	SAFE_TENS
	and	#$f
	asl
	tay

	lda	number_sprites,Y
	sta	INL
	lda	number_sprites+1,Y
	sta	INH

	lda	#21
	sta	XPOS
	lda	#8
	sta	YPOS

	jsr	put_sprite_crop

	; ones digit

	lda	SAFE_ONES
	and	#$f
	asl
	tay

	lda	number_sprites,Y
	sta	INL
	lda	number_sprites+1,Y
	sta	INH

	lda	#27
	sta	XPOS
	lda	#8
	sta	YPOS

	jsr	put_sprite_crop

	rts



	; valve sprites
valve_sprites:
	.word valve0_sprite
	.word valve1_sprite
	.word valve2_sprite
	.word valve3_sprite

valve0_sprite:
	.byte 6,6
	.byte $AA,$1A,$11,$11,$1A,$AA
	.byte $1A,$A1,$11,$AA,$A1,$11
	.byte $11,$AA,$d1,$1A,$1A,$11
	.byte $11,$A1,$A1,$1A,$AA,$11
	.byte $A1,$11,$AA,$11,$1A,$A1
	.byte $AA,$A1,$A1,$A1,$A1,$AA

valve1_sprite:
	.byte 6,6
	.byte $AA,$1A,$A1,$11,$1A,$AA
	.byte $11,$A1,$AA,$11,$AA,$11
	.byte $11,$A1,$dA,$a1,$AA,$11
	.byte $11,$AA,$11,$A1,$A1,$11
	.byte $A1,$11,$11,$AA,$1A,$A1
	.byte $AA,$AA,$A1,$A1,$A1,$AA

valve2_sprite:
	.byte 6,6
	.byte $AA,$1A,$A1,$A1,$1A,$AA
	.byte $11,$11,$AA,$AA,$11,$11
	.byte $11,$AA,$d1,$A1,$AA,$11
	.byte $11,$AA,$11,$A1,$1A,$11
	.byte $A1,$11,$AA,$AA,$11,$A1
	.byte $AA,$AA,$A1,$A1,$A1,$AA

valve3_sprite:
	.byte 6,6
	.byte $AA,$1A,$A1,$A1,$1A,$AA
	.byte $11,$A1,$1A,$AA,$AA,$11
	.byte $11,$AA,$d1,$1A,$A1,$11
	.byte $11,$1A,$A1,$11,$AA,$11
	.byte $AA,$11,$AA,$A1,$11,$A1
	.byte $AA,$AA,$A1,$A1,$A1,$AA


	;==============
	; flame sprites

flame_sprites:
	.word flame1_sprite
	.word flame2_sprite

flame1_sprite:
	.byte 6,3
	.byte $f5,$d5,$d5,$95,$95,$95
	.byte $ff,$ff,$df,$dd,$9d,$9d
	.byte $59,$59,$59,$59,$58,$58

flame2_sprite:
	.byte 6,3
	.byte $f5,$d5,$d5,$95,$95,$95
	.byte $ff,$ff,$df,$dd,$9d,$ff
	.byte $5d,$5d,$59,$59,$59,$59


	;=============================
	; draw valve and other things
	; involving the boiler
	;=============================
draw_valve_cabin:

	; make sure facing right direction

	lda	DIRECTION
	and	#$f
	cmp	#DIRECTION_E
	bne	done_draw_valve

	; see if we need to draw pilot

	lda	BOILER_LEVEL
	bpl	skip_pilot

	; put $91 at 15,36, $55f

	lda	#$5
	clc
	adc	DRAW_PAGE
	sta	pilot_smc+2

	lda	#$91
pilot_smc:
	sta	$55f

	; see if need to draw flame
	lda	BOILER_VALVE
	beq	skip_pilot

	; draw flame
	lda	FRAMEL
	and	#$8
	lsr
	lsr
	tay

	lda	flame_sprites,Y
	sta	INL
	lda	flame_sprites+1,Y
	sta	INH

	lda	#18
	sta	XPOS
	lda	#32
	sta	YPOS
	jsr	put_sprite_crop

skip_pilot:


draw_psi:

	bit	TEXTGR	; bit of a hack

	; adjust to correct page
	lda	DRAW_PAGE
	clc
	adc	#$7
	sta	psi_smc+2

	lda	BOILER_LEVEL
	and	#$1f
	tay

	cpy	#13
	beq	want_colon
	bcc	want_backslash
want_slash:
	lda	#'/'|$80
	bne	put_psi		; bra

want_backslash:
	lda	#'\'|$80
	bne	put_psi		; bra
want_colon:
	lda	#':'|$80

put_psi:

	; 7,44  = $757
psi_smc:
	sta	$757,Y



	lda	#31
	sta	XPOS
	lda	#14
	bne	really_draw_valve	; bra

draw_valve_basement:
	lda	DIRECTION
	and	#$f
	cmp	#DIRECTION_N
	bne	done_draw_valve

	lda	#5
	sta	XPOS
	lda	#24

really_draw_valve:
	sta	YPOS

	lda	BOILER_VALVE
	and	#$3
	asl
	tay
	lda	valve_sprites,Y
	sta	INL
	lda	valve_sprites+1,Y
	sta	INH

	jmp	put_sprite_crop



done_draw_valve:
	rts


	;==============================
	; press elevator button
	;==============================
press_elevator_button:

	lda	TREE_LEVEL
	cmp	#2
	beq	bump_up
	bcc	button_ineffective

	dec	TREE_LEVEL		; drops you a floor
	lda	#$80
	sta	BOILER_LEVEL		; give some time before hitting again

	jsr	change_tree_level

button_ineffective:
	rts

bump_up:
	inc	TREE_LEVEL		; if on ground floor it bumps you up

	jsr	change_tree_level

	jmp	button_ineffective

