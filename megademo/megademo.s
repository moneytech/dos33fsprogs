; Apple II Megademo

; by deater (Vince Weaver) <vince@deater.net>

.include "zp.inc"
.include "hardware.inc"


	;===================
	; Check for Apple II and patch
	;===================

	lda	$FBB3		; IIe and newer is $06
	cmp	#6
	beq	apple_iie

	lda	#$54		; patch the check_email font code
	sta	ce_patch+1


apple_iie:

	;===================
	; set graphics mode
	;===================
	jsr	HOME

	jsr	check_email

	; C64 Opening Sequence

	jsr	c64_opener

	; Falling Apple II

	jsr	falling_apple

	; Starring Screens

	; E-mail arriving
	jsr	check_email


	; Leaving house

	; Riding bird
	jsr	bird_mountain

	; Waterfall

	; Enter ship

	; mode7 (???)

	; Fly in space

	; Arrive

	; Fireworks

	jsr	fireworks

	; Game over
game_over_man:
	jmp	game_over_man

	;===================
	; Loop Forever
	;===================
loop_forever:
	jmp	loop_forever


	.include	"lz4_decode.s"
	.include	"c64_opener.s"
	.include	"falling_apple.s"
	.include	"check_email.s"
.align $100
	.include	"gr_offsets.s"
	.include	"gr_hline.s"
	.include	"vapor_lock.s"
	.include	"delay_a.s"
	.include	"wait_keypress.s"
	.include	"random16.s"
.align $100
	.include	"fireworks.s"
	.include	"hgr.s"
	.include	"bird_mountain.s"
	.include	"move_letters.s"
.align $100
	.include	"gr_putsprite.s"
