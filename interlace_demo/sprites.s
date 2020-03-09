; TODO
; + merge with spacebars code
; + end of game, fly to the right
; + make harder as shoot more
; + end level with enough hits?


; Uses the 40x48d page1/page2 every-1-scanline pageflip mode

; self modifying code to get some extra colors (pseudo 40x192 mode)

; by deater (Vince Weaver) <vince@deater.net>

; Zero Page
FRAMEBUFFER	= $00	; $00 - $0F
CH		= $24
CV		= $25
GBASL		= $26
GBASH		= $27
BASL		= $28
BASH		= $29
FRAME		= $60
BLARGH		= $69
SPRITE_XPOS	= $E0
SPRITE_YPOS	= $E1
RANDOM_PTR	= $E2

ASTEROID_X	= $E3
ASTEROID_Y	= $E4
ASTEROID_SUBX	= $E5
ASTEROID_EXPLODE= $E6
DRAW_PAGE	= $EE
XPOS		= $EF

FIRE_X		= $F0
FIRE_Y		= $F1
YPOS		= $F2
YADD		= $F3
BLAST1		= $F4
BLAST2		= $F5
FIRE		= $F6
TEMP		= $F7
WHICH		= $F8
TEMPY		= $F9
LEVEL_DONE	= $FA
ASTEROID_SPEED	= $FB
INL		= $FC
INH		= $FD
OUTL		= $FE
OUTH		= $FF

GREEN0		= $80
GREEN1		= $81
GREEN2		= $82
GREEN3		= $83
GREEN4		= $84
ZERO		= $85
GAME_OVER	= $86

; Soft Switches
KEYPRESS= $C000
KEYRESET= $C010
SET_GR	= $C050 ; Enable graphics
FULLGR	= $C052	; Full screen, no text
PAGE0	= $C054 ; Page0
PAGE1	= $C055 ; Page1
LORES	= $C056	; Enable LORES graphics
PADDLE_BUTTON0 = $C061
PADDL0	= $C064
PTRIG	= $C070

; ROM routines

TEXT	= $FB36				;; Set text mode
HOME	= $FC58				;; Clear the text screen
WAIT	= $FCA8				;; delay 1/2(26+27A+5A^2) us


start_sprites:

	;===================
	; init screen
	jsr	TEXT
	jsr	HOME
	bit	KEYRESET

	;===================
	; init vars

	lda	#0
	sta	DRAW_PAGE
	sta	WHICH
	sta	ZERO
	sta	YADD
	sta	LEVEL_DONE
	sta	FIRE_X
	sta	ASTEROID_SUBX
	sta	ASTEROID_EXPLODE

	lda	#$44
	sta	GREEN0
	sta	GREEN4
	lda	#$cc
	sta	GREEN1
	sta	GREEN3
	lda	#$ff
	sta	GREEN2

	lda	#36
	sta	ASTEROID_X

	lda	#12
	sta	ASTEROID_Y

	lda	#64
	sta	YPOS

	lda	#1
	sta	ASTEROID_SPEED
	sta	XPOS

	;=============================
	; Load graphic page0

	lda	#$0c
	sta	BASH
	lda	#$00
	sta	BASL                    ; load image to $c00

	lda	WHICH
	asl
	asl				; which*4
	tay

	lda	pictures,Y
	sta	GBASL
	lda	pictures+1,Y
	sta	GBASH
	jsr	load_rle_gr

	lda	#4
	sta	DRAW_PAGE

	jsr	gr_copy_to_current	; copy to page1

	; GR part
	bit	PAGE1
	bit	LORES							; 4
	bit	SET_GR							; 4
	bit	FULLGR							; 4

	;=============================
	; Load graphic page1

	lda	#$0c
	sta	BASH
	lda	#$00
	sta	BASL                    ; load image to $c00

	lda	WHICH
	asl
	asl				; which*4
	tay

	lda	pictures+2,Y
	sta	GBASL
	lda	pictures+3,Y
	sta	GBASH
	jsr	load_rle_gr

	lda	#0
	sta	DRAW_PAGE

	jsr	gr_copy_to_current

