;.include "zp.inc"

;===========
; CONSTANTS
;===========
CONST_SHIPX	EQU	15
CONST_TILE_W	EQU	64
CONST_TILE_H	EQU	64
CONST_MAP_MASK_X	EQU	(CONST_TILE_W - 1)
CONST_MAP_MASK_Y	EQU	(CONST_TILE_H - 1)
CONST_LOWRES_W	EQU	40
CONST_LOWRES_H	EQU	40
CONST_BETA_I	EQU	$ff
CONST_BETA_F	EQU	$80
CONST_SCALE_I	EQU	$14
CONST_SCALE_F	EQU	$00
CONST_LOWRES_HALF_I	EQU	$ec	; -(LOWRES_W/2)
CONST_LOWRES_HALF_F	EQU	$00

	; pre-programmed directions

checkerboard_flying_directions:
	.byte	$18,$00		; 24 frames, do nothing
	.byte	$10,'D'		; 16 frames, turn right
	.byte	$10,$00		; 16 frames, do nothing
	.byte	$f,'A'		; 15 frames, turn left
	.byte	$10,$00		; 16 frames, do nothing
	.byte	$1,'Z'		; start moving forward
	.byte	$20,$00		; 32 frames, do nothing
	.byte	$1,'Q'		; quit

island_flying_directions:
	.byte	$2,$00		; 2 frames, do nothing
	.byte	$1,'Z'		; start moving forward
	.byte	$10,$00		; 16 frames, do nothing
	.byte	$3,'D'		; 3 frames, turn right
	.byte	$1,'Z'		; move faster
	.byte	$8,$00		; 8 frames, do nothing
	.byte	$2,'D'		; 2 frames, turn left
	.byte	$8,$00		; 8 frames, do nothing
	.byte	$3,'A'		; 3 frames, turn left
	.byte	$1,'Z'		; speedup
	.byte	$8,$00		; 8 frames, do nothing
	.byte	$6,'S'		; 6 frames down
	.byte	$6,$00		; 6 frames do nothing
	.byte	$3,'A'		; 3 frames left
	.byte	$3,'D'		; 3 frames right
	.byte	$2,$00		; 2 frames nothing
	.byte	$1,'D'		; 1 frame right
	.byte	$2,$00		; 2 frames nothing
	.byte	$8,'D'		; 8 frame right
	.byte	$1,'Z'		; 8 frames up
	.byte	$6,'W'		; 2 speedup
	.byte	$a,$00		; 10 nothing
	.byte	$3,'S'		; 3 down
	.byte	$1,'Q'		; quit

	;=====================
	; Flying
	;=====================

mode7_flying:

	;================================
	; Clear screen and setup graphics
	;================================

	jsr	clear_screens		 ; clear top/bottom of page 0/1
	jsr     set_gr_page0

	;===============
	; Init Variables
	;===============
	lda	#20
	sta	SHIPY
	lda	#0
	sta	TURNING
	sta	ANGLE
	sta	SPACEX_I
	sta	SPACEY_I
	sta	CX_I
	sta	CX_F
	sta	CY_I
	sta	CY_F
	sta	DRAW_SPLASH
	sta	SPEED
	sta	SPLASH_COUNT
	sta	DISP_PAGE
	sta	KEY_COUNT
	sta	KEY_OFFSET
	sta	FRAME_COUNT

	lda	#2		; initialize sky both pages
	sta	DRAW_SKY

	lda	#4		; starts out at 4.5 altitude
	sta	SPACEZ_I
	lda	#$80
	sta	SPACEZ_F

	jsr	update_z_factor

flying_loop:

	lda	SPLASH_COUNT						; 3
	beq	flying_keyboard						; 2nt/3
	dec	SPLASH_COUNT	; decrement splash count		; 5

flying_keyboard:

;	jsr	get_key		; get keypress				; 6

	lda	KEY_COUNT
	bne	done_key

	ldy	KEY_OFFSET
direction_smc_1:
	lda	island_flying_directions,Y
	sta	KEY_COUNT
	iny
direction_smc_2:
	lda	island_flying_directions,Y
	sta	LASTKEY
	inc	KEY_OFFSET
	inc	KEY_OFFSET

done_key:
	dec	KEY_COUNT
	lda	LASTKEY							; 3

	cmp	#('Q')							; 2
	bne	check_up						; 3/2nt

	; done
	rts

check_up:
	cmp	#('W')							; 2
	bne	check_down						; 3/2nt

	;===========
	; UP PRESSED
	;===========

	lda	SHIPY
	cmp	#17
	bcc	check_down	; bgt, if shipy>16
	dec	SHIPY
	dec	SHIPY		; move ship up
	inc	SPACEZ_I	; incement height
	jsr	update_z_factor
	lda	#0
	sta	SPLASH_COUNT

check_down:
	cmp	#('S')
	bne	check_left

	;=============
	; DOWN PRESSED
	;=============

	lda	SHIPY
	cmp	#28
	bcs	splashy		; ble, if shipy < 28
	inc	SHIPY
	inc	SHIPY		; move ship down
	dec	SPACEZ_I	; decrement height
	jsr	update_z_factor
	bcc	check_left

splashy:
	lda	#10
	sta	SPLASH_COUNT

check_left:
	cmp	#('A')
	bne	check_right

	;=============
	; LEFT PRESSED
	;=============

	lda	TURNING
	bmi	turn_left
	beq	turn_left

	lda	#$0
	sta	TURNING
	clv
	bvc	check_right

turn_left:
	lda	#253	; -3
	sta	TURNING

	dec	ANGLE

	inc	DRAW_SKY
	inc	DRAW_SKY

check_right:
	cmp	#('D')
	bne	check_speedup

	;==============
	; RIGHT PRESSED
	;==============

	lda	TURNING		;; FIXME: optimize me
	bpl	turn_right
	lda	#0
	sta	TURNING
	clv
	bvc	check_speedup

turn_right:
	lda	#3
	sta	TURNING

	inc	ANGLE
	inc	DRAW_SKY
	inc	DRAW_SKY

check_speedup:
	cmp	#('Z')
	bne	check_speeddown

	;=========
	; SPEED UP
	;=========
	lda	#$8
	cmp	SPEED
	beq	check_speeddown
	inc	SPEED

check_speeddown:
	cmp	#('X')
	bne	check_brake

	;===========
	; SPEED DOWN
	;===========

	lda	SPEED
	beq	check_brake
	dec	SPEED

check_brake:
	cmp	#(' '+128)
	bne	check_land

	;============
	; BRAKE
	;============
	lda	#$0
	sta	SPEED

check_land:
	cmp	#13
	bne	check_help

check_help:
	cmp	#('H')
	bne	check_done

check_done:

	;================
	; Wrap the Angle
	;================
	; FIXME: only do this in right/left routine?
	lda	ANGLE							; 3
	and	#$f							; 2
	sta	ANGLE							; 3

	;================
	; Handle Movement
	;================

speed_move:
	ldx	SPEED							; 3
	beq	draw_background						; 2nt/3
								;=============
	lda	ANGLE	; dx.i=fixed_sin[(angle+4)&0xf].i; // cos()	; 3
	clc								; 2
	adc	#4							; 2
	and	#$f							; 2
	asl								; 2
	tay								; 2
	lda	fixed_sin_scale,Y					; 4
	sta	DX_I							; 3
	iny		; dx.f=fixed_sin[(angle+4)&0xf].f; // cos()	; 2
	lda	fixed_sin_scale,Y					; 4
	sta	DX_F							; 3

	lda	ANGLE	; dy.i=fixed_sin[angle&0xf].i; // sin()		; 3
	and	#$f							; 2
	asl								; 2
	tay								; 2
	lda	fixed_sin_scale,Y					; 4
	sta	DY_I							; 3
	iny		; dx.f=fixed_sin[angle&0xf].f; // sin()		; 2
	lda	fixed_sin_scale,Y					; 4
	sta	DY_F							; 3
								;============
								;	 54
speed_loop:

	clc			; fixed_add(&cx,&dx,&cx);		; 2
	lda	CX_F							; 3
	adc	DX_F							; 3
	sta	CX_F							; 3
	lda	CX_I							; 3
	adc	DX_I							; 3
	sta	CX_I							; 3

	clc			; fixed_add(&cy,&dy,&cy);		; 2
	lda	CY_F							; 3
	adc	DY_F							; 3
	sta	CY_F							; 3
	lda	CY_I							; 3
	adc	DY_I							; 3
	sta	CY_I							; 3

	dex								; 2
	bne	speed_loop						; 2nt/3
								;============
								;	45

	;====================
	; Draw the background
	;====================
draw_background:
	jsr	draw_background_mode7					; 6

	lda	DRAW_BLUE_SKY
	bne	draw_spaceship

	;========================================
	;========================================
	; DRAW SPHERE CODE
	;========================================
	;========================================
draw_sphere:

	; FIXME: optimize this mess

	; draw shadow first
	lda	FRAME_COUNT
	and	#$0f
	tax
	lda	gravity,X

	cmp	#$5
	bmi	high_shadow
low_shadow:
	lda     #>sphere_shadow1
        sta     INH
        lda     #<sphere_shadow1
        sta     INL
	jmp	done_shadow
high_shadow:
	lda     #>sphere_shadow2
        sta     INH
        lda     #<sphere_shadow2
        sta     INL
done_shadow:

	lda	#18							; 2
	sta	XPOS							; 3

	lda	#36							; 2
	sta	YPOS							; 3
	jsr	put_sprite


	; draw sphere


	lda     #>sphere0						; 2
        sta     INH							; 3
        lda     #<sphere0						; 2
        sta     INL							; 3

	lda	ANGLE
	lsr
	tax
	lda	sphere_offset,X

	clc
	adc	INL
	sta	INL
	lda	#0
	adc	INH
	sta	INH

	lda	#18							; 2
	sta	XPOS							; 3

	lda	FRAME_COUNT
	and	#$0f
	tax
	lda	gravity,X
	cmp	#10
	bne	no_click
	bit	SPEAKER
no_click:
	clc
	adc	#18							; 3
	sta	YPOS							; 3
	jsr	put_sprite						; 6

	jmp	done_draw_spaceship

done_draw_sphere:

	;========================================
	;========================================
	; DRAW SPACESHIP CODE
	;========================================
	;========================================
draw_spaceship:

check_over_water:
	;	See if we are over water
	lda	CX_I							; 3
	sta	SPACEX_I						; 3
	lda	CY_I							; 3
	sta	SPACEY_I						; 3

	jsr	lookup_island_map					; 6

	sec								; 2
	sbc	#COLOR_BOTH_DARKBLUE					; 2
	sta	OVER_LAND						; 3
								;===========
								;	31

	; Calculate whether to draw the splash

	lda	#0			; set splash drawing to 0	; 2
	sta	DRAW_SPLASH						; 3

	lda	SPEED			; if speed==0, no splash	; 3
	beq	no_splash						; 2nt/3

	lda	TURNING							; 3
	beq	no_turning_splash					; 2nt/3

	lda	SHIPY							; 3
	cmp	#27							; 2
	bcc	no_turning_splash	; blt if shipy<25 skip		; 2nt/3

	lda	#1							; 2
	sta	SPLASH_COUNT						; 3

no_turning_splash:
	lda	OVER_LAND	; no splash if over land		; 3
	bne	no_splash						; 2nt/3

	lda	SPLASH_COUNT	; no splash if splash_count expired	; 3
	beq	no_splash						; 2nt/3

	lda	#1							; 2
	sta	DRAW_SPLASH						; 3

no_splash:

	;==============
	; Draw the ship
	;==============

	clv								; 2
	lda	TURNING							; 3
	beq	draw_ship_forward					; 2nt/3
	bpl	draw_ship_right						; 2nt/3
	bmi	draw_ship_left		;; FIXME: optimize order	; 2nt/3

draw_ship_forward:
	lda	DRAW_SPLASH						; 2
	beq	no_forward_splash					; 2nt/3

	; Draw Splash
	lda     #>splash_forward					; 2
        sta     INH							; 3
        lda     #<splash_forward					; 2
        sta     INL							; 3
	lda	#(CONST_SHIPX+1)					; 2
	sta	XPOS							; 3
	clc								; 2
	lda	SHIPY							; 3
	adc	#9							; 2
	and	#$fe			; make sure it's even		; 2
	sta	YPOS							; 3
	jsr	put_sprite						; 6
								;==========
								;	33
no_forward_splash:
	; Draw Shadow
	lda     #>shadow_forward					; 2
        sta     INH							; 3
        lda     #<shadow_forward					; 2
        sta     INL							; 3
	lda	#(CONST_SHIPX+3)					; 2
	sta	XPOS							; 3
	clc								; 2
	lda	SPACEZ_I						; 3
	adc	#31							; 2
	and	#$fe			; make sure it's even		; 2
	sta	YPOS							; 3
	jsr	put_sprite						; 6

	lda     #>ship_forward						; 2
        sta     INH							; 3
        lda     #<ship_forward						; 2
        sta     INL							; 3
	bvc	draw_ship						; 3
								;===========
								;	46
draw_ship_right:
	lda	DRAW_SPLASH						; 3
	beq	no_right_splash						; 2nt/3

	; Draw Splash
	lda     #>splash_right						; 2
        sta     INH							; 3
        lda     #<splash_right						; 2
        sta     INL							; 3
	lda	#(CONST_SHIPX+1)					; 2
	sta	XPOS							; 3
	clc								; 2
	lda	#36							; 2
	sta	YPOS							; 3
	jsr	put_sprite						; 6
								;===========
								;	28
no_right_splash:

	; Draw Shadow
	lda     #>shadow_right						; 2
        sta     INH							; 3
        lda     #<shadow_right						; 2
        sta     INL							; 3
	lda	#(CONST_SHIPX+3)					; 2
	sta	XPOS							; 3
	clc								; 2
	lda	SPACEZ_I						; 3
	adc	#31							; 2
	and	#$fe			; make sure it's even		; 2
	sta	YPOS							; 3
	jsr	put_sprite						; 6

	lda     #>ship_right						; 2
        sta     INH							; 3
        lda     #<ship_right						; 2
        sta     INL							; 3

	dec	TURNING							; 5

	bvc	draw_ship						; 3
								;==========
								;	51
draw_ship_left:
	lda	DRAW_SPLASH						; 3
	beq	no_left_splash						; 2nt/3

	; Draw Splash
	lda     #>splash_left						; 2
        sta     INH							; 3
        lda     #<splash_left						; 2
        sta     INL							; 3
	lda	#(CONST_SHIPX+1)					; 2
	sta	XPOS							; 3
	clc								; 2
	lda	#36							; 2
	sta	YPOS							; 3
	jsr	put_sprite						; 6
								;===========
								;	 28
no_left_splash:

	; Draw Shadow
	lda     #>shadow_left						; 2
        sta     INH							; 3
        lda     #<shadow_left						; 2
        sta     INL							; 3
	lda	#(CONST_SHIPX+3)					; 2
	sta	XPOS							; 3
	clc								; 2
	lda	SPACEZ_I						; 3
	adc	#31							; 2
	and	#$fe			; make sure it's even		; 2
	sta	YPOS							; 3
	jsr	put_sprite						; 6

	lda     #>ship_left						; 2
        sta     INH							; 3
        lda     #<ship_left						; 2
        sta     INL							; 3

	inc	TURNING							; 5
								;==========
								;	 48

draw_ship:
	lda	#CONST_SHIPX						; 2
	sta	XPOS							; 3
	lda	SHIPY							; 3
	sta	YPOS							; 3
	jsr	put_sprite						; 6
								;===========
								;	17

done_draw_spaceship:


	;==================
	; flip pages
	;==================

	jsr	page_flip						; 6

	inc	FRAME_COUNT

	;==================
	; loop forever
	;==================

	jmp	flying_loop						; 3


update_z_factor:

	; we only do the following if Z changes

	; fixed_mul(&space_z,&BETA,&factor);
;mul1
	lda	SPACEZ_I						; 3
	sta	NUM1H							; 3

	; interlude, update SPACEZ_SHIFTED
	asl								; 2
	asl								; 2
	asl								; 2
	asl								; 2
	asl								; 2
	sec								; 2
	sbc	#8							; 2
	sta	spacez_shifted+1					; 4


	lda	SPACEZ_F						; 3
	sta	NUM1L							; 3

	lda	#CONST_BETA_I	; BETA_I				; 2
	sta	NUM2H							; 3
	lda	#CONST_BETA_F	; BETA_F				; 2
	sta	NUM2L							; 3

	sec			; don't reuse old values		; 2
	jsr	multiply						; 6

	stx	FACTOR_I						; 3
	sta	FACTOR_F						; 3

	rts								; 6
								;===========
								;        60


;===========================
; Draw the Mode7 Background
;===========================

draw_background_mode7:

	; Only draw sky if necessary
	; (at start, or if we have switched to text, we never overwrite it)

	lda	DRAW_SKY						; 3
	beq	no_draw_sky						;^2nt/3
								;==============
								;	  6

	dec	DRAW_SKY	; usually 2 as we redraw both pages	; 5


	lda	DRAW_BLUE_SKY
	bne	draw_blue_sky

draw_black_sky:
	sta	CV

	jsr	scroll_background
	jmp	no_draw_sky

draw_blue_sky:
	; Draw Sky
	; not performance critical as this happens rarely


	lda	#COLOR_BOTH_MEDIUMBLUE	; MEDIUMBLUE color		; 2
	sta	COLOR							; 3
	lda	#0							; 2
								;===========
								;	 11

sky_loop:				; draw line across screen
	ldy	#39			; from y=0 to y=6		; 2
	sty	V2							; 3
	ldy	#0							; 2
	pha								; 3
	jsr	hlin_double		; hlin y,V2 at A	; 63+(X*16)
	pla								; 4
	clc								; 2
	adc	#2							; 2
	cmp	#6							; 2
	bne	sky_loop						; 3/2nt
								;=============
								; (23+63+(X*16))*5
	; Draw Hazy Horizon

	lda	#COLOR_BOTH_GREY	; Horizon is Grey		; 2
	sta	COLOR							; 3
	lda	#6			; draw single line at 6/7	; 2
	ldy	#39							; 2
	sty	V2			; hlin	Y,V2 at A		; 3
	ldy	#0							; 2
	jsr	hlin_double		; hlin	0,40 at 6	; 63+(X*16)
								;===========
								; 63+(X*16)+14



no_draw_sky:

	; setup initial odd/even color mask
	lda	#$f0							; 2
	sta	COLOR_MASK						; 3

	; start Y at 8 (below horizon line)
	lda	#8							; 2
	sta	SCREEN_Y						; 3
								;=============
								;	 10

screeny_loop:
	and	#$fe		; be sure SCREEN_Y used later is even	; 2
	tay			; put in Y for lookup table later	; 2

	lda	COLOR_MASK	; flip mask for odd/even row plotting	; 3
	eor	#$ff							; 2
	sta	COLOR_MASK						; 3
	sta	mask_label+1	; setup self-modifying code		; 4

	eor	#$ff		; setup self-modifying branch later	; 2
	bmi	odd_branch	; beq is $f0 (too clever FIXME)		; 2nt/3
	lda	#$d0		; bne is $d0				; 2
odd_branch:
	sta	mask_branch_label	; actually update branch	; 4
								;============
								;	 27

setup_gr_addr:
	lda	gr_offsets,Y	; lookup low-res memory row address	; 4
	sta	GBASL		; store in GBASL zero-page pointer	; 3
	iny			; point to high part of address		; 2

	lda	gr_offsets,Y	; load high part of address		; 4
	clc			; clear carry for add			; 2
	adc	DRAW_PAGE       ; add in draw page offset               ; 3
	sta	GBASH		; store in GBASH zero-page pointer	; 3

								;=============
								;	 21

calc_horizontal_scale:

	; Calculate the horizontal scale using a lookup table

	; horizontal_scale.i *ALWAYS* = 0

	;	unsigned char horizontal_lookup[7][32];
	;horizontal_scale.f=
	;	horizontal_lookup[space_z.i&0xf][(screen_y-8)/2];
	;		horizontal_lookup[(space_z<<5)+(screen_y-8)]


	clc								; 2
	lda	SCREEN_Y						; 3
spacez_shifted:
	adc	#0	; self-modify, loads (spacez<<5)-8		; 2
	tay								; 2
	lda	horizontal_lookup,Y					; 4
	sta	NUM1L	; HORIZ_SCALE_F is input to next mul		; 3
								;============
								;	 16

; mul2
	; calculate the distance of the line we are drawing
	; fixed_mul(&horizontal_scale,&scale,&distance);
	lda	#0	; HORIZ_SCALE_I is always zero			; 2
	sta	NUM1H							; 3
	; NUM1L was set to HORIZ_SCALE_F previously			;
	lda	#CONST_SCALE_I	; SCALE_I				; 2
	sta	NUM2H							; 3
	lda	#CONST_SCALE_F	; SCALE_F				; 2
	sta	NUM2L							; 3
	sec			; don't reuse previous settings		; 2
	jsr	multiply						; 6
	stx	DISTANCE_I						; 2
	sta	DISTANCE_F						; 2
								;==========
								;	 27

	; calculate the dx and dy to add to points in space
	; we add to the starting values on each row to get the next
	; space values

	; dx.i=fixed_sin[(angle+8)&0xf].i	// -sin()
	lda	ANGLE							; 3
	clc								; 2
	adc	#8							; 2
	and	#$f							; 2
	asl								; 2
	tay								; 2
	lda	fixed_sin,Y	; load integer half			; 4
	sta	NUM2H		; use as source in upcomnig mul		; 3


	; dx.f=fixed_sin[(angle+8)&0xf].f; 	// -sin()
	iny			; point to float half			; 2
	lda	fixed_sin,Y	; load it from lookup table		; 4
	sta	NUM2L		; use as source in upcoming mul		; 3
								;==========
								;	 29

;mul3
	; fixed_mul(&dx,&horizontal_scale,&dx);

				; DX_I:DX_F already set in NUM2H:NUM2L
	clc			; reuse HORIZ_SCALE in NUM1		; 2
	jsr	multiply						; 6
	stx	DX_I							; 3
	sta	DX_F							; 3
								;==========
								;	 14

	; dy.i=fixed_sin[(angle+4)&0xf].i; // cos()

	lda	ANGLE							; 3
	clc								; 2
	adc	#4							; 2
	and	#$f							; 2
	asl								; 2
	tay								; 2
	lda	fixed_sin,Y	; load integer half			; 4
	sta	NUM2H		; use as source in upcoming mul		; 3

	; dy.f=fixed_sin[(angle+4)&0xf].f; // cos()

	iny			; point to float half			; 2
	lda	fixed_sin,Y	; load from lookup table		; 4
	sta	NUM2L		; use as source in upcoming mul		; 3
								;==========
								;	 29
;mul4
	; fixed_mul(&dy,&horizontal_scale,&dy);

				; DY_I:DY_F already in NUM2H:NUM2L
	clc			; reuse horiz_scale in num1		; 2
	jsr	multiply						; 6
	stx	DY_I							; 3
	sta	DY_F							; 3
								;==========
								;	 14

	;=================================
	; calculate the starting position
	;=================================

			; fixed_add(&distance,&factor,&space_x);
	clc		; fixed_add(&distance,&factor,&space_y);	; 2
	lda	DISTANCE_F						; 3
	adc	FACTOR_F						; 3
	sta	SPACEY_F						; 3
	sta	SPACEX_F						; 3

	lda	DISTANCE_I						; 3
	adc	FACTOR_I						; 3
	sta	SPACEY_I						; 3
	sta	SPACEX_I						; 3
								;==========
								;	 26


	; temp.i=fixed_sin[(angle+4)&0xf].i; // cos()

	lda	ANGLE							; 3
	clc								; 2
	adc	#4							; 2
	and	#$f							; 2
	asl								; 2
	tay								; 2
	lda	fixed_sin,Y						; 4
	sta	NUM2H	; store as source for next mul			; 3


	; temp.f=fixed_sin[(angle+4)&0xf].f; // cos()
	iny								; 2
	lda	fixed_sin,Y						; 4
	sta	NUM2L	; store as source for next mul			; 3
								;==========
								;	 29

; mul5
	; fixed_mul(&space_x,&temp,&space_x);
	lda	SPACEX_I						; 3
	sta	NUM1H							; 3
	lda	SPACEX_F						; 3
	sta	NUM1L							; 3
			; NUM2H:NUM2L already set above
	sec		; don't reuse previous NUM1			; 2
	jsr	multiply						; 6
			; SPACEX_I in X					;
			; SPACEX_F in A					;
								;==========
								;	 20

	; fixed_add(&space_x,&cx,&space_x);
	clc								; 2
			; SPACEX_F still in A				;
	adc	CX_F							; 3
	sta	SPACEX_F						; 3
	txa		; SPACEX_I was in X				; 2
	adc	CX_I							; 3
	sta	SPACEX_I						; 3
								;===========
								;	 16


	; temp.i=fixed_sin[angle&0xf].i; // sin()
	lda	ANGLE							; 3
	and	#$f							; 2
	asl								; 2
	tay								; 2
	lda	fixed_sin,Y						; 4
	sta	NUM2H		; store for next mul			; 3

	; fixed_temp.f=fixed_sin[angle&0xf].f; // sin()
	iny								; 2
	lda	fixed_sin,Y						; 4
	sta	NUM2L		; store for next mul			; 3
								;==========
								;	 25

;mul6
	; fixed_mul(&space_y,&fixed_temp,&space_y);
	lda	SPACEY_I						; 3
	sta	NUM1H							; 3
	lda	SPACEY_F						; 3
	sta	NUM1L							; 3
				; NUM2H:NUM2L already set
	sec			; don't reuse previous num1		; 2
	jsr	multiply						; 6
				; SPACEY_I in X				;
				; SPACEY_F in A				;
								;==========
								;	 20

	; fixed_add(&space_y,&cy,&space_y);
	clc								; 2
				; SPACEY_F in A
	adc	CY_F							; 3
	sta	SPACEY_F						; 3
	txa			; SPACEY_I in X				; 2
	adc	CY_I							; 3
	sta	SPACEY_I						; 3
								;==========
								;	 16
; mul7
	; fixed_mul(&lowres_half,&dx,&temp);
	lda	#CONST_LOWRES_HALF_I					; 2
	sta	NUM1H							; 3
	lda	#CONST_LOWRES_HALF_F					; 2
	sta	NUM1L							; 3
	lda	DX_I							; 3
	sta	NUM2H							; 3
	sta	dxi_label+1	; for self modify			; 4
	lda	DX_F							; 3
	sta	dxf_label+1	; for self modify			; 4
	sta	NUM2L							; 3
	sec			; don't reuse previous num1		; 2
	jsr	multiply						; 6
				; TEMP_I in X				;
				; TEMP_F in A				;
								;==========
								;	 38


	; fixed_add(&space_x,&temp,&space_x);
	clc								; 2
				; TEMP_F in A
	adc	SPACEX_F						; 3
	sta	SPACEX_F						; 3
	txa			; TEMP_I in X				; 2
	adc	SPACEX_I						; 3
	sta	SPACEX_I						; 3
								;==========
								;	 16

;mul8
	; fixed_mul(&fixed_temp,&dy,&fixed_temp);
	lda	DY_I							; 3
	sta	NUM2H							; 3
	sta	dyi_label+1	; for self modify			; 4
	lda	DY_F							; 3
	sta	NUM2L							; 3
	sta	dyf_label+1	; for self modify			; 4
	clc	; reuse CONST_LOWRES_HALF from last time		; 2
	jsr	multiply						; 6
			; TEMP_I in X
			; TEMP_F in A
								;==========
								;	 28

	; fixed_add(&space_y,&temp,&space_y);
	clc								; 2
			; TEMP_F in A
	adc	SPACEY_F						; 3
	sta	SPACEY_F						; 3

	txa		; TEMP_I in X					; 2
	adc	SPACEY_I						; 3
	sta	SPACEY_I						; 3

								;==========
								;	 16


	ldx	#40	; was SCREEN_X					; 2
								;==========
								;	  2
	;===================================================
	; SCREEN_X LOOP!!!!
	;   every cycle in here counts for 32*40=1280 cycles
	;===================================================
screenx_loop:


nomatch:
; This is self modified a few times
;	jsr	lookup_checkerboard_map
;	jmp	match
	; Get color to draw in A
	.include "island_lookup.s"

match:

mask_label:
	and	#0	; COLOR_MASK (self modifying)			; 2

	ldy	#0							; 2
mask_branch_label:
	beq	big_bottom	; this branch is modified based on odd/even
				; F0=beq, D0=bne			; 2nt/3

	ora	(GBASL),Y	; we're odd, or the bottom in		; 5
big_bottom:

	sta	(GBASL),Y	; plot double height pixel		; 6
	inc	GBASL		; point to next pixel			; 5
								;============
								;	22/18



	; advance to the next position in space

	; fixed_add(&space_x,&dx,&space_x);

	clc								; 2
	lda	SPACEX_F						; 3
dxf_label:
	adc	#0	; self modifying, is DX_F			; 2
	sta	SPACEX_F						; 3
	lda	SPACEX_I						; 3
dxi_label:
	adc	#0	; self modifying, is DX_I			; 2
	sta	SPACEX_I						; 3
								;==========
								;	 18

	; fixed_add(&space_y,&dy,&space_y);

	clc								; 2
	lda	SPACEY_F						; 3
dyf_label:
	adc	#0	; self modifyig, is DY_F			; 2
	sta	SPACEY_F						; 3
	lda	SPACEY_I						; 3
dyi_label:
	adc	#0	; self mofidying is DY_I			; 2
	sta	SPACEY_I						; 3
								;============
								;	 18

	dex	; decrement	SCREEN_X				; 2
	beq	done_screenx_loop	; branch until we've done 40	; 2nt/3
								;=============
								;	4/5


	; cache color and return if same as last time
	lda	SPACEY_I						; 3
spacey_label:
	cmp	#0	; self modify, LAST_SPACEY_I			; 2
	bne	nomatch							; 2nt/3
	lda	SPACEX_I						; 3
spacex_label:
	cmp	#0	; self modify, LAST_SPACEX_I			; 2
	bne	nomatch							; 2nt/3
map_color_label:
	lda	#0	; self modify, LAST_MAP_COLOR			; 2
	jmp	match							; 3

done_screenx_loop:
	inc	SCREEN_Y						; 5
	lda	SCREEN_Y						; 3
	cmp	#40			; LOWRES height			; 2
	beq	done_screeny						; 2nt/3
	jmp	screeny_loop		; too far to branch		; 3
								;=============
								;	 15
done_screeny:
	rts								; 6


	;====================
	; lookup_map
	;====================
	; finds value in space_x.i,space_y.i
	; returns color in A
	; CLOBBERS: A,Y
	; this is used to check if above water or grass
	; the high-performance per-pixel version has been inlined
lookup_island_map:
	.include "island_lookup.s"

	rts								; 6

lookup_checkerboard_map:
	.include "checkerboard_lookup.s"

	rts								; 6


;===============================================
; External modules
;===============================================

.include "gr_putsprite.s"
.include "bg_scroll.s"

.include "sprites.inc"

;===============================================
; Tables
;===============================================

.include "island_map.inc"
.include "starry_sky.scroll"

.include "multiply_fast.s"


; 8.8 fixed point
; should we store as two arrays, one I one F?
fixed_sin:
	.byte $00,$00 ;  0.000000=00.00
	.byte $00,$61 ;  0.382683=00.61
	.byte $00,$b5 ;  0.707107=00.b5
	.byte $00,$ec ;  0.923880=00.ec
	.byte $01,$00 ;  1.000000=01.00
	.byte $00,$ec ;  0.923880=00.ec
	.byte $00,$b5 ;  0.707107=00.b5
	.byte $00,$61 ;  0.382683=00.61
	.byte $00,$00 ;  0.000000=00.00
	.byte $ff,$9f ; -0.382683=ff.9f
	.byte $ff,$4b ; -0.707107=ff.4b
	.byte $ff,$14 ; -0.923880=ff.14
	.byte $ff,$00 ; -1.000000=ff.00
	.byte $ff,$14 ; -0.923880=ff.14
	.byte $ff,$4b ; -0.707107=ff.4b
	.byte $ff,$9f ; -0.382683=ff.9f

fixed_sin_scale:
	.byte $00,$00
	.byte $00,$0c
	.byte $00,$16
	.byte $00,$1d
	.byte $00,$20
	.byte $00,$1d
	.byte $00,$16
	.byte $00,$0c
	.byte $00,$00
	.byte $ff,$f4
	.byte $ff,$ea
	.byte $ff,$e3
	.byte $ff,$e0
	.byte $ff,$e3
	.byte $ff,$ea
	.byte $ff,$f4

	; we can guarantee 4 cycle indexed reads if we page-aligned this
.align 256
horizontal_lookup:
	.byte $0C,$0B,$0A,$09,$09,$08,$08,$07,$07,$06,$06,$06,$05,$05,$05,$05
	.byte $04,$04,$04,$04,$04,$04,$04,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.byte $26,$22,$20,$1D,$1B,$19,$18,$16,$15,$14,$13,$12,$11,$10,$10,$0F
	.byte $0E,$0E,$0D,$0D,$0C,$0C,$0C,$0B,$0B,$0A,$0A,$0A,$0A,$09,$09,$09
	.byte $40,$3A,$35,$31,$2D,$2A,$28,$25,$23,$21,$20,$1E,$1D,$1B,$1A,$19
	.byte $18,$17,$16,$16,$15,$14,$14,$13,$12,$12,$11,$11,$10,$10,$10,$0F
	.byte $59,$51,$4A,$44,$40,$3B,$38,$34,$31,$2F,$2C,$2A,$28,$26,$25,$23
	.byte $22,$21,$20,$1E,$1D,$1C,$1C,$1B,$1A,$19,$18,$18,$17,$16,$16,$15
	.byte $73,$68,$60,$58,$52,$4C,$48,$43,$40,$3C,$39,$36,$34,$32,$30,$2E
	.byte $2C,$2A,$29,$27,$26,$25,$24,$22,$21,$20,$20,$1F,$1E,$1D,$1C,$1C
	.byte $8C,$80,$75,$6C,$64,$5D,$58,$52,$4E,$4A,$46,$43,$40,$3D,$3A,$38
	.byte $36,$34,$32,$30,$2E,$2D,$2C,$2A,$29,$28,$27,$26,$25,$24,$23,$22
	.byte $A6,$97,$8A,$80,$76,$6E,$68,$61,$5C,$57,$53,$4F,$4B,$48,$45,$42
	.byte $40,$3D,$3B,$39,$37,$35,$34,$32,$30,$2F,$2E,$2C,$2B,$2A,$29,$28

gravity:
; 10fps
;	.byte 10,10,10,10,10, 8, 8, 8, 8, 6, 6, 4, 4, 2, 2, 0
;	.byte  0, 2, 2, 4, 4, 6, 6, 8, 8, 8, 8,10,10,10,10,10

; 5fps
;	.byte 10,10, 8, 8, 6, 4, 2, 0
;	.byte  0, 2, 4, 6, 8, 8, 10,10

	.byte 10, 8, 8, 6, 6, 4, 2, 0
	.byte  0, 2, 4, 6, 6, 8, 8,10
