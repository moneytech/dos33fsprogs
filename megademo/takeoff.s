; Rocket Takeoff

; Simple HGR/GR split


; STATE0 = RIDE IN ON BIRD
; STATE2 = BIRD RUNS / WALK INTO SHIP
; STATE4 = PAUSE / SMOKE OUT BACK
; STATE6 = ROTATING / FLAME SPRITES + TREES MOVING/SPEED UP
;          also horizon drop away?


	; 5 4 3 2 1 blastoff, another rocketship run
	; o/~ Take me to the moon o/~
rocket_takeoff:


	;===================
	; init screen
	bit	KEYRESET

setup_rocket:


	;===================
	; init vars

	lda	#0
	sta	DRAW_PAGE
	sta	FRAME
	sta	FRAMEH
	sta	STATE
	lda	#1
	sta	XX

	;=============================
	; Load graphic hgr

	lda	#<takeoff_hgr
	sta	LZ4_SRC
	lda	#>takeoff_hgr
	sta	LZ4_SRC+1

	lda	#<(takeoff_hgr_end-8)	; skip checksum at end
	sta	LZ4_END
	lda	#>(takeoff_hgr_end-8)	; skip checksum at end
	sta	LZ4_END+1

	lda	#<$2000
	sta	LZ4_DST
	lda	#>$2000
	sta	LZ4_DST+1
	sta	HGR_PAGE

	jsr	lz4_decode

	jsr	draw_stars

	;=============================
	; Load graphic page0

	lda	#$0c
	sta	BASH
	lda	#$00
	sta	BASL                    ; load image to $c00


	lda	#<takeoff
	sta	GBASL
	lda	#>takeoff
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

	bit	PAGE0

	sei		; disable interrupt music

	;==============================
	; setup graphics for vapor lock
	;==============================

	jsr	vapor_lock						; 6

	; vapor lock returns with us at beginning of hsync in line
	; 114 (7410 cycles), so with 5070 lines to go

	jsr	gr_copy_to_current		; 6+ 9292

	; now we have 322 left

	; GR part
	bit	LORES							; 4
	bit	SET_GR							; 4
	bit	FULLGR							; 4

	; 322 - 12 = 310
	; - 3 for jmp
	; 307

	; Try X=9 Y=6 cycles=307

        ldy	#6							; 2
toloopA:ldx	#9							; 2
toloopB:dex								; 2
	bne	toloopB							; 2nt/3
	dey								; 2
	bne	toloopA							; 2nt/3

	jmp	to_begin_loop
.align  $100


	;================================================
	; Takeoff Loop
	;================================================
	; each scan line 65 cycles
	;       1 cycle each byte (40cycles) + 25 for horizontal
	;       Total of 12480 cycles to draw screen
	; Vertical blank = 4550 cycles (70 scan lines)
	; Total of 17030 cycles to get back to where was

	; want 12*4 = 48 lines of HIRES = 3120-4=3116
	; want 192-48=144 lines of LORES = 9360-4=9356



to_begin_loop:
	; 12*4 = 48 lines of HIRES = 3120
	;                              -4 set HIRES
	;			    -1038 play_music
	;			=========
	;			     2078

	bit	HIRES			; 4

	jsr	play_music	; 6 + 1032

	; Try X=5 Y=67 cycles=2078
	; Try X=11 Y=51 cycles=3112 R4


	ldy	#67							; 2
toloop8:ldx	#5							; 2
toloop9:dex								; 2
	bne	toloop9							; 2nt/3
	dey								; 2
	bne	toloop8							; 2nt/3



	;===========================
	; Draw Lores bottom
	; 144 * 65 = 9360
	;	       -4 swith to LORES
	;====================
	;	     9356


	bit	LORES			; 4

	; Try X=10 Y=167 cycles=9353 R3

	lda	$0

	ldy	#167							; 2
toloop6:ldx	#10							; 2
toloop7:dex								; 2
	bne	toloop7							; 2nt/3
	dey								; 2
	bne	toloop6							; 2nt/3


;======================================================
; We have 4550 cycles in the vblank, use them wisely
;======================================================

	; do_nothing should be      4550
	;			     -23 state jump
	;			     -23 wrap counter
	;			      -7 timeout
	;			   -3886 state
	;			     -10 keypress
	;			===========
	;			      601


	;================
	; wrap counter
	;================
	; nowrap = 13+10=23
	;   wrap = 13+10=23
	inc	FRAME							; 5
	lda	FRAME							; 3
	cmp	#8	; 7.5 Hz						; 2
	beq	to_wrap							; 3
to_nowrap:
									;-1
	lda	$0			; nop				; 3
	lda	$0			; nop				; 3
	nop								; 2
	jmp	to_wrap_done						; 3
to_wrap:
	lda	#0							; 2
	sta	FRAME							; 3
	inc	FRAMEH							; 5
to_wrap_done:


	;==============
	; timeout after 5s or so?
	;==============
	; 7 cycles
to_timeout:
	lda	FRAMEH							; 3
	cmp	#68							; 2
	beq	to_exit							; 3
									; -1


	; Try X=118 Y=1 cycles=597 R4

	nop
	nop

	ldy	#1							; 2
toloop1:ldx	#118							; 2
toloop2:dex								; 2
	bne	toloop2							; 2nt/3
	dey								; 2
	bne	toloop1							; 2nt/3

	; Set up jump table that runs same speed on 6502 and 65c02
	ldy     STATE						; 3
	lda	to_jump_table+1,y				; 4
	pha							; 3
	lda	to_jump_table,y					; 4
	pha							; 3
	rts							; 6
                                                        ;=============
                                                        ;        23

to_done_state:


	lda	KEYPRESS				; 4
	bpl	to_no_keypress				; 3
	jmp	to_exit
to_no_keypress:

	jmp	to_begin_loop				; 3

to_exit:
	bit	KEYRESET	; clear keypress	; 4
	cli			; re-enable interrupt music
	rts						; 6


;.include "takeoff.inc"
;takeoff_hgr:
;.incbin "takeoff.img.lz4",11
;takeoff_hgr_end:

to_jump_table:
	.word   (to_state0-1)
	.word   (to_state2-1)
	.word   (to_state3-1)
	.word   (to_state4-1)

to_sprite_table:
	.word   (flame1)
	.word   (flame2)
	.word   (flame3)
	.word   (flame4)


;.align	$100

	;============================
	; state0: Draw+move Bird+Rider
	;============================
	; 3886
	; -578 gr_copy
	; -602 draw tree
	;  -13 inc xpos
	;  -19 which sprite
	;-2208 draw sprites
	;  -20 adjust state
	;   -3 jmp
	;====================
	;  443
to_state0:

	jsr	gr_copy_row22				; 6+572


	; draw tree
	lda	#32					; 2
	sta	XPOS					; 3
	lda     #30					; 2
	sta	YPOS					; 3
	lda	#>small_tree				; 2
	sta	INH                                     ; 3
	lda	#<small_tree				; 2
	sta	INL                                     ; 3
	jsr	put_sprite                              ; 6
							;========
							; 26 + 576 = 602



	; INC XX, 13 cycles
	lda	FRAME					; 3
	bne	to_xpos_no_inc				; 3
to_xpos_inc:						;-1
	inc	XX					; 5
	jmp	to_xpos_done				; 7
to_xpos_no_inc:
	lda	$0					; 3
	nop						; 2
	nop						; 2
to_xpos_done:


	lda     #22					; 2
	sta	YPOS					; 3
	lda	XX					; 3
	sta	XPOS					; 3
	lda	FRAMEH					; 3
	and	#$1					; 2
	beq	to_bwalk				; 3
						;===========
						;        19


to_bstand:
	; draw bird/rider standing                              ; -1
	lda	#>bird_rider_stand_right                ; 2
	sta	INH                                     ; 3
	lda	#<bird_rider_stand_right                ; 2
	sta	INL                                     ; 3
	jsr	put_sprite                              ; 6

	jmp	to_done_bwalk                           ; 3
                                                        ;=========
                                                        ; 18 + 2190 = 2208


to_bwalk:
	; draw bird/rider walking
	lda     #>bird_rider_walk_right			; 2
	sta     INH					; 3
	lda     #<bird_rider_walk_right			; 2
	sta     INL					; 3
	jsr     put_sprite				; 6

	nop						; 2
	lda	$0
	lda	$0
	lda	$0
	nop
	nop
	nop
	                                                ;=========
                                                        ; 33 + 2175 = 2208