;	; GR part
	bit	PAGE0

	;==============================
	; setup graphics for vapor lock
	;==============================

	jsr	vapor_lock

	; vapor lock returns with us at beginning of hsync in line
	; 114 (7410 cycles), so with 5070 lines to go

	; GR part
	bit	LORES							; 4
	bit	SET_GR							; 4
	bit	FULLGR							; 4

	jsr	gr_copy_to_current			; 6+ 9292

	; 5070 + 4550 = 9620
	;		9292
	;		  12
	;		   6
	;		====
	;		 310

	; - 3 for jmp
	; 307

	; Try X=9 Y=6 cycles=307

	ldy	#6							; 2
loopA:	ldx	#9							; 2
loopB:	dex								; 2
	bne	loopB							; 2nt/3
	dey								; 2
	bne	loopA							; 2nt/3

	jmp	display_loop						; 3

.align  $100

	;================================================
	; Display Loop
	;================================================
	; each scan line 65 cycles
	;       1 cycle each byte (40cycles) + 25 for horizontal
	;       Total of 12480 cycles to draw screen
	; Vertical blank = 4550 cycles (70 scan lines)
	; Total of 17030 cycles to get back to where was

	; We want to alternate between page1 and page2 every 65 cycles
        ;       vblank = 4550 cycles to do scrolling


display_loop:

.include "sprites_screen.s"

	;======================================================
	; We have 4550 cycles in the vblank, use them wisely
	;======================================================

	; 4550	-- VBLANK
	;-1835	-- draw ship (131*14)+1
	; -829	-- erase ship (100*8)+(14*2)+1
	; -167	-- erase fire
	; -348	-- erase asteroid
	;  -31	-- move ship
	;  -17  -- move fire
	;  -56  -- collide asteroid/fire
	;  -40	-- collide ship
	;  -35	-- move asteroid
	; -436	-- draw fire
	; -337	-- draw asteroid
	;  -61  -- keypress
	;  -33	-- handle fire press
	;  -51	-- exploding asteroid
	;  -47	-- sparkle
	;  -36 	-- blast (18+18)
	;  -25  -- loop
	;  -3	-- alignment
	;=======
	;  163
	; -40 nop sled


	;================
	; erase old ship

	ldy	YPOS			; 3		; 0
	jsr	erase_line		; 6+94

	iny				; 2		; 1
	jsr	erase_line		; 6+94

	iny				; 2		; 2
	jsr	erase_line		; 6+94

	iny				; 2		; 3
	jsr	erase_line		; 6+94

	; note, to be complete should erase all these
	; only an issue if moving up/down really fast

	iny				; 2		; 4
;	jsr	erase_line		; 6+94
	iny				; 2		; 5
;	jsr	erase_line		; 6+94
	iny				; 2		; 6
;	jsr	erase_line		; 6+94
	iny				; 2		; 7
;	jsr	erase_line		; 6+94
	iny				; 2		; 8
;	jsr	erase_line		; 6+94
	iny				; 2		; 9
;	jsr	erase_line		; 6+94
	iny				; 2		; 10
	jsr	erase_line		; 6+94
	iny				; 2		; 11
	jsr	erase_line		; 6+94
	iny				; 2		; 12
	jsr	erase_line		; 6+94
	iny				; 2		; 13
	jsr	erase_line		; 6+94

	;==========================
	; erase the fire
	;==========================

	ldy	FIRE_Y			; 3
	iny				; 2
	jsr	erase_fire		; 6+71
	iny				; 2
	iny				; 2
	iny				; 2
	iny				; 2
	jsr	erase_fire		; 6+71
					;========
					; 167

