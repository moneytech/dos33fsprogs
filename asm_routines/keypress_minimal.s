	;==========================================================
	; Get Key
	;==========================================================
	;

get_key:

	lda	KEYPRESS						; 3
	bpl	no_key							; 2nt/3

figure_out_key:
	cmp	#' '+128		; the mask destroys space	; 2
	beq	save_key		; so handle it specially	; 2nt/3

	and	#$5f			; mask, to make upper-case	; 2
check_right_arrow:
	cmp	#$15							; 2
	bne	check_left_arrow					; 2nt/3
	lda	#'D'							; 2
check_left_arrow:
	cmp	#$08							; 2
	bne	check_up_arrow						; 2nt/3
	lda	#'A'							; 2
check_up_arrow:
	cmp	#$0B							; 2
	bne	check_down_arrow					; 2nt/3
	lda	#'W'							; 2
check_down_arrow:
	cmp	#$0A							; 2
	bne	check_escape						; 2nt/3
	lda	#'S'							; 2
check_escape:
        cmp	#$1B							; 2
	bne	save_key						; 2nt/3
	lda	#'Q'							; 2
	jmp	save_key						; 3

no_key:
	lda	#0			; no key, so save a zero	; 2

save_key:
	sta	LASTKEY			; save the key to our buffer	; 2
	bit	KEYRESET		; clear the keyboard buffer	; 4
	rts								; 6
								;============



