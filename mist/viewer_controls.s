display_viewer:


display_nothing:
	lda	ANIMATE_FRAME
	beq	done_animation


	lda	ANIMATE_FRAME
	asl
	tay
	lda	nothing_animation,Y
	sta	INL
	lda	nothing_animation+1,Y
	sta	INH

	lda	#12
	sta	XPOS
	lda	#20
	sta	YPOS

	jsr	put_sprite_crop

	lda	FRAMEL
	and	#$1f
	bne	done_animation

	inc	ANIMATE_FRAME
	lda	ANIMATE_FRAME
	cmp	#6
	bne	done_animation
done_nothing:
	lda	#0
	sta	ANIMATE_FRAME

done_animation:
	rts


enter_viewer:

	lda	#1
	sta	ANIMATE_FRAME

	rts

enter_control_panel:

	lda	#VIEWER_CONTROL_PANEL
	sta	LOCATION

	lda	#(DIRECTION_E|DIRECTION_ONLY_POINT|DIRECTION_SPLIT)
	sta	DIRECTION

	jsr	change_location

	rts


control_panel_pressed:

	lda	CURSOR_Y
	cmp	#26		; blt
	bcc	panel_inc
	cmp	#30		; blt
	bcc	panel_dec

panel_latch:

	lda	VIEWER_CHANNEL
	sta	VIEWER_LATCHED	; latch value into pool state

	lda	#VIEWER_POOL
	sta	LOCATION

	lda	#DIRECTION_W
	sta	DIRECTION
	jmp	change_location

panel_inc:
	lda	CURSOR_X
	cmp	#18
	bcs	right_arrow_pressed

	; 19-23 left arrow

	lda	VIEWER_CHANNEL
	and	#$f0
	cmp	#$90
	bcs	done_panel_press	; bge
	lda	VIEWER_CHANNEL
	clc
	adc	#$10
	sta	VIEWER_CHANNEL
	rts

right_arrow_pressed:
	; 13-17 right arrow

	lda	VIEWER_CHANNEL
	and	#$f
	cmp	#9
	bcs	done_panel_press	; bge
	inc	VIEWER_CHANNEL
	rts

panel_dec:
	lda	CURSOR_X
	cmp	#18
	bcs	right_arrow_pressed_dec

	; 19-23 left arrow

	lda	VIEWER_CHANNEL
	and	#$f0
	beq	done_panel_press
	lda	VIEWER_CHANNEL
	sec
	sbc	#$10
	sta	VIEWER_CHANNEL
	rts

right_arrow_pressed_dec:
	; 13-17 right arrow

	lda	VIEWER_CHANNEL
	and	#$f
	beq	done_panel_press
	dec	VIEWER_CHANNEL

done_panel_press:
	rts


display_panel_code:

	; ones digit

	lda	VIEWER_CHANNEL
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

	; tens digit

	lda	VIEWER_CHANNEL
	and	#$f0
	lsr
	lsr
	lsr
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

	rts



number_sprites:
.word sprite_0,sprite_1,sprite_2,sprite_3,sprite_4
.word sprite_5,sprite_6,sprite_7,sprite_8,sprite_9

;  .   .   .   .  . .
; O O ^O  ^ O ^ O O O
; O O  O   O   ^O ^^O
; ^.^ .O. O.. ..^   O

sprite_0:
	.byte 3,4
	.byte	$AA,$0A,$AA	;
	.byte	$00,$AA,$00	;
	.byte	$00,$AA,$00	;
	.byte	$A0,$0A,$A0	;

;  .   .   .   .  . .
; O O ^O  ^ O ^ O O O
; O O  O   O   ^O ^^O
; ^.^ .O. O.. ..^   O

sprite_1:
	.byte 3,4
	.byte	$AA,$0A,$AA
	.byte	$A0,$00,$AA
	.byte	$AA,$00,$AA
	.byte	$0A,$00,$0A

;  .   .   .   .  . .
; O O ^O  ^ O ^ O O O
; O O  O   O   ^O ^^O
; ^.^ .O. O.. ..^   O

sprite_2:
	.byte 3,4
	.byte	$AA,$0A,$AA
	.byte	$A0,$AA,$00
	.byte	$AA,$00,$AA
	.byte	$00,$0A,$0A

