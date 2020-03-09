;
;	Ride the bird past the mountain
;		by Vince Weaver
;


	TREE1X	= $E1
	TREE2X	= $E2

bird_mountain:

	;===================
	; init screen

	jsr	TEXT
	jsr	HOME

	;==================
	; Init vars

	lda	#0
	sta	FRAME
	sta	FRAMEH

	lda	#28
	sta	TREE1X
	lda	#37
	sta	TREE2X

	;=========================
	; setup scrolling letters
	;=========================

	; Patch the inverse values out (as used by check_email)
	lda	#39
	sta	ml_patch_dest+1
	lda	#$80
	sta	ml_patch_or+1
	lda	#$09
	sta	ml_patch_or
	lda	#' '|$80
	sta	ml_patch_space+1

	lda	#<letters_bm
	sta	LETTERL
	lda	#>letters_bm
	sta	LETTERH
	lda	#39
	sta	LETTERX
	lda	#1
	sta	LETTERY
	lda	#16
	sta	LETTERD

	;=================
	; Set draw page

	lda	#0
	sta	DISP_PAGE
	lda	#0
	sta	DRAW_PAGE

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

	sei				; disable interrupt music

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

	jsr	draw_moon_sky					; 6+54




	; vapor lock returns with us at beginning of hsync in line
	; 114 (7410 cycles), so with 5070 cycles to go
	; 5070+4550 = 9620
	;	     -2757 (draw text)
	;	===========
	;	      6863


	;; Try X=97 Y=14 cycles=6875
	; Try X=136 Y=10 cycles=6861 R2

	nop
	ldy	#10							; 2
bmloopA:ldx	#136							; 2
bmloopB:dex								; 2
	bne	bmloopB							; 2nt/3
	dey								; 2
	bne	bmloopA							; 2nt/3

	jmp	bm_display_loop

	;====================
	; draw moon sky
	;   54 cycles
draw_moon_sky:

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
	rts							; 6

.align	$100

	;=====================================================
	;=====================================================
	; Loop forever display loop
	;=====================================================
	;=====================================================
bm_display_loop:
	; each scan line 65 cycles
	;	1 cycle each byte (40cycles) + 25 for horizontal
	;Total of 12480 cycles to draw screen
	;Vertical blank = 4550 cycles (70 scan lines)
	; Total of 17030 cycles to get back to where was
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
bmloop2:ldx	#1							; 2
bmloop1:dex								; 2
	bne	bmloop1							; 2nt/3
	dey								; 2
	bne	bmloop2							; 2nt/3

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


	;=========================================
	; Update frame
	;=========================================
	; 16 addition
	;  7 inc high
	;  7 if done
	;=========
	; 30 update frame

	inc	FRAME			; frame++			; 5
	lda	FRAME							; 3
	and	#$3f			; roll over after 63		; 2
	sta	FRAME							; 3
	bne	bm_noflo						; 3

									; -1
	inc	FRAMEH							; 5
	jmp	bm_check_done						; 3
bm_noflo:
	nop								; 2
	nop								; 2
	lda	$0	; nop						; 3
bm_check_done:
	; finish after so many cycles
	lda	FRAMEH							; 3
	cmp	#23							; 2
	beq	bm_done							; 3
									; -1


	;===========================
	; Update tree1 = 22 cycles
	lda	FRAME							; 3
;	and	#$3f			; if (frame%64==0)		;
	beq	dec_tree1						; 3

	; need to do 19-5 cycles of nonsense				; -1
	inc	TREE1X							; 5
	dec	TREE1X							; 5
	lda	#0							; 2
	lda	#0							; 2

	jmp	done_tree1						; 3

dec_tree1:
	dec	TREE1X			; tree1_x--			; 5
	lda	TREE1X							; 3
	bmi	tree1_neg						; 3

									;-1
	ldx	TREE1X							; 3
	jmp	done_tree1						; 3
tree1_neg:
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
	; Frame Update		  -30
	; Tree1 Update		  -22
	; Tree2 Update		  -24
	; hgr bits		   -8
	; ======================  411 cycles

	; Try X=1 Y=37 cycles=408 R2
	; Try X=7 Y=10 cycles=411

	ldy	#10							; 2
loop3:
	ldx	#7							; 2
loop4:
	dex								; 2
	bne	loop4							; 2nt/3

	dey								; 2
	bne	loop3							; 2nt/3

;===========================================================================


	; gr
	bit	LORES							; 4


	; Mockingboard went here***

	; lores want 	5200
	; mockingboard			-492
	; softswitch	  -4
	;===================
	;		5196 cycles

	; Try X=46 Y=22 cycles=5193 R3

	lda	$0							; 3

	ldy	#22							; 2
bmloop5:ldx	#46							; 2
bmloop6:dex								; 2
	bne	bmloop6							; 2nt/3
	dey								; 2
	bne	bmloop5							; 2nt/3

;========================================================================

	; vertical blank

	; want 4550 cycles
	; Try X=13 Y=64 cycles=4545 R2

;=========================================================================

	jsr	move_letters					; 6+126

	; Blanking time:	 4550
	; move_letters		 -132
	; play_music		-1038
	; check keypress	   -7
	; JMP at end		   -3
	;========================3370 cycles

	jsr	play_music	; 6+1032

	; Try X=175 Y=5 cycles=4406 R2
	; Try X=17 Y=37 cycles=3368 R2

	nop								; 2

	ldy	#37							; 2
bmloop7:ldx	#17							; 2
bmloop8:dex								; 2
	bne	bmloop8							; 2nt/3
	dey								; 2
	bne	bmloop7							; 2nt/3

	; Skip if keypressed

	lda	KEYPRESS						; 4
	bpl	bm_no_keypress						; 3
        jmp	bm_done							; 3
bm_no_keypress:

	jmp	bm_display_loop						; 3

bm_done:
	bit	KEYRESET	; clear keypress			; 4
	cli		; re-enable interrupt music
	rts								; 6

;===========================================================
;===========================================================
;===========================================================

;wait_until_keypressed:
;	lda	KEYPRESS			; check if keypressed
;	bpl	wait_until_keypressed		; if not, loop
;	bit	KEYRESET
;	rts


.align $100
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


;.align	$100
;.include "tfv_sprites.inc"

;katahdin:
;.incbin	"KATC.BIN.lz4",11		; skip the header
;katahdin_end:


