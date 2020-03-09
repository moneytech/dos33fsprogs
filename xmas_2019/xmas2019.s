; XMAS2019 Demo

; + Display awesome tree
; + Starfield
; + Music
; + Snow

; by deater (Vince Weaver) <vince@deater.net>

; Zero Page
CH		= $24
CV		= $25
GBASL		= $26
GBASH		= $27
BASL		= $28
BASH		= $29

SEEDL		= $4E
SEEDH		= $4F

FRAME_PLAY_OFFSET=$56
FRAME_PLAY_PAGE = $57

WAITING         = $62
LETTERL         = $63
LETTERH         = $64
LETTERX         = $65
LETTERY         = $66
LETTERD         = $67
LETTER          = $68
BLARGH          = $69

AY_REGISTERS    = $70
A_FINE_TONE     = $70
A_COARSE_TONE   = $71
B_FINE_TONE     = $72
B_COARSE_TONE   = $73
C_FINE_TONE     = $74
C_COARSE_TONE   = $75
NOISE           = $76
ENABLE          = $77
PT3_MIXER_VAL   = $77
A_VOLUME        = $78
B_VOLUME        = $79
C_VOLUME        = $7A
ENVELOPE_FINE   = $7B
ENVELOPE_COARSE = $7C
ENVELOPE_SHAPE  = $7D

PATTERN_L	= $7E
PATTERN_H	= $7F
ORNAMENT_L	= $80
ORNAMENT_H	= $81
SAMPLE_L	= $82
SAMPLE_H	= $83
LOOP		= $84
MB_VALUE	= $85
MB_ADDR_L	= $86
MB_ADDR_H	= $87
DONE_PLAYING	= $88
DONE_SONG	= $89
PT3_TEMP	= $8A
ENV_SHAPE_TEMP	= $8B
C_COARSE_TEMP	= $8C
A_VOL_TEMP	= $8D

WASTE_CYCLES    = $C6
FOREVER_OFFSET  = $C7
FRAME_OFFSET    = $C8
FRAME_PAGE      = $C9
AY_WRITE_TEMP   = $CA
AY_WRITE_TEMP2  = $CB


HGR_COLOR	= $E4
DRAW_PAGE	= $EE
SNOWX		= $F0
COLOR		= $F1
CMASK1		= $F2
CMASK2		= $F3
WHICH_Y		= $F4
FRAME		= $F5
TEMPY		= $F6
TEMP		= $F7
SOUND_WHILE_DECODE =    $F8


HGR		= $F3E2

NUMFLAKES	= 10

TREESIZE	= 12

.include	"hardware.inc"


	;==================================
	;==================================
	; Init

	lda	#0
	sta	FRAME

	jsr	HGR

	bit	SET_TEXT
	bit	FULLGR
	bit	LORES
	bit	PAGE0


	;===========================
	; Check for Apple IIe
	;===========================
	; fonts are offset so patch to make scroll effect same on II+

	lda	$FBB3	; IIe and newer is $06
	cmp	#6
	bne	apple_ii_regular

	lda	#$54
	sta	tl_smc1+1
	lda	#$55
	sta	tl_smc2+1

apple_ii_regular:



	;=========================
        ; set up sound
        ;=========================
        lda	#0
        sta	DONE_PLAYING
        sta	FRAME_PLAY_OFFSET
        sta	FRAME_PLAY_PAGE
        sta	FRAME_OFFSET
        sta	FRAME_PAGE
        sta	SOUND_WHILE_DECODE
        jsr	update_pt3_play
        jsr	pt3_set_pages

	jsr	mockingboard_detect
	jsr	mockingboard_patch

	jsr	mockingboard_init
	jsr	reset_ay_both
	jsr	clear_ay_both
	jsr	pt3_init_song

        lda     #1
        sta     LOOP

	;====================================
	; generate 4 patterns worth of music
	; at address $7000-$9C00

	jsr     pt3_write_lc_4


	;==================================
	; init snow
	;==================================

	ldx	#NUMFLAKES-1
snow_init_loop:

	jsr	random16

	lda	SEEDL
	and	#$3f
	sta	snow_x,X

	lda	SEEDH
	and	#$7f
	sta	snow_y,X

	dex
	bpl	snow_init_loop

	lda     #<letters_bm
        sta     LETTERL
        lda     #>letters_bm
        sta     LETTERH
        lda     #39
        sta     LETTERX
        lda     #1
        sta     LETTERY
        lda     #15
        sta     LETTERD


	;=============================
	; Load graphic page0

	lda	#<message_low
	sta	GBASL
	lda	#>message_low
	sta	GBASH
	lda	#$c
	jsr	load_rle_gr

	;=============================
	; Load graphic page1

	lda	#<message_high
	sta	GBASL
	lda	#>message_high
	sta	GBASH
	lda	#$8
	jsr	load_rle_gr

	jmp	blah_align

.align	$100
blah_align:

	;==========================================================
	;==========================================================
	; Vapor Lock
	;==========================================================
	;==========================================================

	jsr	vapor_lock

	; vapor lock returns with us at beginning of hsync in line
	; 114 (7410 cycles), so with 5070 lines to go to vblank
	; then we want another 4550 cycles to end, so 9620

	;  9620
	; -9298
	;=======
	;  322

	jsr	gr_copy_to_current		; 6+ 9292

	;=================================
	; do nothing
	;=================================
	; and take 322 cycles to do it
do_nothing:
	; Try X=1 Y=29 cycles=320 R2

	nop

	ldy     #29							; 2
loop1:	ldx	#1							; 2
loop2:	dex								; 2
	bne	loop2							; 2nt/3
	dey								; 2
	bne	loop1							; 2nt/3




	;=============================================
	;=============================================
	;=============================================

display_loop:

	;==========================
	; First 8*4 = 32 lines GR??
	; 2080 cycles

	ldx	#15		; 2
top_loop:
	; even lines PAGE1
	bit	SET_TEXT	; 4
	bit	LORES		; 4
tl_smc1:
	bit	PAGE1		; 4
	; 65-12 = 53 - 25 - 2 = 26
	lda	#26		; 2
	jsr	delay_a		; 51

	; odd lines PAGE0
	bit	SET_TEXT	; 4
	bit	LORES		; 4
tl_smc2:
	bit	PAGE0		; 4
	; 65-12 = 53 - 25 - 2 -2 -3 =21
	lda	#21		; 2
	jsr	delay_a		; 46
	dex			; 2
	bpl	top_loop	; 3

				; -1

	;=====================================
	; Next 32*4 = 128 lines  HGR1/GR1 for 20 cycles/HGR1

	ldx	#127	; 2
middle_loop:


	bit	PAGE0			; 4
	bit	SET_GR			; 4
	bit	HIRES			; 4
					; 19

	nop
	lda	COLOR	; 3
	lda	COLOR	; 3
	lda	COLOR	; 3
	lda	COLOR	; 3


	bit	LORES			; 4
					; 16
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda	COLOR
	bit	HIRES			; 4
					; 5cycles
	nop
	;lda	COLOR
	nop

	lda	COLOR	; 3
	nop

	dex				; 2
	bpl	middle_loop		; 3
					; -1

	;==========================
	; Next 8*4 = 32 lines GR ??
	; 2080 cycles -8 -2 +1=2071

	; we have extraneous 1 (from us)
	; extraneous 1 (from above)

	ldx	#7			; 2
bottom_loop:
	; top two lines PAGE1
	bit	SET_GR			; 4
	bit	LORES			; 4
	bit	PAGE1			; 4
	; 65+65-12 = 118 - 25 - 2 = 91
	lda	#91			; 2
	jsr	delay_a			; 116

	; nottom two lines PAGE0
	bit	SET_GR			; 4
	bit	LORES			; 4
	bit	PAGE0			; 4
	; 65+65-12 = 118 - 25 - 2 -2 -3 =86
	lda	#86			; 2
	jsr	delay_a			; 111
	dex				; 2
	bpl	bottom_loop		; 3

					; -1

	jmp	vblank_start		; 3 (so total extra = 3+1+1+1=6)

.align	$100
vblank_start:


	;===========================
	; alternate between tree and snow/music
	; every other frame
	;===========================
				; 6 leftover from above

	lda	#1		; 2
	eor	FRAME		; 3
	sta	FRAME		; 3
	beq	tree_half	; 3
				;====
				; 17

				; -1
	jmp	music_snow	; 3
				;=====
				; 2

tree_half:
	;==========================================================
	;==========================================================
	; TREE at 30Hz
	;==========================================================
	;==========================================================



	;==========================================================
	; erase old lines
	;==========================================================
	; clear 10-30 on lines 8-38

	; 4+(80+5)*20-1 = 1703 cycles
clear_lores:

	lda	#$0						; 2
	ldx	#19						; 2
							;===========
							;	  4
clear_lores_loop:
	sta	$600+10,X	; 8				; 5
	sta	$680+10,X	; 10				; 5
	sta	$700+10,X	; 12				; 5
	sta	$780+10,X	; 14				; 5
	sta	$428+10,X	; 16				; 5
	sta	$4A8+10,X	; 18				; 5
	sta	$528+10,X	; 20				; 5
	sta	$5A8+10,X	; 22				; 5
	sta	$628+10,X	; 24				; 5
	sta	$6A8+10,X	; 26				; 5
	sta	$728+10,X	; 28				; 5
	sta	$7A8+10,X	; 30				; 5
	sta	$450+10,X	; 32				; 5
	sta	$4D0+10,X	; 34				; 5
	sta	$550+10,X	; 36				; 5
	sta	$5D0+10,X	; 38				; 5
							;===========
							;	80

	dex							; 2
	bpl	clear_lores_loop				; 3
							;===========
							;	  5
								; -1


	;============================================================
	;============================================================
	; move line
	;============================================================
	;============================================================

	inc	WHICH_Y					; 5
	lda	WHICH_Y					; 3
	and	#$7f					; 2
	sta	WHICH_Y					; 3
							;=====
							; 13

	jmp	draw_tree				; 3

.align $100

draw_tree:

	;==========================================================
	;==========================================================
	; draw new line
	;==========================================================
	;==========================================================
	;NEW: 2,4,6,8,10,12,14,16,18,2,2,2
	;
	; 2-1 + 7*TREESIZE + 85*TREESIZE +
	;			18*(2+4+6+8+10+12+14+16+18+2+1+1)
	;
	; 1 + 84 + 1020 + 18*94 = 1105 + 1692 = 2797


	ldx	#0					; 2
draw_line_loop:

	;=================================
	;=================================
	; draw line
	;=================================
	;=================================
	; X = which

	; optimized:	34 + 18 + 34 +      18*len + -1 = 85+(18*len)

draw_line:

	; set up proper sine table
	ldy	tree_line,X					; 4+
	lda	sine_table_l,Y					; 4+
	sta	sine_table_smc+1				; 4
	lda	sine_table_h,Y					; 4+
	sta	sine_table_smc+2				; 4

	ldy	WHICH_Y						; 3
sine_table_smc:
	lda	sine_table5,Y					; 4+
	lsr							; 2
	tay							; 2
	bcs	draw_line_odd					; 3
								;======
								; 34
draw_line_even:
								; -1
	lda	tree_color,X					; 4+
	and	#$0f						; 2
	sta	ll_smc1+1					; 4
	lda	#$f0						; 2
	sta	ll_smc2+1					; 4
	jmp	draw_line_actual				; 3
								;====
								; 18

draw_line_odd:
	lda	tree_color,X					; 4+
	and	#$f0						; 2
	sta	ll_smc1+1					; 4
	lda	#$0f						; 2
	sta	ll_smc2+1					; 4
	nop							; 2
								;====
								; 18

draw_line_actual:
	lda	gr_offsets_l,Y					; 4+
	clc							; 2
	adc	tree_start,X					; 4+
	sta	ll_smc3+1					; 4
	sta	ll_smc4+1					; 4

	lda	gr_offsets_h,Y					; 4+
	sta	ll_smc3+2					; 4
	sta	ll_smc4+2					; 4

	ldy	tree_len,X					; 4+
								;=====
								; 34

line_loop:
ll_smc3:
	lda	$400,Y						; 4+
ll_smc2:
	and	#$f0						; 2
ll_smc1:
	ora	#$0f						; 2
