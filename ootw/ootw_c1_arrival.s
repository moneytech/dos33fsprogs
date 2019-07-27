; Ootw Checkpoint1 -- arriving with a splash

ootw_c1_arrival:
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

	;=============================
	; Load background to $c00

	lda     #>(underwater_rle)
        sta     GBASH
	lda     #<(underwater_rle)
        sta     GBASL
	lda	#$c			; load image off-screen $c00
	jsr	load_rle_gr


	;=================================
	; do intro flash

	jsr	do_flash


	;=================================
	; setup vars

	lda	#0
	sta	GAME_OVER
	sta	GAIT

	lda	#20
	sta	BUBBLES_Y
	sta	CONSOLE_Y
	sta	PHYSICIST_Y

	lda	#17
	sta	PHYSICIST_X

        bit     KEYRESET		; clear keypress

	;============================
	; Underwater Loop
	;============================
underwater_loop:

	;================================
	; copy background to current page
	;================================

	jsr	gr_copy_to_current


	;=======================
	; draw Surface ripple
	;=======================

;	jsr	ootw_draw_miners

	;======================
	; draw console
	;======================

	lda	#16
	sta	XPOS
	lda	CONSOLE_Y
        sta	YPOS

	lda	#<console_sprite
	sta	INL
	lda	#>console_sprite
	sta	INH
	jsr	put_sprite_crop

	;=================================
	; draw physicist
	;=================================

	lda	PHYSICIST_X
	sta	XPOS
	lda	PHYSICIST_Y
        sta	YPOS

	ldy	GAIT
	lda	swim_progression,Y
	sta	INL
	lda	swim_progression+1,Y
	sta	INH
	jsr	put_sprite_crop

	;======================
	; draw monster
	;======================

	;======================
	; draw bubbles
	;======================

	lda	BUBBLES_Y
	cmp	#2
	bcc	no_draw_bubbles	; blt

        sta	YPOS

	lda	#17
	sta	XPOS


	lda	#<bubbles_sprite
	sta	INL
	lda	#>bubbles_sprite
	sta	INH
	jsr	put_sprite_crop
no_draw_bubbles:




	;===============================
	; check keyboard
	;===============================

	lda	KEYPRESS
        bpl	underwater_done_keyboard

	cmp	#27+$80
	beq	underwater_escape

	cmp	#'A'+$80
	beq	uw_left_pressed
	cmp	#8+$80
	beq	uw_left_pressed

	cmp	#'D'+$80
	beq	uw_right_pressed
	cmp	#$15+$80
	beq	uw_right_pressed

	cmp	#'W'+$80
	beq	uw_up_pressed
	cmp	#$0B+$80
	beq	uw_up_pressed

	cmp	#'S'+$80
	beq	uw_down_pressed
	cmp	#$0A+$80
	beq	uw_down_pressed

	jmp	underwater_done_keyboard

underwater_escape:
	lda	#$ff
	sta	GAME_OVER
	bne	underwater_done_keyboard	; bra


uw_left_pressed:
	dec	PHYSICIST_X
	jmp	underwater_done_keyboard

uw_right_pressed:
	inc	PHYSICIST_X
	jmp	underwater_done_keyboard

uw_up_pressed:
	dec	PHYSICIST_Y
	dec	PHYSICIST_Y
	jmp	underwater_done_keyboard

uw_down_pressed:
	inc	PHYSICIST_Y
	inc	PHYSICIST_Y
	jmp	underwater_done_keyboard


underwater_done_keyboard:
	bit	KEYRESET

	;=================================
	; move things
	;=================================

	;===================
	; move bubbles
	;===================

	lda	FRAMEL
	and	#$f
	bne	no_move_bubbles

	ldx	BUBBLES_Y
	beq	no_move_bubbles

	dex
	dex
	stx	BUBBLES_Y

no_move_bubbles:

	;===================
	; move console
	;===================

	lda	FRAMEL
	and	#$1f
	bne	no_move_console

	ldx	CONSOLE_Y
	cpx	#34
	bcs	no_move_console	; bge

	inx
	inx
	stx	CONSOLE_Y

no_move_console:


	;===================
	; move physicist
	;===================
	; gradually pull you down

	lda	FRAMEL
	and	#$f
	bne	no_move_swim

	lda	GAIT
	clc
	adc	#$2
	and	#$f
	sta	GAIT

no_move_swim:

	lda	FRAMEL
	and	#$1f
	bne	no_move_physicist

	ldx	PHYSICIST_Y
	cpx	#34
	bcs	no_move_physicist	; bge

	inx
	inx
	stx	PHYSICIST_Y

no_move_physicist:




	;===============
	; page flip

	jsr	page_flip

	;================
	; inc frame count

	inc	FRAMEL
	bne	underwater_frame_no_oflo
	inc	FRAMEH

underwater_frame_no_oflo:


	;==========================
	; check if done this level
	;==========================

	lda	GAME_OVER
	cmp	#$ff
	beq	done_underwater


	; check if leaving the pool

	lda	PHYSICIST_Y
	cmp	#$FE
	beq	done_underwater


	; loop forever

	jmp	underwater_loop

done_underwater:
	rts









bubbles_sprite:
	.byte 5,2
	.byte $6A,$AA,$A6,$7A,$6A
	.byte $AA,$AA,$A6,$AA,$AA



console_sprite:
	.byte 6,5
	.byte $AA,$A5,$55,$5A,$AA,$AA
	.byte $AA,$AA,$00,$05,$05,$AA
	.byte $5A,$05,$00,$00,$00,$55
	.byte $AA,$A5,$55,$00,$00,$55
	.byte $AA,$AA,$A5,$A0,$A0,$A5







	;============================
	; Do Flash
	;============================
do_flash:

	lda	#0
	sta	FRAMEL

	;============================
	; Flash Loop
	;============================
flash_loop:



	;================================
	; Handle Flash
	;================================

	lda	FRAMEL
	cmp	#180
	bcc	no_flash		; blt
	cmp	#182
	bcc	first_flash
	bcs	second_flash

first_flash:

	; Load background to $1000

	lda     #>(uboot_flash1_rle)
        sta     GBASH
	lda     #<(uboot_flash1_rle)
        sta     GBASL
	lda	#$10			; load image off-screen $c00
	jsr	load_rle_gr

	jsr	gr_overlay

	jmp	check_flash_done
second_flash:

	; Load background to $1000

	lda     #>(uboot_flash2_rle)
        sta     GBASH
	lda     #<(uboot_flash2_rle)
        sta     GBASL
	lda	#$10			; load image off-screen $c00
	jsr	load_rle_gr

	jsr	gr_overlay

	jmp	check_flash_done

no_flash:
	;================================
	; copy background to current page
	;================================

	jsr	gr_copy_to_current

check_flash_done:


	;=======================
	; draw Surface ripple
	;=======================

;	jsr	ootw_draw_miners

	;=======================
	; draw Overall ripple
	;=======================



	;===============
	; page flip

	jsr	page_flip

	;================
	; inc frame count

	inc	FRAMEL
	bne	flash_frame_no_oflo
	inc	FRAMEH

flash_frame_no_oflo:


	;==========================
	; check if done this level
	;==========================

	lda	FRAMEL
	cmp	#184
	beq	done_flash



	; loop forever

	jmp	flash_loop

done_flash:
	rts