;	jsr	erase_fire		; 6+71
;	jsr	erase_fire		; 6+71
;	jsr	erase_fire		; 6+71
					;====
					; 388




	;=====================
	; erase the asteroid

	lda	#$0			; 2
	sta	DRAW_PAGE		; 3

	lda	#<void_p1		; 2
	sta	INL			; 3
	lda	#>void_p1		; 2
	sta	INH			; 3
	lda	ASTEROID_X		; 3
	sta	SPRITE_XPOS		; 3
	lda	ASTEROID_Y		; 3
	sta	SPRITE_YPOS		; 3
	jsr	put_sprite		; 6+304
					;======
					; 337


	;==========================
	; move the asteroid
	;==========================
	; move none:			16 	 [12+7]	= 35
	; move ok:			16+12    [7]	= 35
	; move off screen:		16+12+7 	= 35
	; game over: who cares
move_asteroid:
	clc			; 2
	lda	ASTEROID_SUBX	; 3
	adc	ASTEROID_SPEED	; 3
	sta	ASTEROID_SUBX	; 3
	cmp	#$12		; 2
	bcc	no_new_asteroid2; 3 blt
				;========
				; 16

				; -1
	lda	#0		; 2
	sta	ASTEROID_SUBX	; 3
	dec	ASTEROID_X	; 5
	bne	no_new_asteroid	; 3
				;=====
				; 12
new_asteroid:
						; -1
	lda	#7				; 2
	sta	ASTEROID_EXPLODE		; 3
	jmp	done_move_asteroid		; 3
					;===========
					;	7

no_new_asteroid2:
	inc	TEMP				; 5
	inc	TEMP				; 5
	nop					; 2

no_new_asteroid:
	nop					; 2
	nop					; 2
	lda	TEMP				; 3
						;====
						; 7

done_move_asteroid:



	;==========================
	; move the fire
	;==========================
	; no-fire:	6+7	= 13 [4]
	; too-far:	6+4+7	= 17
	; moving:	6+4+7	= 17


	lda	FIRE_X		; 3
	beq	no_fire		; 3
				; -1
	cmp	#39		; 2
	bcs	kill_fire	; bge 3
				; -1
	inc	FIRE_X		; 5
	jmp	done_move_fire	; 3
no_fire:
	nop
	nop
kill_fire:
	nop			; 2
	lda	#0		; 2
	sta	FIRE_X		; 3
done_move_fire:


	;==========================
	; move the ship
	; in bounds:	14+5 =    19 [12]
	; too small:	14+10 =   24 [7]
	; too big:	14+5+12 = 31

	clc				; 2
	lda	YPOS			; 3
	adc	YADD			; 3
	sta	YPOS			; 3
	bpl	not_minus		; 3

minus:
					; -1
	lda	#$0			; 2
	sta	YPOS			; 3
	sta	YADD			; 3
	jmp	done_move_delay_7	; 3
not_minus:
	cmp	#104			; 2
	bcc	done_move_delay_12	; blt	; 3
					; -1
	lda	#$0			; 2
	sta	YADD			; 3
	lda	#103			; 2
	sta	YPOS			; 3
	jmp	done_move		; 3
done_move_delay_12:
	lda	TEMP			; 3
	nop				; 2
done_move_delay_7:
	lda	TEMP			; 3
	nop				; 2
	nop				; 2

done_move:


nop_sled:
	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop



	;==========================
	; collision (fire/asteroid)
	;==========================
	; none:			13    [20+23]
	; xmatch not y:		13+20 [23]
	; explosion:		13+20+23 = 56

	sec				; 2
	lda	ASTEROID_X		; 3
	sbc	FIRE_X			; 3
	cmp	#252			; 2
	bcc	no_collide_x		; 3	; blt
					;===
					; 13

					; -1
	lda	FIRE_Y			; 3
	lsr				; 2
	lsr				; 2
	clc				; 2
	adc	#$9			; 2
	sec				; 2
	sbc	ASTEROID_Y		; 3
	cmp	#4			; 2
	bcs	no_collide_y		; 3	; bge
					;===
					; 20

					; -1
	lda	#1			; 2
	sta	ASTEROID_EXPLODE	; 3

	inc	ASTEROID_SPEED		; 5

	lda	#0			; 2
	sta	FIRE_X			; 3

	inc	$408			; 6

	jmp	collision_done		; 3
					;====
					; 23
