;
;	Cycle-counting text/hgr/lowres demo
;		by Vince Weaver
;

.include "zp.inc"

	FRAME	= $60
	TREE1X	= $61
	TREE2X	= $62

	LETTERL	= $63
	LETTERH = $64
	LETTERX = $65
	LETTERY	= $66
	LETTERD = $67
	LETTER	= $68
	BLARGH	= $69
	MBASE	= $97
	MBOFFSET = $98
	WAITING = $99

	;===================
	; init screen

	jsr	TEXT
	jsr	HOME

	;==================
	; Init vars

	lda	#28
	sta	TREE1X
	lda	#37
	sta	TREE2X

	lda	#0
	sta	MBOFFSET
	lda	#>music
	sta	MBASE

	lda	#<letters
	sta	LETTERL
	lda	#>letters
	sta	LETTERH
	lda	#39
	sta	LETTERX
	lda	#1
	sta	LETTERY
	lda	#15
	sta	LETTERD

	lda	#0
	sta	DISP_PAGE
	lda	#0
	sta	DRAW_PAGE

	;==========================
	; setup mockingboard

	jsr mockingboard_detect_slot4
	stx	MB_DETECTED
	ldx	MB_DETECTED
	beq	no_init_mb

	jsr	mockingboard_init

no_init_mb:


	;==========================
	; Load the background image

	lda	#<katahdin
	sta	LZ4_SRC
	lda	#>katahdin
	sta	LZ4_SRC+1

	lda	#<(katahdin_end-8)		; skip checksum at end
	sta	LZ4_END
	lda	#>(katahdin_end-8)		; skip checksum at end
	sta	LZ4_END+1

	lda	#<$2000			; Destination is HGR page0
	sta	LZ4_DST
	lda	#>$2000
	sta	LZ4_DST+1

	jsr	lz4_decode


	; test letters
;letter_loop:
;	lda	#80
;	jsr	WAIT
;	jsr	move_letters
;	jmp	letter_loop

	; Wait

;	jsr	wait_until_keypressed

	; GR part
;	bit	LORES
;	bit	SET_GR
;	bit	FULLGR

;	jsr	draw_bottom_green				; 6

	; Wait

;	jsr	wait_until_keypressed

;	bit	HIRES


	; Wait

;	jsr	wait_until_keypressed

	;=====================================================
	; attempt vapor lock
	;=====================================================
	jsr	vapor_lock


	;==========================
	; setup text screen

	; clear top 6 lines to space

	; takes (Y/2)*(6+435+7)+5 = ?
	lda	#$A0			; space			; 2
	ldy	#10			; 6 lines		; 2
	jsr	clear_page_loop					; 2693

;                                1               2
;                0123456789abcdef0123456789abcdef0123456
;line1:.asciiz	"   *                            .      " $400
;line2:.asciiz	"  *    .                            .  " $480
;line3:.asciiz	"  *                                    " $500
;line4:.asciiz	"   *                                   " $580
;line5:.asciiz	" .                          .    .     " $600
;line6:.asciiz	"             .                         " $680

	lda	#'.'|$80	; print star			; 2
	sta	$420						; 4
	sta	$487						; 4
	sta	$4A4						; 4
	sta	$601						; 4
	sta	$61c						; 4
	sta	$621						; 4
	sta	$68d						; 4
							;============
							;	 30
	; draw the moon
	lda	#' '		; print inv space		; 2
	sta	$403						; 4
	sta	$482						; 4
	sta	$502						; 4
	sta	$583						; 4
							;============
							;	 18



	; vapor lock returns with us at beginning of hsync in line
	; 114 (7410 cycles), so with 5070 cycles to go
	; 5070+4550 = 9620
	;	     -2745 (draw text)
	;	===========
	;	      6875


	; Try X=97 Y=14 cycles=6875

	ldy	#14							; 2
loopA:	ldx	#97							; 2
loopB:	dex								; 2
	bne	loopB							; 2nt/3
	dey								; 2
	bne	loopA							; 2nt/3

	jmp	display_loop
.align	$100

	;=====================================================
	;=====================================================
	; Loop forever display loop
	;=====================================================
	;=====================================================
display_loop:
	; each scan line 65 cycles
	;	1 cycle each byte (40cycles) + 25 for horizontal
	;	Total of 12480 cycles to draw screen
	; Vertical blank = 4550 cycles (70 scan lines)
	; Total of 17030 cycles to get back to where was

	;	16666     = 17030      x=1021.8
	;         1000        x


	; TODO: find beginning of scan
	;	Text mode for 6*8=48 scanlines (3120 cycles)
	;	hgr for 64 scalines (4160 cycles)
	;	gr for 80 scalines (5200 cycles)
	;	vblank = 4550 cycles

	; text
	bit	SET_TEXT						; 4

	;================
	; clear bottom green

	jsr	draw_bottom_green				; 2209+6


	;================
	; Draw Small Tree

	lda	#>small_tree				; 2
	sta	INH					; 3
	lda	#<small_tree				; 2
	sta	INL					; 3

	lda	TREE1X					; 3
	sta	XPOS					; 3
	lda	#28					; 2
	sta	YPOS					; 3

	jsr	put_sprite				; 6
							;=========
							; 27
							; + 576
							;========
							; 603


	; want		 3120
	; green		-2215
	; tree1		 -603
	; set_test	   -4
	;=============== 298 cycles

	; Try X=1 Y=27 cycles=298

	ldy	#27							; 2
loop2:
	ldx	#1							; 2
loop1:
	dex								; 2
	bne	loop1							; 2nt/3

	dey								; 2
	bne	loop2							; 2nt/3

;=============================================

	; hgr
	bit	HIRES							; 4
	bit	SET_GR							; 4


	;================
	; Draw Big Tree

	lda	#>big_tree				; 2
	sta	INH					; 3
	lda	#<big_tree				; 2
	sta	INL					; 3

	lda	TREE2X					; 3
	sta	XPOS					; 3
	lda	#30					; 2
	sta	YPOS					; 3

	jsr	put_sprite				; 6
							;=========
							; 27
							; + 1410
							;========
							; 1437

	lda	FRAME							; 3
	and	#$1f							; 2
	and	#$10							; 2

	beq	bird_walking
									; 2
	lda	#>bird_rider_stand_right				; 2
	sta	INH							; 3
	lda	#<bird_rider_stand_right				; 2
	sta	INL							; 3

	jmp	draw_bird						; 3

bird_walking:
									; 3
	lda	#>bird_rider_walk_right					; 2
	sta	INH							; 3
	lda	#<bird_rider_walk_right					; 2
	sta	INL							; 3
	; must be 15
	lda	#0							; 2
	; Must add another 15 as sprite is different
	inc	XPOS							; 5
	inc	XPOS							; 5
	inc	XPOS							; 5


draw_bird:

							; 15 + 7
	lda	#17					; 2
	sta	XPOS					; 3
	lda	#30					; 2
	sta	YPOS					; 3

	jsr	put_sprite				; 6
							;=========
							; 38

							; + 2190
							;========
							; 2228


	;==========================
	; Update frame = 13 cycles


	inc	FRAME			; frame++			; 5
	lda	FRAME							; 3
	and	#$3f			; roll over after 63		; 2
	sta	FRAME							; 3

								;===========
								;        13

	;===========================
	; Update tree1 = 21 cycles
	and	#$3f			; if (frame%64==0)		; 2
	beq	dec_tree1
									; 2
	; need to do 19-5 cycles of nonsense
	inc	TREE1X							; 5
	dec	TREE1X							; 5
	lda	#0							; 2
	lda	#0							; 2

	jmp	done_tree1						; 3

