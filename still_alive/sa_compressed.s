; Still Alive Decompression Util

.include "zp.inc"

UNPACK_ENDING	EQU	$1800
UNPACK_ALIVE	EQU	$0800

start:
	;==============================
	; Unpack the Ending routine from $1800-$4000
	;==============================

unpack_ending:
	lda	#<ending
	sta	LZ4_SRC
	lda	#>ending
	sta	LZ4_SRC+1

	lda	#<ending_end
	sta	LZ4_END
	lda	#>ending_end
	sta	LZ4_END+1

	lda	#<UNPACK_ENDING
	sta	LZ4_DST
	lda	#>UNPACK_ENDING		; original unpacked data offset
	sta	LZ4_DST+1



	jsr	lz4_decode

	;==============================
	; Run the ending routine
	;==============================

	jsr	$1800

	;=====================================
	; Unpack the main code from $800-$367d
	;=====================================

	lda	#<still_alive
	sta	LZ4_SRC
	lda	#>still_alive
	sta	LZ4_SRC+1

	lda	#<still_alive_end
	sta	LZ4_END
	lda	#>still_alive_end
	sta	LZ4_END+1

	lda	#<UNPACK_ALIVE
	sta	LZ4_DST
	lda	#>UNPACK_ALIVE		; original unpacked data offset
	sta	LZ4_DST+1

	jsr	lz4_decode

	;=====================================
	; Unpack the music right after previous
	;=====================================

	lda	USEMB
	beq	load_ed_music

	;=====================================
	; MB SA.KR4 from 367D to 58ff
	;=====================================

load_mb_music:
	lda	#<music_mb
	sta	LZ4_SRC
	lda	#>music_mb
	sta	LZ4_SRC+1

	lda	#<music_mb_end
	sta	LZ4_END
	lda	#>music_mb_end
	sta	LZ4_END+1

	jmp	decode_music

	;=====================================
	; ED SA.ED from 367D to ????
	;=====================================

load_ed_music:
	lda	#<music_ed
	sta	LZ4_SRC
	lda	#>music_ed
	sta	LZ4_SRC+1

	lda	#<music_ed_end
	sta	LZ4_END
	lda	#>music_ed_end
	sta	LZ4_END+1

decode_music:

	; LZ4_DST should already be set to where STILL_ALIVE finished

	jsr	lz4_decode

	;==============================
	; Run still alive
	;==============================

	jmp	$800




; LZ4 data decompressor for Apple II

; Code by Peter Ferrie (qkumba) (peter.ferrie@gmail.com)
; "LZ4 unpacker in 143 bytes (6502 version) (2013)"
;    http://pferrie.host22.com/misc/appleii.htm
; This is that code, but with comments and labels added for clarity.
; I also found a bug when decoding with runs of multiples of 256
;   which has since been fixed upstream.

; For LZ4 reference see
; https://github.com/lz4/lz4/wiki/lz4_Frame_format.md