no_collide_x:
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5

no_collide_y:
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5
	lda	TEMP	; 3

collision_done:


	;==========================
	; collision (ship/asteroid)
	;==========================
	; none:			8    [20+12]
	; xmatch not y:		8+20 [12]
	; explosion:		8+20+12 = 40
ship_collision:

	lda	ASTEROID_X		; 3
	cmp	#$8			; 2
	bcs	no_ship_collide_x	; 3	; blt
					;===
					; 8

					; -1
	lda	YPOS			; 3
	lsr				; 2
	lsr				; 2
	clc				; 2
	adc	#10			; 2
	sec				; 2
	sbc	ASTEROID_Y		; 3
	cmp	#6			; 2
	bcs	no_ship_collide_y	; 3	; bge
					;===
					; 20

					; -1
	lda	#1			; 2
	sta	ASTEROID_EXPLODE	; 3

	lda	#1			; 2
	sta	LEVEL_DONE		; 3

	lda	#1
	sta	GAME_OVER

	jmp	ship_collision_done	; 3
					;====
					; 12
no_ship_collide_x:
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5

no_ship_collide_y:
	lda	TEMP	; 3
	lda	TEMP	; 3
	lda	TEMP	; 3
	lda	TEMP	; 3

ship_collision_done:




	;==========================
	; draw the ship

	ldy	YPOS			; 3

	; line 0
	ldx	#0			; 2
	jsr	sprite_line		; 6+121
					;====
					; 129

	; line 1
	iny				; 2
	ldx	#7			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 2
	iny				; 2
	ldx	#14			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 3
	iny				; 2
	ldx	#21			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 4
	iny				; 2
	ldx	#28			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 5
	iny				; 2
	ldx	#35			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 6
	iny				; 2
	ldx	#42			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 7
	iny				; 2
	ldx	#49			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 8
	iny				; 2
	ldx	#56			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 9
	iny				; 2
	ldx	#63			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 10
	iny				; 2
	ldx	#70			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 11
	iny				; 2
	ldx	#77			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 12
	iny				; 2
	ldx	#84			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131

	; line 13
	iny				; 2
	ldx	#91			; 2
	jsr	sprite_line		; 6+121
					;====
					; 131




	;==========================
	; draw the fire
	;==========================
	; 6+(61*7)+3 = 436

	lda	FIRE_X			; 3
	beq	no_draw_fire		; 3
					; -1
	ldy	FIRE_Y			; 3

	; line 0
	ldx	#0			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 1
	iny				; 2
	ldx	#1			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 2
	iny				; 2
	ldx	#2			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 3
	iny				; 2
	ldx	#3			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 4
	iny				; 2
	ldx	#4			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 5
	iny				; 2
	ldx	#5			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 6
	iny				; 2
	ldx	#5	; zero again	; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	jmp	done_draw_fire		; 3

no_draw_fire:

	; want 436, have 6+1+(61*7)=434

	nop	; 2

	ldy	FIRE_Y			; 3

	; line 0
	ldx	#5			; 2
	jsr	fire_line		; 6+51
					;====
					; 61+1

	; line 1
	iny				; 2
	ldx	#5			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 2
	iny				; 2
	ldx	#5			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 3
	iny				; 2
	ldx	#5			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 4
	iny				; 2
	ldx	#5			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 5
	iny				; 2
	ldx	#5			; 2
	jsr	fire_line		; 6+51
					;====
					; 61

	; line 6
	iny				; 2
	ldx	#5	; zero again	; 2
	jsr	fire_line		; 6+51
					;====
					; 61

done_draw_fire:


	;=====================
	; draw the asteroid
draw_asteroid:
	lda	#$0			; 2
	sta	DRAW_PAGE		; 3

	lda	ASTEROID_EXPLODE	; 3
	and	#$fe			; 2
	tax				; 2
	lda	asteroid_lookup,X	; 4
	sta	INL			; 3
	lda	asteroid_lookup+1,X	; 4
	sta	INH			; 3
	lda	ASTEROID_X		; 3
	sta	SPRITE_XPOS		; 3
	lda	ASTEROID_Y		; 3
	sta	SPRITE_YPOS		; 3
	jsr	put_sprite		; 6+304
					;======
					; 348


	;=================
	; BLAST1
	;=================
	; blast1: 6+7+5		= 18
	; noblast1: 6+5+[7]

	lda	BLAST1		; 3
	beq	no_blast1d	; 3
blast1:
				; -1
	inc	ZERO		; 5
	jmp	no_blast1	; 3
no_blast1d:
	lda	TEMP		; 3
	nop			; 2
	nop			; 2

no_blast1:
	lda	#0		; 2
	sta	BLAST1		; 3


	;=================
	; BLAST2
	;=================
	; blast2: 6+7+5		= 18
	; noblast1: 6+5+[7]

	lda	BLAST2		; 3
	beq	no_blast2d	; 3
blast2:
				; -1
	lda	#0		; 2
	sta	ZERO		; 3
	jmp	no_blast2	; 3
no_blast2d:
	lda	TEMP
	nop
	nop
no_blast2:
	lda	#0		; 2
	sta	BLAST2		; 3




	;==================
	; sparkle flame
	;==================
	; 14+20+13 = 47

sparkle_flame:
	inc	FRAME			; 5
	lda	FRAME			; 3
	and	#$7			; 2
	asl				; 2
	tay				; 2

	 ; Set up jump table that runs same speed on 6502 and 65c02
	lda	jump_table+1,y					; 4
	pha							; 3
	lda	jump_table,y					; 4
	pha							; 3
	rts							; 6
                                                        ;=============
                                                        ;        20
jump_table:
	.word	(sparkle1-1),(sparkle_motion-1),(sparkle2-1),(sparkle_motion-1)
	.word	(sparkle3-1),(sparkle_motion-1),(sparkle4-1),(sparkle_motion-1)

sparkle1:
	lda	ship_sprite_l9+0	; 4
	eor	#$88			; 2
	sta	ship_sprite_l9+0	; 4
	jmp	done_sparkle		; 3

sparkle2:
	lda	ship_sprite_l9+1	; 4
	eor	#$88			; 2
	sta	ship_sprite_l9+1	; 4
	jmp	done_sparkle		; 3

sparkle3:
	lda	ship_sprite_l8+0	; 4
	eor	#$44			; 2
	sta	ship_sprite_l8+0	; 4
	jmp	done_sparkle		; 3

sparkle4:
	lda	ship_sprite_l10+0	; 4
	eor	#$44			; 2
	sta	ship_sprite_l10+0	; 4
	jmp	done_sparkle		; 3

sparkle_motion:
	lda	TEMP			; 3
	lda	TEMP			; 3
	nop
	nop
	jmp	done_sparkle		; 3

done_sparkle:




pad_time:


	;============================
	; WAIT for VBLANK to finish
	;============================

wait_loop:

	; Try X=11 Y=2 cycles=123

	ldy	#2							; 2
loop1:	ldx	#11							; 2
loop2:	dex								; 2
	bne	loop2							; 2nt/3
	dey								; 2
	bne	loop1							; 2nt/3
wait_loop_end:

	;===============
	; check keypress

	jsr	handle_keypress					; 6+55

	;=================================
	; handle fire
	;=================================
	; FIRE: 6+5+17+5      = 33
	; FIRE but OUT: 6+5+5 = 16 [17]
	; no FIRE:      6+5   = 11 [22]
	; urgh pain to make this invariant

	lda	FIRE			; 3
	beq	no_firing2		; 3
					; -1

	lda	FIRE_X			; 3
	bne	no_firing		; 3
					; -1

	clc				; 2
	lda	YPOS			; 3
	adc	#10			; 2
	sta	FIRE_Y			; 3

	lda	#7			; 2
	sta	FIRE_X			; 3

	jmp	really_no_firing	; 3

no_firing2:
	inc	TEMP			; 5