dec_tree1:
									; 3
	dec	TREE1X			; tree1_x--			; 5
	lda	TREE1X							; 3
	bmi	tree1_neg
									; 2
	ldx	TREE1X							; 3
	jmp	done_tree1						; 3
tree1_neg:
							; incoming br     3
	ldx	#37							; 2
	stx	TREE1X							; 3
done_tree1:

	;===========================
	; Update tree2 = 24 cycles
	lda	FRAME							; 3
	and	#$f			; if (frame%16==0)		; 2
	beq	dec_tree2
									; 2
	; need to do 19-5 cycles of nonsense
	inc	TREE2X							; 5
	dec	TREE2X							; 5
	lda	#0							; 2
	lda	#0							; 2

	jmp	done_tree2						; 3

dec_tree2:
									; 3
	dec	TREE2X			; tree2_x--			; 5
	lda	TREE2X							; 3
	bmi	tree2_neg
									; 2
	ldx	TREE2X							; 3
	jmp	done_tree2						; 3
tree2_neg:
							; incoming br     3
	ldx	#37							; 2
	stx	TREE2X							; 3
done_tree2:


	; want                   4160
	; Tree2 Sprite		-1437
	; Sprite		-2228
	; Frame Update		  -13
	; Tree1 Update		  -21
	; Tree2 Update		  -24
	; hgr bits		   -8
	; ======================  429 cycles

	; Try X=13 Y=6 cycles=427 R2

	lda	#0							; 2

	ldy	#6							; 2
loop3:
	ldx	#13							; 2
loop4:
	dex								; 2
	bne	loop4							; 2nt/3

	dey								; 2
	bne	loop3							; 2nt/3

;===========================================================================


	; gr
	bit	LORES							; 4

	;=========================
	; play mockingboard
	; 11+ 84*5 + 10*4 + 21 = 492

	lda	MBASE				; 3
	sta	MB_ADDRH			; 3
	lda	#0				; 2
	sta	MB_ADDRL			; 3
					;=============
					;	11

	ldx	#0				; 2
	ldy	MBOFFSET			; 3
	lda	(MB_ADDRL),Y			; 5
	sta	MB_VALUE			; 3
	jsr	write_ay_both			; 6+65
					;===============
					;	84

	clc					; 2
	lda	#6				; 2
	adc	MB_ADDRH			; 3
	sta	MB_ADDRH			; 3
					;==============
					;	10
	ldx	#2
	ldy	MBOFFSET
	lda	(MB_ADDRL),Y
	sta	MB_VALUE
	jsr	write_ay_both

	clc
	lda	#6
	adc	MB_ADDRH
	sta	MB_ADDRH

	ldx	#3
	ldy	MBOFFSET
	lda	(MB_ADDRL),y
	sta	MB_VALUE
	jsr	write_ay_both

	clc
	lda	#6
	adc	MB_ADDRH
	sta	MB_ADDRH

	ldx	#8
	ldy	MBOFFSET
	lda	(MB_ADDRL),y
	sta	MB_VALUE
	jsr	write_ay_both

	clc
	lda	#6
	adc	MB_ADDRH
	sta	MB_ADDRH

	ldx	#9
	ldy	MBOFFSET
	lda	(MB_ADDRL),y
	sta	MB_VALUE
	jsr	write_ay_both

	;

	lda	FRAME			; 3
	and	#1			; 2
	clc				; 2
	adc	MBOFFSET		; 3
	sta	MBOFFSET		; 3

	lda	MBASE			; 3
	adc	#0			; 2
	sta	MBASE			; 3
				;=============
				;         21

	; 2=2 not loop
	; 2+7+3= 12 = last page
	; 2+7+15=24  = loop

	cmp	#>music+5		; 2
	bne	waste_7		;
					; 2
	lda	MBOFFSET		; 3
	cmp	#16			; 2
	bne	waste_12		;
					; 2
	lda	#>music			; 2
	sta	MBASE			; 3
	lda	#0			; 2
	sta	MBOFFSET		; 3
	jmp	not_ready_to_loop	; 3