ll_smc4:
	sta	$400,Y						; 5
	dey							; 2
	bpl	line_loop					; 3
								;=====
								; 18

								; -1

	inx						; 2
	cpx	#TREESIZE				; 2
	bne	draw_line_loop				; 3


							; -1

	;==============================================================
	;==============================================================

	; 4550 cycles
	;  -17		alternate frame
	;-1703		erase lores
	;  -13		move tree
	;   -3		jmp (alignment)
	;-2797		draw tree
	;   -3		jmp at end
	;========
	;   14

	lda	COLOR	; 3
	lda	COLOR	; 3
	lda	COLOR	; 3
	lda	COLOR	; 3
	nop		; 2


	; Try X=2 Y=1 cycles=17

;	lda	COLOR

;	ldy     #1							; 2
;eloop1:	ldx	#2							; 2
;eloop2:	dex								; 2
;	bne	eloop2							; 2nt/3
;	dey								; 2
;	bne	eloop1							; 2nt/3

	jmp	display_loop				; 3









	;=======================================================
	;=======================================================
	;=======================================================
	; music/snow
	;=======================================================
	;=======================================================
	;=======================================================
	; Display falling snow
.align $100
music_snow:

	; do letters

	jsr	move_letters				; 6+126

	; play music
	jsr	play_frame_compressed			; 6+1237

;	lda	#107
;	jsr	delay_a

	lda	FRAME_PLAY_PAGE				; 3
	cmp	#8					; 2
	beq	wrap_play				; 3
						;===========
						;	  8

							; -1
	lda	#98					; 2
	jsr	delay_a					; 123
	jmp	no_problem				; 3
						;=============
						;	 127

wrap_play:
	lda	#0					; 2
	sta	FRAME_PLAY_OFFSET			; 3
	lda	#3					; 2
	sta	FRAME_PLAY_PAGE				; 3
	jsr	update_pt3_play				; 6+111
							;=======
							; 127

no_problem:


	; 0 4 8 c 10 14 18 1c
	; 0 1 2 3 4  5  6  7

	;=========================
	; erase old snow
	;=========================
	; 2 + (40+38+7)*NUMFLAKES - 1
	; 1 + 85*NUMFLAKES = 851

	ldx	#0					; 2
erase_loop:
	lda	snow_y,X	; get Y			; 4+
	lsr						; 2
	lsr						; 2
	lsr			; divide by 8		; 2
	sta	TEMPY					; 3
	lda	snow_x,X				; 4+
	tay						; 2
	lda	div_7_q,Y				; 4+

	ldy	TEMPY					; 3
	clc						; 2
	adc	hgr_offsets_l,Y				; 4+
	sta	GBASL					; 3
	adc	#30					; 2
	sta	BASL					; 3
						;=============
						;         40

	lda	snow_y,X				; 4+
	asl						; 2
	asl						; 2
	and	#$1f					; 2
	clc						; 2
	adc	hgr_offsets_h,Y				; 4
	sta	GBASH					; 3
	sta	BASH					; 3
	lda	#0					; 2
	tay						; 2
	sta	(GBASL),Y				; 6
	sta	(BASL),Y				; 6
						;============
						;        38

	inx						; 2
	cpx	#NUMFLAKES				; 2
	bne	erase_loop				; 3
						;============
						;	  7

							; -1

	;==========================
	; move snow
	;
	; 2 + NUM_FLAKES*(9+17+56+16+11+7) -1
	; 1 + NUM_FLAKES*116      = 1161

	ldx	#0					; 2
move_snow:
	; Check if off edge of screen

	lda	snow_y,X				; 4+
	cmp	#160					; 2
	beq	snow_new_y				; 3
						;==========
						;	  9
no_new_y:
							; -1
	lda	SEEDH					; 3
	lda	SEEDH					; 3
	lda	SEEDH					; 3
	lda	SEEDH					; 3
	lda	SEEDH					; 3
	jmp	just_inc				; 3
						;============
						;        17

snow_new_y:
	; out of bounds, get new
	lda	#32					; 2
	sta	snow_y,X				; 5
	lda	SEEDH					; 3
	and	#$3f					; 2
	sta	snow_x,X				; 5
						;============
						;	 17
just_inc:

	jsr	random16				; 6+42
	lda	SEEDL					; 3
	and	#$f					; 2
	beq	snow_left				; 3
						;===============
						;        56

; if left  = 7    = 7  + (9) = 16
; if right = 4+10 = 14 + (2) = 16
; else     = 4+9  = 13 + (3) = 16
							; -1
	cmp	#$1					; 2
	beq	snow_right				; 3
						;===============
						;         4

snow_else:
	lda	SEEDL	; nop				; 3
							; -1
	inc	snow_y,X				; 7
	jmp	snow_no					; 3
						;===============
						;         9+3

snow_right:
	nop						; 2
	inc	snow_x,X				; 7
	jmp	snow_no					; 3
						;============
						; 	10+2

snow_left:
	dec	snow_x,X				; 7
	lda	SEEDL		; nop
	lda	SEEDL		; nop
	lda	SEEDL		; nop




snow_no:
	lda	snow_x,X				; 4+
	and	#$3f					; 2
	sta	snow_x,X				; 5
							;====
							; 11

done_inc:
	inx						; 2
	cpx	#NUMFLAKES				; 2
	bne	move_snow				; 3
						;===========
						;	  7

							; -1

	;=========================
	; draw new snow
	;=========================
	; 2+ (40+22+28+7)*NUMFLAKES -1
	; 1+97*NUMFLAKES = 971

	ldx	#0					; 2
draw_loop:
	lda	snow_y,X				; 4+
	lsr						; 2
	lsr						; 2
	lsr						; 2
	sta	TEMPY					; 3
	lda	snow_x,X				; 4+
	tay						; 2
	lda	div_7_q,Y				; 4+
	ldy	TEMPY					; 3
	clc						; 2
	adc	hgr_offsets_l,Y				; 4+
	sta	GBASL					; 3
	adc	#30					; 2
	sta	BASL					; 3
						;===========
						;	 40

	lda	snow_y,X				; 4+
	asl						; 2
	asl						; 2
	and	#$1f					; 2
	clc						; 2
	adc	hgr_offsets_h,Y				; 4+
	sta	GBASH					; 3
	sta	BASH					; 3
						;=============
						;	 22

	ldy	snow_x,X				; 4+
	lda	div_7_r,Y				; 4+
	tay						; 2
	lda	pixel_lookup,Y				; 4+

	ldy	#0					; 2
	sta	(GBASL),Y				; 6
	sta	(BASL),Y				; 6
						;=============
						;	 28

	inx						; 2
	cpx	#NUMFLAKES				; 2
	bne	draw_loop				; 3
						;=============
						;	  7

							; -1

	; 4550 cycles
	;  -17 even/odd
	;   -2 even/odd jump
	; -851 erase
	;-1161 move
	; -971 draw
	;   -3 jump at end
	;-1243 music
	; -135 wrap
	; -132 letters
	;======
	;  35

	; Try X=2 Y=2 cycles=33R2

	nop

	ldy     #2							; 2
dloop1:	ldx	#2							; 2
dloop2:	dex								; 2
	bne	dloop2							; 2nt/3
	dey								; 2
	bne	dloop1							; 2nt/3

	jmp	display_loop			; 3




tree:
	;	color	start	stop		; 01234567890123456789
;	.byte	$DD,	19,	20,	$00	;          YY
;	.byte	$44,	17,	22,	$00	;         DDDD
;	.byte	$CC,	16,	23,	$00	;        LLLLLL
;	.byte	$44,	15,	24,	$00	;       DDDDDDDD
;	.byte	$CC,	14,	25,	$00	;      LLLLLRRLLL
;	.byte	$44,	13,	26,	$00	;     DDDDDDDDDDDD
;	.byte	$CC,	12,	27,	$00	;    LLLLLLLLLLLLLL
;	.byte	$44,	11,	28,	$00	;   DDDDRRDDDDDDDDDD
;	.byte	$CC,	10,	29,	$00	;  LLLLLLLLLLLLLLLLLL
;	.byte	$88,	19,	20,	$00	;          BB

.align $100
tree_color:	.byte	$DD,$44,$CC,$44, $CC,$11, $44, $CC, $44,$11, $CC, $88
tree_line:	.byte	  0,  1,  2,  3,   4,  4,   5,   6,   7,  7,   8,   9
tree_start:	.byte	 19, 18, 17, 16,  15, 20,  14,  13,  12, 16,  11,  19
tree_len:	.byte	2-1,4-1,6-1,8-1,10-1,1-1,12-1,14-1,16-1,1-1,18-1, 2-1