no_firing:
	inc	TEMP			; 5
	inc	TEMP			; 5
	inc	TEMP			; 5
	nop				; 2

really_no_firing:
	lda	#0			; 2
	sta	FIRE			; 3


alignment:
	jmp	blah			; 3
.align $100

blah:
	;=================================
	; handle exploding asteroid
	;=================================
	; none: 	6    [12+33]
	; exploding:	6+12 [33]
	; done:		6+12+33 = 51

	lda	ASTEROID_EXPLODE	; 3
	beq	asteroid_no_explode	; 3
					;==
					; 6

					; -1
	inc	ASTEROID_EXPLODE	; 5
	lda	ASTEROID_EXPLODE	; 3
	cmp	#9			; 2
	bne	asteroid_not_done	; 3
					;===
					; 12
asteroid_done:
						; -1
	lda	#0				; 2
	sta	ASTEROID_EXPLODE		; 3
	inc	RANDOM_PTR			; 5
	ldy	RANDOM_PTR			; 3
	lda	random_values,Y			; 4
	and	#$1e				; 2
	clc					; 2
	adc	#$4				; 2
	sta	ASTEROID_Y			; 3
	lda	#36				; 2
	sta	ASTEROID_X			; 3
	jmp	asteroid_done_done		; 3
						;====
						;33
asteroid_no_explode:
	inc	TEMP	; 5
	inc	TEMP	; 5
	nop		; 2
asteroid_not_done:
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5
	inc	TEMP	; 5
	lda	TEMP	; 3
asteroid_done_done:


	;=========================
	; check for end
	;=========================
	; not done = 6+3 = 9 + [16] = 25
	; done	   = who cares
	; dying    = 6+4+12+3 = 25

	lda	LEVEL_DONE					; 3
	beq	final_loop_short				; 3

								;-1
	cmp	#1						;2
	beq	done_level					;3

								;-1
	dec	LEVEL_DONE					; 5
	inc	XPOS						; 5
	jmp	final_loop					; 3
								;=====
								; 12 

final_loop_short:
	inc	TEMP
	inc	TEMP
	lda	TEMP
	lda	TEMP
final_loop:

	jmp	display_loop					; 3

done_level:
	rts






.align	$100
	;=======================
	; handle keypress
	;=======================
	; separate function so we an align to avoid branches
	; crossing page boundaries
	;
	; NONE = 6+7			= 13	[42]
	; ESC  = doesn't matter
	; ' '  = 6+6+9+5+7		= 33	[22] [[20]]
	; '.'  = 6+6+9+5+5+7		= 48	[17] [[5]]
	; ','  = 6+6+9+5+5+5+7		= 43	[12] [[5]]
	; 'A'  = 6+6+9+5+5+5+7+7	= 50	[5]  [[7]]
	; 'Z'  = 6+6+9+5+5+5+7+5+7	= 55	[0]  [[5]]
	; unkno= 6+6+9+5+5+5+7+5+3+[4]	= 55	[0]
handle_keypress:
	lda	KEYPRESS				; 4
	bpl	key_delay_42				; 3
							; -1

	bit	KEYRESET	; clear strobe		; 4

	cmp	#27+$80					; 2
	bne	key_not_escape				; 3

	lda	#32
	sta	LEVEL_DONE

	rts

key_not_escape:

	cmp	#' '+$80				; 2
	bne	key_not_space				; 3
							; -1
	lda	#$ff					; 2
	sta	FIRE					; 3
	jmp	key_delay_22				; 3

key_not_space:
	cmp	#'.'+$80				; 2
	bne	key_not_period				; 3
							; -1
	lda	#1					; 2
	sta	BLAST1					; 3
	jmp	key_delay_17				; 3

key_not_period:
	cmp	#','+$80				; 2
	bne	key_not_comma				; 3
							; -1
	lda	#1					; 2
	sta	BLAST2					; 3
	jmp	key_delay_12				; 3

key_not_comma:
	and	#$5f	; make uppercase		; 2

	cmp	#'A'					; 2
	bne	key_not_a				; 3
							; -1
	dec	YADD					; 5
	jmp	key_delay_5				; 3

