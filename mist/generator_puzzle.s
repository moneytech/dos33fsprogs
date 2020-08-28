;====================================
; Routines for the generator puzzles
;====================================

leave_tower1:
        lda     #GEN_TOWER1_TOP
        sta     LOCATION

        lda     #DIRECTION_E
        sta     DIRECTION

        jsr     change_location

        rts

back_to_mist:
	lda	#MIST_TREE_CORRIDOR_4
	sta	LOCATION

	lda	#DIRECTION_E
	sta	DIRECTION

	lda	#LOAD_MIST
	sta	WHICH_LOAD

	lda	#$ff
	sta	LEVEL_OVER

	rts


draw_circuit_breaker:
	lda	ANIMATE_FRAME
	beq	done_draw_circuit_breaker

	lda	#17
	sta	XPOS
	lda	#12
	sta	YPOS

	lda	#<breaker_down_sprite
	sta	INL
	lda	#>breaker_down_sprite
	sta	INH

	jsr	put_sprite_crop

	lda	FRAMEL
	and	#$1f
	bne	done_draw_circuit_breaker

	dec	ANIMATE_FRAME

done_draw_circuit_breaker:
	rts


breaker_down_sprite:
	.byte 3,2
	.byte $90,$0f,$90
	.byte $69,$65,$69


;=======================
; flip circuit breaker

; if room==MIST_TOWER2_TOP, and with #$fe
; if room==GEN_TOWER1_TOP, and with #$fd

circuit_breaker:

	jsr	click_speaker		; click speaker

	lda	#2
	sta	ANIMATE_FRAME

	lda	LOCATION
	cmp	#MIST_TOWER2_TOP
	bne	other_circuit_breaker

	lda	BREAKER_TRIPPED
	and	#$fe
	jmp	done_circuit_breaker

other_circuit_breaker:
	lda	BREAKER_TRIPPED
	and	#$fd

done_circuit_breaker:
	sta	BREAKER_TRIPPED

	bne	done_turn_on_breaker

turn_on_breaker:

	lda	GENERATOR_VOLTS
	cmp	#$60
	bcs	done_turn_on_breaker

	sta	ROCKET_VOLTS
	sta	ROCKET_VOLTS_DISP


done_turn_on_breaker:

	rts


;======================
; open the generator_door

open_gen_door:

	lda	gen_door_status
	eor	#$1
	sta	gen_door_status

	beq	gen_close_door

gen_open_door:

	ldy	#LOCATION_NORTH_EXIT
	lda	#GEN_GENERATOR_ROOM
	sta	location3,Y			; GEN_GENERATOR_DOOR

	ldy	#LOCATION_NORTH_EXIT_DIR
	lda	#(DIRECTION_N | DIRECTION_SPLIT | DIRECTION_ONLY_POINT)
	sta	location3,Y			; GEN_GENERATOR_DOOR

	ldy	#LOCATION_NORTH_BG
	lda	#<gen_door_open_n_lzsa
	sta	location3,Y			; GEN_GENERATOR_DOOR
	lda	#>gen_door_open_n_lzsa
	sta	location3+1,Y			; GEN_GENERATOR_DOOR

	jmp	change_location

gen_close_door:

	; disable exit
	ldy	#LOCATION_NORTH_EXIT
	lda	#$ff
	sta	location3,Y			; GEN_GENERATOR_DOOR

	ldy	#LOCATION_NORTH_EXIT_DIR
	lda	#$ff
	sta	location3,Y			; GEN_GENERATOR_DOOR

	; change background

	ldy	#LOCATION_NORTH_BG
	lda	#<gen_door_closed_n_lzsa
	sta	location3,Y			; GEN_GENERATOR_DOOR
	lda	#>gen_door_closed_n_lzsa
	sta	location3+1,Y			; GEN_GENERATOR_DOOR

	jmp	change_location


gen_door_status:
	.byte	$00	; closed

button_lookup:
.byte $10,$8,$4,$2,$1

button_values_top:
.byte	$01,$02,$22,$19,$09	; BCD
button_values_bottom:
.byte	$10,$07,$08,$16,$05	; BCD

needle_strings:
	.byte '\'|$80,' '|$80,' '|$80,' '|$80
	.byte ' '|$80,':'|$80,' '|$80,' '|$80
	.byte ' '|$80,' '|$80,':'|$80,' '|$80
	.byte ' '|$80,' '|$80,' '|$80,'/'|$80

;============================
; handle button presses
;============================

generator_button_press:

	lda	DIRECTION
	and	#$f
	cmp	#DIRECTION_N
	beq	really_the_panel

	; otherwise, the sign

	lda	CURSOR_X
	cmp	#27
	bcs	draw_sign

	; not draw sign, leave room

	lda	#GEN_GENERATOR_DOOR
	sta	LOCATION
	jmp	change_location

draw_sign:

	lda	#GEN_SIGN
	sta	LOCATION

	lda	#(DIRECTION_S|DIRECTION_SPLIT)
	sta	DIRECTION

	jmp	change_location


really_the_panel:

	lda	CURSOR_Y
	cmp	#38
	bcs	button_bottom_row		; bge

button_top_row:

	lda	CURSOR_X
	sec
	sbc	#24
	lsr
	bmi	done_press
	cmp	#5
	bcs	done_press		; bge

	tax
	lda	SWITCH_TOP_ROW
	eor	button_lookup,X		; toggle switch
	sta	SWITCH_TOP_ROW

	jmp	done_press

button_bottom_row:

	lda	CURSOR_X
	sec
	sbc	#25
	lsr
	bmi	done_press
	cmp	#5
	bcs	done_press		; bge

	tax
	lda	SWITCH_BOTTOM_ROW
	eor	button_lookup,X		; toggle switch
	sta	SWITCH_BOTTOM_ROW
no_bottom_press:

done_press:


calculate_button_totals:

	lda	#0
	sta	ROCKET_VOLTS
	sta	GENERATOR_VOLTS
	tax

calc_buttons_loop:

	; top button

	lda	SWITCH_TOP_ROW
	and	button_lookup,X
	beq	ctop_button_off

ctop_button_on:
	sed
	clc
	lda	GENERATOR_VOLTS
	adc	button_values_top,X
	sta	GENERATOR_VOLTS
	cld

ctop_button_off:

	lda	SWITCH_BOTTOM_ROW
	and	button_lookup,X
	beq	cbottom_button_off

cbottom_button_on:
	sed
	clc
	lda	GENERATOR_VOLTS
	adc	button_values_bottom,X
	sta	GENERATOR_VOLTS
	cld

cbottom_button_off:

	inx
	cpx	#5
	bne	calc_buttons_loop

	; calculate rocket volts
	lda	BREAKER_TRIPPED
	bne	done_rocket_volts

	lda	GENERATOR_VOLTS
	cmp	#$60
	bcs	oops_flipped		; bge

	sta	ROCKET_VOLTS
	jmp	done_rocket_volts

oops_flipped:
	lda	#$3
	sta	BREAKER_TRIPPED

done_rocket_volts:

	rts

;===========================
; draw the voltage displays
;===========================

generator_update_volts:

	; gradually adjust generator voltage
	sed
	lda	GENERATOR_VOLTS_DISP
	cmp	GENERATOR_VOLTS
	beq	no_adjust_gen_volts
	bcs	gen_volts_dec

	clc
	adc	#1
	jmp	done_adjust_gen_volts
gen_volts_dec:
	sec
	sbc	#1
done_adjust_gen_volts:
	sta	GENERATOR_VOLTS_DISP

no_adjust_gen_volts:


	; gradually adjust rocket voltage
	lda	ROCKET_VOLTS_DISP
	cmp	ROCKET_VOLTS
	beq	no_adjust_rocket_volts
	bcs	rocket_volts_dec

	clc
	adc	#1
	jmp	done_adjust_rocket_volts
rocket_volts_dec:
	sec
	sbc	#1
done_adjust_rocket_volts:
	sta	ROCKET_VOLTS_DISP

no_adjust_rocket_volts:
	cld


	lda	DRAW_PAGE
	clc
	adc	#$6
	sta	gen_volt_ones_smc+2
	sta	gen_volt_tens_smc+2
	sta	rocket_volt_ones_smc+2
	sta	rocket_volt_tens_smc+2
	sta	gen_put_needle_smc+2
	sta	rocket_put_needle_smc+2

	lda	GENERATOR_VOLTS_DISP
	and	#$f
	clc
	adc	#$b0
gen_volt_ones_smc:
	sta	$6d0+14			; 14,21

	lda	GENERATOR_VOLTS_DISP
	lsr
	lsr
	lsr
	lsr
	and	#$f
	clc
	adc	#$b0
gen_volt_tens_smc:
	sta	$6d0+13			; 13,21

	; draw gen needle
	lda	GENERATOR_VOLTS_DISP
	ldx	#0
	cmp	#$25
	bcc	gen_put_needle
	inx
	cmp	#$50
	bcc	gen_put_needle
	inx
	cmp	#$75
	bcc	gen_put_needle
	inx
gen_put_needle:
	txa
	asl
	asl
	tax
	ldy	#0
gen_put_needle_loop:

	lda	needle_strings,X
gen_put_needle_smc:
	sta	$650+12,Y
	iny
	inx
	cpy	#4
	bne	gen_put_needle_loop


	lda	ROCKET_VOLTS_DISP
	and	#$f
	clc
	adc	#$b0
rocket_volt_ones_smc:
	sta	$6d0+21			; 21,21

	lda	ROCKET_VOLTS_DISP
	lsr
	lsr
	lsr
	lsr
	and	#$f
	clc
	adc	#$b0
rocket_volt_tens_smc:
	sta	$6d0+20			; 20,21


	; draw rocket needle
	lda	ROCKET_VOLTS_DISP
	ldx	#0
	cmp	#$25
	bcc	rocket_put_needle
	inx
	cmp	#$50
	bcc	rocket_put_needle
	inx
	cmp	#$75
	bcc	rocket_put_needle
	inx
rocket_put_needle:
	txa
	asl
	asl
	tax
	ldy	#0
rocket_put_needle_loop:

	lda	needle_strings,X
rocket_put_needle_smc:
	sta	$650+19,Y
	iny
	inx
	cpy	#4
	bne	rocket_put_needle_loop

	rts

	;=========================
	; draw the buttons
	;=========================

generator_draw_buttons:

	ldx	#0
	clc
	lda	DRAW_PAGE
	adc	#$4
	sta	top_button_draw_smc+2
	adc	#$1
	sta	bottom_button_draw_smc+2
	lda	#$d0+25
	sta	top_button_draw_smc+1
	adc	#$1
	sta	bottom_button_draw_smc+1

draw_buttons_loop:

	; top button

	lda	SWITCH_TOP_ROW
	and	button_lookup,X
	beq	top_button_off

top_button_on:
	ldy	#$95
	bne	top_button_draw_smc

top_button_off:
	ldy	#$35

top_button_draw_smc:
	sty	$4d0+25

	inc	top_button_draw_smc+1
	inc	top_button_draw_smc+1

	; bottom button

	lda	SWITCH_BOTTOM_ROW
	and	button_lookup,X
	beq	bottom_button_off

bottom_button_on:
	ldy	#$19
	bne	bottom_button_draw_smc

bottom_button_off:
	ldy	#$13

bottom_button_draw_smc:
	sty	$5d0+26

	inc	bottom_button_draw_smc+1
	inc	bottom_button_draw_smc+1

	inx
	cpx	#5
	bne	draw_buttons_loop

	rts