;  .   .   .   .  . .
; O O ^O  ^ O ^ O O O
; O O  O   O   ^O ^^O
; ^.^ .O. O.. ..^   O

sprite_3:
	.byte 3,4
	.byte	$AA,$0A,$AA
	.byte	$A0,$AA,$00
	.byte	$AA,$A0,$00
	.byte	$0A,$0A,$A0

;  .   .   .   .  . .
; O O ^O  ^ O ^ O O O
; O O  O   O   ^O ^^O
; ^.^ .O. O.. ..^   O

sprite_4:
	.byte 3,4
	.byte	$0A,$AA,$0A
	.byte	$00,$AA,$00
	.byte	$A0,$A0,$00
	.byte	$AA,$AA,$00

; ...  .. ...  .   .
; O   O     O O O O O
; ^^. O^.  O  .^.  ^O
; ..^ ^.^ O   ^.^ ..O

sprite_5:
	.byte 3,4
	.byte	$0A,$0A,$0A
	.byte	$00,$AA,$AA
	.byte	$A0,$A0,$0A
	.byte	$0A,$0A,$A0

; ...  .. ...  .   .
; O   O     O O O O O
; ^^. O^.  O  .^.  ^O
; ..^ ^.^ O   ^.^ ..O

sprite_6:
	.byte 3,4
	.byte	$AA,$0A,$0A
	.byte	$00,$AA,$AA
	.byte	$00,$A0,$0A
	.byte	$A0,$0A,$A0

; ...  .. ...  .   .
; O   O     O O O O O
; ^^. O^.  O  .^.  ^O
; ..^ ^.^ O   ^.^ ..O

sprite_7:
	.byte 3,4
	.byte	$0A,$0A,$0A
	.byte	$AA,$AA,$00
	.byte	$AA,$00,$AA
	.byte	$00,$AA,$AA

; ...  .. ...  .   .
; O   O     O O O O O
; ^^. O^.  O  .^.  ^O
; ..^ ^.^ O   ^.^ ..O

sprite_8:
	.byte 3,4
	.byte	$AA,$0A,$AA
	.byte	$00,$AA,$00
	.byte	$0A,$A0,$0A
	.byte	$A0,$0A,$A0

; ...  .. ...  .   .
; O   O     O O O O O
; ^^. O^.  O  .^.  ^O
; ..^ ^.^ O   ^.^ ..^

sprite_9:
	.byte 3,4
	.byte	$AA,$0A,$AA
	.byte	$00,$AA,$00
	.byte	$AA,$A0,$00
	.byte	$0A,$0A,$A0



nothing_animation:
	.word empty,empty,na_frame0,na_frame1,na_frame0,empty

empty:
	.byte 16,4
	.byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
	.byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
	.byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
	.byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA

na_frame0:
	.byte 16,4
	.byte $FA,$7f,$5f,$57,$57,$57,$57,$57,$57,$57,$57,$57,$57,$7f,$7f,$fA
	.byte $57,$55,$55,$55,$77,$55,$55,$55,$55,$55,$55,$77,$55,$55,$55,$57
	.byte $55,$55,$55,$55,$77,$55,$5d,$57,$57,$5d,$55,$77,$55,$55,$55,$55
	.byte $7f,$f5,$fd,$55,$77,$55,$5d,$57,$57,$5d,$55,$77,$55,$5d,$f5,$7f

na_frame1:
	.byte 16,4
	.byte $fA,$7f,$ff,$f7,$f7,$f7,$f7,$f7,$f7,$f7,$f7,$f7,$f7,$7f,$7f,$fa
	.byte $f7,$ff,$ff,$ff,$77,$ff,$ff,$ff,$ff,$ff,$ff,$77,$ff,$ff,$ff,$f7
	.byte $ff,$ff,$ff,$ff,$77,$ff,$fd,$f7,$f7,$fd,$ff,$77,$ff,$ff,$ff,$ff
	.byte $7f,$ff,$fd,$ff,$77,$ff,$fd,$f7,$f7,$fd,$ff,$77,$ff,$fd,$ff,$7f