waste_7:
	lda	#0			; 2
	inc	BLARGH			; 5
waste_12:
					; 3
	lda	#0			; 2
	inc	BLARGH			; 5
	inc	BLARGH			; 5

not_ready_to_loop:

	; lores want 	5200
	; mockingboard	-492
	; wrap		 -24
	; softswitch	  -4
	;===================
	;		4680 cycles

	; Try X=7 Y=114 cycles=4675 R5

	inc 	BLARGH							; 5
;	lda	#0							; 2
;	lda	#0							; 2
;	lda	#0							; 2
;	lda	#0							; 2

	ldy	#114							; 2
loop5:
	ldx	#7							; 2
loop6:
	dex								; 2
	bne	loop6							; 2nt/3

	dey								; 2
	bne	loop5							; 2nt/3

;========================================================================

	; vertical blank

	; want 4550 cycles
	; Try X=13 Y=64 cycles=4545 R2

;=========================================================================



	jsr	move_letters					; 6+126

	; Blanking time:	 4550
	; move_letters		 -132
	; JMP at end		   -3
	;========================4415 cycles

	; Try X=24 Y=35 cycles=4411 R4

	nop
	nop

	ldy	#35							; 2
loop7:	ldx	#24							; 2
loop8:	dex								; 2
	bne	loop8							; 2nt/3
	dey								; 2
	bne	loop7							; 2nt/3


	jmp	display_loop						; 3

;===========================================================
;===========================================================
;===========================================================

;wait_until_keypressed:
;	lda	KEYPRESS			; check if keypressed
;	bpl	wait_until_keypressed		; if not, loop
;	bit	KEYRESET
;	rts



	;====================================
	; Draw bottom green
	;====================================
	; using hlin 7127, optimized a bit but still awful
	; this one is much better
	; 2209 cycles
draw_bottom_green:

	lda	#$44							; 2
	ldx	#39							; 2
green_loop:
	sta	$728,X		; 28					; 5
	sta	$7a8,X		; 30					; 5
	sta	$450,X		; 32					; 5
	sta	$4d0,X		; 34					; 5
	sta	$550,X		; 36					; 5
	sta	$5d0,X		; 38					; 5
	sta	$650,X		; 40					; 5
	sta	$6d0,X		; 42					; 5
	sta	$750,X		; 44					; 5
	sta	$7d0,X		; 46					; 5

	dex								; 2
	bpl	green_loop						; 2nt/3

	rts								; 6

; 4 + (40*55) + 6 - 1


.align $100

letters:
	;.byte	1,15
	.byte	     "T A L B O T",128
	.byte	2,14,"F A N T A S Y",128
	.byte	3,16,"S E V E N",128
	.byte	1,15," ",128
	.byte	2,14," ",128
	.byte	3,16," ",128
	.byte	1,19,"BY",128
	.byte	3,14,"VINCE WEAVER",128
	.byte	1,19," ",128
	.byte	3,14," ",128
	.byte	1,16,"MUSIC BY",128
	.byte	3,12,"HIROKAZU TANAKA",128
	.byte	1,16," ",128
	.byte	3,12," ",128
	.byte	2,13,"CYCLE COUNTING",128
	.byte	3,16,"IS HARD!"
	.byte	255

.include "vapor_lock.s"
.include "delay_a.s"
.include "gr_hline.s"
.include "move_letters.s"
.include "gr_putsprite.s"
.include "mockingboard.s"
;.include "../asm_routines/keypress.s"

.align	$100
.include "tfv_sprites.inc"

.include "lz4_decode.s"

;.align	$1000

katahdin:
.incbin	"KATC.BIN.lz4",11		; skip the header
katahdin_end:

.align $100
music:
.incbin "music.tfv"