gr_offsets_l:
	.byte	<$400,<$480,<$500,<$580,<$600,<$680,<$700,<$780
	.byte	<$428,<$4a8,<$528,<$5a8,<$628,<$6a8,<$728,<$7a8
	.byte	<$450,<$4d0,<$550,<$5d0,<$650,<$6d0,<$750,<$7d0

gr_offsets_h:
	.byte	>$400,>$480,>$500,>$580,>$600,>$680,>$700,>$780
	.byte	>$428,>$4a8,>$528,>$5a8,>$628,>$6a8,>$728,>$7a8
	.byte	>$450,>$4d0,>$550,>$5d0,>$650,>$6d0,>$750,>$7d0

sine_table_l:
	.byte	<sine_table5, <sine_table6, <sine_table7, <sine_table8
	.byte	<sine_table9, <sine_table10,<sine_table11,<sine_table12
	.byte	<sine_table13,<sine_table14,<sine_table15

sine_table_h:
	.byte	>sine_table5, >sine_table6, >sine_table7, >sine_table8
	.byte	>sine_table9, >sine_table10,>sine_table11,>sine_table12
	.byte	>sine_table13,>sine_table14,>sine_table15


snow_x:
	.byte 0,0,0,0,0,0,0,0,0,0

snow_y:
	.byte 0,0,0,0,0,0,0,0,0,0

hgr_offsets_h:
.byte	>$2000,>$2080,>$2100,>$2180,>$2200,>$2280,>$2300,>$2380
.byte	>$2028,>$20A8,>$2128,>$21A8,>$2228,>$22A8,>$2328,>$23A8
.byte	>$2050,>$20D0,>$2150,>$21D0,>$2250,>$22D0,>$2350,>$23D0

hgr_offsets_l:
.byte	<$2000,<$2080,<$2100,<$2180,<$2200,<$2280,<$2300,<$2380
.byte	<$2028,<$20A8,<$2128,<$21A8,<$2228,<$22A8,<$2328,<$23A8
.byte	<$2050,<$20D0,<$2150,<$21D0,<$2250,<$22D0,<$2350,<$23D0


div_7_q:
	.byte 0,0,0,0,0,0,0		; 0..6
	.byte 1,1,1,1,1,1,1		; 7..13
	.byte 2,2,2,2,2,2,2		; 14..20
	.byte 3,3,3,3,3,3,3		; 21..27
	.byte 4,4,4,4,4,4,4		; 28..34
	.byte 5,5,5,5,5,5,5		; 35..41
	.byte 6,6,6,6,6,6,6		; 42..48
	.byte 7,7,7,7,7,7,7		; 49..55
	.byte 8,8,8,8,8,8,8		; 56..62
	.byte 9				; 63

.align	$100
div_7_r:
	.byte 0,1,2,3,4,5,6		; 0..6
	.byte 0,1,2,3,4,5,6		; 7..13
	.byte 0,1,2,3,4,5,6		; 14..20
	.byte 0,1,2,3,4,5,6		; 21..27
	.byte 0,1,2,3,4,5,6		; 28..34
	.byte 0,1,2,3,4,5,6		; 35..41
	.byte 0,1,2,3,4,5,6		; 42..48
	.byte 0,1,2,3,4,5,6		; 49..55
	.byte 0,1,2,3,4,5,6		; 56..62
	.byte 0				; 63

pixel_lookup:
	.byte $01,$02,$04,$08,$10,$20,$40


.align	$100
.include "sines.inc"
.include "vapor_lock.s"
.include "delay_a.s"
.include "random16.s"
.include "message.inc"

.include "gr_unrle.s"
.include "gr_copy.s"

; include music

; Music player
.include "pt3_lib_core.s"
.include "pt3_lib_init.s"
.include "pt3_lib_mockingboard_setup.s"
.align $100
.include "pt3_lib_play_frame.s"
.include "pt3_lib_write_frame.s"
.include "pt3_lib_write_lc.s"
.include "pt3_lib_mockingboard_detect.s"

.align $100
.include "move_letters.s"
.include "letters.s"

.align $100
PT3_LOC = song
song:
.incbin "./music/jingle_fast.pt3"