to_done_bwalk:
	lda	XX					; 3
	cmp	#21					; 2
	bne	to_keep_state				; 3

							; -1
	inc	STATE					; 5
	inc	STATE					; 5
	jmp	to_done_keep_state			; 3
							;========
							; 12
to_keep_state:
	lda	$0
	lda	$0
	lda	$0
	lda	$0


to_done_keep_state:

        ; delay

	; Try X=4 Y=17 cycles=443

        ldy	#17							; 2
toloopV:ldx	#4							; 2
toloopW:dex                                                             ; 2
        bne	toloopW                                                 ; 2nt/3
        dey                                                             ; 2
        bne	toloopV                                                 ; 2nt/3

	jmp	to_done_state						; 3



.align	$100

	;============================
	; state2: Bird Returns
	;============================
	; want 3886
	;      -578 gr_copy
	;     -1418 tfv stand
	;       -15 xpos adjust
	;       -19 which sprite
	;     -1833 draw bird
	;       -20 (8+12) change state
	;        -3 jump back
	; ==========
	;         0

to_state2:

	jsr	gr_copy_row22				; 6+572

	; draw tfv

	lda     #22					; 2
	sta	YPOS					; 3
	lda	#21					; 2
	sta	XPOS					; 3
	lda	#>tfv_stand_right			; 2
	sta	INH                                     ; 3
	lda	#<tfv_stand_right			; 2
	sta	INL                                     ; 3
	jsr	put_sprite                              ; 6

                                                        ;=========
							; 26 + 1392 = 1418

	; INC XX, 15 cycles
	lda	FRAME					; 3
	and	#$3	; 0..7, 100 and 00		; 2
	bne	to2_xpos_no_inc				; 3
to2_xpos_inc:						;-1
	dec	XX					; 5
	jmp	to2_xpos_done				; 3
to2_xpos_no_inc:
	lda	$0					; 3
	nop						; 2
	nop						; 2
to2_xpos_done:


	lda     #24					; 2
	sta	YPOS					; 3
	lda	XX					; 3
	sta	XPOS					; 3

	lda	FRAMEH					; 3
	and	#$1					; 2
	beq	to2_bwalk				; 3
						;===========
						;        19


to2_bstand:
	; draw bird/rider standing                              ; -1
	lda	#>bird_stand_left_sprite		; 2
	sta	INH                                     ; 3
	lda	#<bird_stand_left_sprite		; 2
	sta	INL                                     ; 3
	jsr	put_sprite                              ; 6

	jmp	to2_done_bwalk				; 3
                                                        ;=========
                                                        ; 18 + 1815 = 1833


to2_bwalk:
	; draw bird/rider walking
	lda     #>bird_walk_left_sprite			; 2
	sta     INH					; 3
	lda     #<bird_walk_left_sprite			; 2
	sta     INL					; 3
	jsr     put_sprite				; 6

	inc	$0					; 5
	inc	$0					; 5
	inc	$0					; 5
	nop						; 2

	                                                ;=========
                                                        ; 16 + 17 + 1800 = 1833

to2_done_bwalk:
	lda	XX					; 3
	cmp	#1					; 2
	bne	to2_keep_state				; 3

							; -1
	inc	STATE					; 5
	inc	STATE					; 5
	jmp	to2_done_keep_state			; 3
							;========
							; 12
to2_keep_state:
	lda	$0
	lda	$0
	lda	$0
	lda	$0


to2_done_keep_state:

        ; delay

	; Try X=1 Y=104 cycles=1145 R5
	; Try X=13 Y=16 cycles=1137 R3

;	lda	$0

;	ldy	#16							; 2
;toloopT:ldx	#13							; 2
;toloopU:dex								; 2
;	bne	toloopU							; 2nt/3
;	dey								; 2
;	bne	toloopT							; 2nt/3

	jmp	to_done_state						; 3


.align	$100

	;============================
	; state3: Takeoff
	;============================
	; want 3886
	;      -578 gr_copy
	;	-31 handle door
	;       -37 flame
	;       -25 (8+17) change state
	;        -3 jump back
	; ==========
	;      3212

to_state3:

	jsr	gr_copy_row22				; 6+572

	; Erase door

	lda	#22					; 2
	sta	XPOS					; 3
	; $FF at 22,18 23,18
	; $FF at 22,20 23,20
	; $FF at 22,22 23,22
	; $45 at 22,24 23,24

	lda	#$ff					; 2
	sta	$4a8+22					; 4
	sta	$4a8+23					; 4
	sta	$528+22					; 4
	sta	$528+23					; 4
	sta	$da8+22					; 4
	sta	$da8+23					; 4
						;============
						; 31

	inc	XX					; 5
	lda	XX					; 3
	cmp	#$40					; 2
	bcs	to3_flame				; 3
						;============
						;	13

							; -1
	lda	$0					; 3
	nop						; 2
	lda	$0					; 3
	nop						; 2
	lda	$0					; 3
	nop						; 2
	lda	$0					; 3
	nop						; 2
	nop

	jmp	to3_done_flame				; 3
						;============
						; 	 24
to3_flame:
	lda	#$d4					; 2
	sta	$428+5		; 5,8			; 4
	lda	#$9d					; 2
	sta	$428+6		; 6,8			; 4
	lda	#$4d					; 2
	sta	$4a8+5		; 5,9			; 4
	lda	#$d9					; 2
	sta	$4a8+6		; 6,9			; 4
						;============
						; 	 24
to3_done_flame:


to3_update_state:
	lda	XX					; 3
	cmp	#$60					; 2
	bne	to3_keep_state				; 3
							;=====
							; 8

							; -1
	inc	STATE					; 5
	inc	STATE					; 5
	lda	#32		; for tree		; 2
	sta	XX					; 3
	jmp	to3_done_keep_state			; 3
							;========
							; 17
to3_keep_state:
	lda	$0					; 3
	lda	$0					; 3
	lda	$0					; 3
	lda	$0					; 3
	lda	$0					; 3
	nop						; 2
						;=============
						;        17

to3_done_keep_state:

        ; delay

	; Try X=79 Y=8 cycles=3209 R3

	lda	$0

	ldy	#8							; 2
toloopG:ldx	#79							; 2
toloopH:dex								; 2
	bne	toloopH							; 2nt/3
	dey								; 2
	bne	toloopG							; 2nt/3

	jmp	to_done_state						; 3





	;============================
	; state4: Flame On
	;============================
	; 	3886
	;      -2217 flame
	;	 -20 erase landing legs
	;	-584 erase tree
	;	 -11 move tree
	;       -597 tree
	;         -3 return
	;  ===============
	;        454
to_state4:

	lda	FRAME					; 3
	and	#$3					; 2
	asl						; 2
	tax						; 2
	lda	to_sprite_table+1,x			; 4
	sta	INH                                     ; 3
	lda	to_sprite_table,x			; 4
	sta	INL                                     ; 3
						;=============
						;	23

	; draw flame

	lda     #14					; 2
	sta	YPOS					; 3
	lda	#0					; 2
	sta	XPOS					; 3
	jsr	put_sprite                              ; 6

                                                        ;=========
							; 16 + 23 + 2178 = 2217




	; erase tree

	lda	XX					; 3
	sta	XPOS					; 3
	jsr	gr_copy_row22				; 6+572


	; erase landing legs

	lda	#$44					; 2
	sta	$6a8+11		; 11,26 29,26		; 4
	sta	$6a8+29		; 29,26			; 4
	lda	#$45					; 2
	sta	$628+12					; 4
	sta	$628+28					; 4
							;=======
							; 20



	; move tree FRAME
	lda	FRAME					; 3
	beq	to_move_tree				; 3
to_no_move_tree:
							; -1
	lda	$0					; 3
	jmp	to_done_move_tree			; 3
to_move_tree:
	dec	XX					; 5
to_done_move_tree:


	; draw tree
	lda     #30					; 2
	sta	YPOS					; 3
	lda	#>small_tree				; 2
	sta	INH                                     ; 3
	lda	#<small_tree				; 2
	sta	INL                                     ; 3
	jsr	put_sprite                              ; 6
							;========
							; 21 + 576 = 597

        ; delay

	; Try X=29 Y=3 cycles=454

	ldy	#3							; 2
toloopZ:ldx	#29							; 2
toloopY:dex                                                             ; 2
	bne	toloopY                                                 ; 2nt/3
	dey                                                             ; 2
	bne	toloopZ							; 2nt/3

	jmp	to_done_state						; 3