; LZ4 summary:
;
; HEADER:
;       Should: check for magic number 04 22 4d 18
;	FLG: 64 in our case (01=version, block.index=1, block.checksum=0
;		size=0, checksum=1, reserved
;	MAX Blocksize: 40 (64kB)
;	HEADER CHECKSUM: a7
;	BLOCK HEADER: 4 bytes (le)  If highest bit set, uncompressed!
; BLOCKS:
;	Token byte.  High 4-bits literal length, low 4-bits copy length
;	+ If literal length==15, then following byte gets added to length
;	  If that byte was 255, then keep adding bytes until not 255
;       + The literal bytes follow.  There may be zero of them
;	+ Next is block copy info.  little-endian 2-byte offset to
;	  be subtracted from current read position indicating source
;	+ The low 4-bits of the token are the copy length, which needs
;         4 added to it.  As with the literal length, if it is 15 then
;	  you read a byte and add (and if that byte is 255, keep adding)


	;======================
	; LZ4 decode
	;======================
	; input buffer in LZ4_SRC
        ; output buffer in LZ4_DST
	; end in LZ4_END

lz4_decode:

unpmain:
	ldy	#0			; used to index, always zero

parsetoken:
	jsr	getsrc			; get next token
	pha				; save for later (need bottom 4 bits)

	lsr				; number of literals in top 4 bits
	lsr				; so shift into place
	lsr
	lsr
	beq	copymatches		; if zero, then no literals
					; jump ahead and copy

	jsr	buildcount		; add up all the literal sizes
					; result is in ram[count+1]-1:A
	tax				; now in ram[count+1]-1:X
	jsr	docopy			; copy the literals

	lda	LZ4_SRC			; 16-bit compare
	cmp	LZ4_END			; to see if we have reached the end
	lda	LZ4_SRC+1
	sbc	LZ4_END+1
	bcs	done

copymatches:
	jsr	getsrc			; get 16-bit delta value
	sta	DELTA
	jsr	getsrc
	sta	DELTA+1

	pla				; restore token
	and	#$0f			; get bottom 4 bits
					; match count.  0 means 4
					; 15 means 19+, must be calculated

	jsr	buildcount		; add up count bits, in ram[count+1]-:A

	clc
	adc	#4			; adjust count by 4 (minmatch)

	tax				; now in ramp[count+1]-1:X

	beq	copy_no_adjust		; BUGFIX, don't increment if
					;	exactly a multiple of 0x100
	bcc	copy_no_adjust

	inc	COUNT+1			; increment if we overflowed
copy_no_adjust:

	lda	LZ4_SRC+1		; save src on stack
	pha
	lda	LZ4_SRC
	pha

	sec				; subtract delta
	lda	LZ4_DST			; from destination, make new src
	sbc	DELTA
	sta	LZ4_SRC
	lda	LZ4_DST+1
	sbc	DELTA+1
	sta	LZ4_SRC+1

	jsr	docopy			; do the copy

	pla				; restore the src
	sta	LZ4_SRC
	pla
	sta	LZ4_SRC+1

	jmp	parsetoken		; back to parsing tokens

done:
	pla

	rts



	;=========
	; getsrc
	;=========
	; gets byte from src into A, increments pointer
getsrc:
	lda	(LZ4_SRC), Y		; get a byte from src
	inc	LZ4_SRC			; increment pointer
	bne	done_getsrc		; update 16-bit pointer
	inc	LZ4_SRC+1		; on 8-bit overflow
done_getsrc:
	rts

	;============
	; buildcount
	;============
buildcount:
	ldx	#1			; high count starts at 1
	stx	COUNT+1			; (loops at zero?)
	cmp	#$0f			; if LITERAL_COUNT < 15, we are done
	bne	done_buildcount
buildcount_loop:
	sta	COUNT			; save LITERAL_COUNT (15)
	jsr	getsrc			; get the next byte
	tax				; put in X
	clc
	adc	COUNT			; add new byte to old value
	bcc	bc_8bit_oflow		; if overflow, increment high byte
	inc	COUNT+1
bc_8bit_oflow:
	inx				; check if read value was 255
	beq	buildcount_loop		; if it was, keep looping and adding
done_buildcount:
	rts

	;============
	; getput
	;============
	; gets a byte, then puts the byte
getput:
	jsr	getsrc
	; fallthrough to putdst

	;=============
	; putdst
	;=============
	; store A into destination
putdst:
	sta 	(LZ4_DST), Y		; store A into destination
	inc	LZ4_DST			; increment 16-bit pointer
	bne	putdst_end		; if overflow, increment top byte
	inc	LZ4_DST+1
putdst_end:
	rts

	;=============================
	; docopy
	;=============================
	; copies ram[count+1]-1:X bytes
	; from src to dst
docopy:

docopy_loop:
	jsr	getput			; get/put byte
	dex				; decrement count
	bne	docopy_loop		; if not zero, loop
	dec	COUNT+1			; if zero, decrement high byte
	bne	docopy_loop		; if not zero, loop

	rts


;===============================================
; External modules
;===============================================

; Note, the endings have all been truncated by 8 bytes with truncate
; to skip the checksums at the end

; Load, skipping 11 bytes of header
ending:
.incbin	"ENDING.lz4",11
ending_end:

still_alive:
.incbin	"STILL_ALIVE.lz4",11
still_alive_end:

music_mb:
.incbin	"SA.KR4.lz4",11
music_mb_end:

music_ed:
.incbin	"SA.ED.lz4",11
music_ed_end:


