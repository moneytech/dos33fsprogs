;===============================================
; level data for Arbor trees
;===============================================

locations:
	.word location0, location1

; ARBOR_INSIDE_ELEV1		-- arrival in elevator1
location0:
	.byte	$ff			; north exit
	.byte	$ff			; south exit
	.byte	$ff			; east exit
	.byte	ARBOR_INSIDE_ELEV1_OPEN	; west exit
	.byte	$ff		; north exit_dir
	.byte	$ff		; south exit_dir
	.byte	$ff		; east exit_dir
	.byte	DIRECTION_W	; west exit_dir
	.word	$0000				; north bg
	.word	$0000				; south bg
	.word	$0000				; east bg
	.word	inside_elevator1_closed_w_lzsa	; west bg
	.byte	BG_WEST
	.byte	$ff

; ARBOR_INSIDE_ELEV1_OPEN	-- arrival in elevator1, door open
location1:
	.byte	$ff			; north exit
	.byte	$ff			; south exit
	.byte	$ff			; east exit
	.byte	ARBOR_ARRIVAL_CLOSED	; west exit
	.byte	$ff		; north exit_dir
	.byte	$ff		; south exit_dir
	.byte	$ff		; east exit_dir
	.byte	DIRECTION_W	; west exit_dir
	.word	$0000				; north bg
	.word	$0000				; south bg
	.word	$0000				; east bg
	.word	inside_elevator1_open_w_lzsa	; west bg
	.byte	BG_WEST
	.byte	$ff

; ARBOR_ARRIVAL_CLOSED		-- just outside elevator, closed
location2:
	.byte	$ff			; north exit
	.byte	$ff			; south exit
	.byte	ARBOR_ARRIVAL_OPEN	; east exit
	.byte	$ff			; west exit
	.byte	$ff		; north exit_dir
	.byte	$ff		; south exit_dir
	.byte	DIRECTION_E	; east exit_dir
	.byte	DIRECTION_W	; west exit_dir
	.word	$0000			; north bg
	.word	$0000			; south bg
	.word	arrival_e_lzsa		; east bg
	.word	arrival_w_lzsa		; west bg
	.byte	BG_WEST|BG_EAST
	.byte	$ff

; ARBOR_ARRIVAL_OPEN		-- just outside elevator, open
location3:
	.byte	$ff			; north exit
	.byte	$ff			; south exit
	.byte	ARBOR_INSIDE_ELEV1_OPEN	; east exit
	.byte	$ff			; west exit
	.byte	$ff		; north exit_dir
	.byte	$ff		; south exit_dir
	.byte	DIRECTION_W	; east exit_dir
	.byte	DIRECTION_W	; west exit_dir
	.word	$0000			; north bg
	.word	$0000			; south bg
	.word	arrival_open_e_lzsa	; east bg
	.word	arrival_w_lzsa		; west bg
	.byte	BG_WEST|BG_EAST
	.byte	$ff