key_not_a:
	cmp	#'Z'					; 2
	bne	key_not_z				; 3
							; -1
	inc	YADD					; 5
	jmp	keypress_done				; 3

key_not_z:
	nop						; 2
	nop						; 2
	jmp	keypress_done				; 3

key_delay_42:
	inc	TEMP					; 5
	dec	TEMP					; 5
	inc	TEMP					; 5
	dec	TEMP					; 5

key_delay_22:
	nop						; 2
	lda	TEMP					; 3
key_delay_17:
	nop						; 2
	lda	TEMP					; 3
key_delay_12:
	nop						; 2
	nop						; 2
	lda	TEMP					; 3

key_delay_5:
	nop						; 2
	lda	TEMP					; 3

keypress_done:
	rts						; 6



	;========================
	; Draw a line of a sprite
	;========================
	; Y = y value
	; x = location in sprite
	; 17+11+(7*12)+3+6 = 121
sprite_line:
	sty	TEMPY			; 3

	lda	y_lookup_l,Y		; 4
	sta	OUTL			; 3
	lda	y_lookup_h,Y		; 4
	sta	OUTH			; 3
					;=======
					; 17

	; XPOS
	lda	XPOS			; 3
	ldy	#0			; 2
	sta	(OUTL),Y		; 6
					;=======
					; 11
	; COL0
	ldy	#2			; 2
	lda	ship_sprite+0,X		; 4
	sta	(OUTL),Y		; 6
					;=======
					; 12

	; COL1
	ldy	#7			; 2
	lda	ship_sprite+1,X		; 4
	sta	(OUTL),Y		; 6
					;=======
					; 12

	; COL2
	ldy	#12			; 2
	lda	ship_sprite+2,X		; 4
	sta	(OUTL),Y		; 6
					;=======
					; 12

	; COL3
	ldy	#17			; 2
	lda	ship_sprite+3,X		; 4
	sta	(OUTL),Y		; 6
					;=======
					; 12

	; COL4
	ldy	#22			; 2
	lda	ship_sprite+4,X		; 4
	sta	(OUTL),Y		; 6
					;=======
					; 12

	; COL5
	ldy	#27			; 2
	lda	ship_sprite+5,X		; 4
	sta	(OUTL),Y		; 6
					;=======
					; 12

	; COL6
	ldy	#32			; 2
	lda	ship_sprite+6,X		; 4
	sta	(OUTL),Y		; 6
					;=======
					; 12

	ldy	TEMPY			; 3
	rts				; 6


	;========================
	; Erase a line of a sprite
	;========================
	; Y = y value
	; 17+10+2+(7*8)+3+6 = 94
erase_line:
	sty	TEMPY			; 3

	lda	y_lookup_l,Y		; 4
	sta	OUTL			; 3
	lda	y_lookup_h,Y		; 4
	sta	OUTH			; 3
					;=======
					; 17

	; XPOS
	lda	#1	; xpos=1	; 2
	ldy	#0			; 2
	sta	(OUTL),Y		; 6
					;=======
					; 10

	lda	#0			; 2

	; COL0
	ldy	#2			; 2
	sta	(OUTL),Y		; 6
	; COL1
	ldy	#7			; 2
	sta	(OUTL),Y		; 6
	; COL2
	ldy	#12			; 2
	sta	(OUTL),Y		; 6
	; COL3
	ldy	#17			; 2
	sta	(OUTL),Y		; 6
	; COL4
	ldy	#22			; 2
	sta	(OUTL),Y		; 6
	; COL5
	ldy	#27			; 2
	sta	(OUTL),Y		; 6
	; COL6
	ldy	#32			; 2
	sta	(OUTL),Y		; 6

	ldy	TEMPY			; 3
	rts				; 6

	;========================
	; Draw a line of a fire
	;========================
	; Y = y value
	; x = location in sprite
	; 17+11+14+9 = 51
fire_line:
	sty	TEMPY			; 3

	lda	y_lookup_l,Y		; 4
	sta	OUTL			; 3
	lda	y_lookup_h,Y		; 4
	sta	OUTH			; 3
					;=======
					; 17

	; 38/40
	; XPOS
	lda	FIRE_X			; 3
	ldy	#37			; 2
	sta	(OUTL),Y		; 6
					;=======
					; 11
	; COL0
	ldy	#39			; 2
	txa				; 2
	ora	#$80			; 2
	tax				; 2
	sta	(OUTL),Y		; 6
					;=======
					; 14

	ldy	TEMPY			; 3
	rts				; 6
					;=======
					; 9


	;========================
	; Erase a line of a fire
	;========================
	; Y = y value
	; 31+29+11 = 71
erase_fire:
	sty	TEMPY			; 3

	tya				; 2
	lsr				; 2
	lsr				; 2
	and	#$fe			; 2
	clc				; 2
	adc	#$8			; 2

	tay				; 2

	lda	gr_offsets,Y		; 4
	sta	OUTL			; 3
	lda	gr_offsets+1,Y		; 4
	sta	OUTH			; 3
					;=======
					; 31

	ldy	FIRE_X			; 3
	lda	#0			; 2
	sta	(OUTL),Y		; 6
	lda	#$4			; 2
	clc				; 2
	adc	OUTH			; 3
	sta	OUTH			; 3
	lda	#0			; 2
	sta	(OUTL),Y		; 6
					;======
					; 29

	; ldx in smc should already be
	; set to value from last draw?

	; COL0
;	ldy	#6			; 2
;	lda	(OUTL),Y		; 5+
;	sta	fz_smc+1		; 5
;	iny				; 2
;	lda	(OUTL),Y		; 5+
;	sta	fz_smc+2		; 5
;	lda	#0			; 2
;fz_smc:
;	sta	$c00,Y			; 5
					;=======
					; 31

	ldy	TEMPY			; 3
	iny				; 2
	rts				; 6
					;=======
					; 11


.include "gr_simple_clear.s"


.include "../asm_routines/gr_unrle.s"
;.include "../asm_routines/keypress.s"
.align $100
random_values:
.incbin	"random.data"
.include "sprites_table.s"
.include "gr_offsets.s"

;.include "movement_table.s"
.include "gr_copy.s"
.include "vapor_lock.s"
.include "delay_a.s"
.align $100
.include "gr_putsprite.s"

.assert >gr_offsets = >gr_offsets_done, error, "gr_offsets crosses page"
.assert >wait_loop = >(wait_loop_end-1), error, "wait_loop crosses page"

pictures:
	.word earth_low,earth_high

.include "earth.inc"

.align $100

ship_sprite:
	; l0:     0   1   2   3   4   5   6
	.byte	$00,$00,$00,$ff,$00,$00,$00
	; l1:
	.byte	$00,$00,$00,$ff,$00,$00,$00
	; l2:
	.byte	$00,$00,$00,$ff,$00,$00,$00
	; l3:
	.byte	$00,$00,$00,$ff,$00,$00,$00
	; l4:
	.byte	$00,$00,$00,$77,$00,$00,$00
	; l5:
	.byte	$00,$00,$00,$ff,$ff,$22,$00
	; l6:
	.byte	$00,$00,$22,$ff,$ff,$22,$00
	; l7:
	.byte	$00,$dd,$66,$11,$22,$22,$00
	; l8:
ship_sprite_l8:
	.byte	$dd,$99,$22,$44,$44,$22,$22
	; l9:
ship_sprite_l9:
	.byte	$99,$11,$66,$ff,$ff,$22,$22
	; l10:
ship_sprite_l10:
	.byte	$dd,$99,$22,$ff,$ff,$22,$22
	; l11:
	.byte	$00,$dd,$66,$77,$77,$77,$ff
	; l12:
	.byte	$00,$00,$22,$ff,$ff,$77,$ff
	; l13:
	.byte	$00,$00,$00,$ff,$ff,$77,$ff


.include	"asteroid.inc"
