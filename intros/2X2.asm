; 2X2 - 1 KB intro for Sinclair ZX Spectrum 128K (released at Forever 2017 demo party in Slovakia)
; (c) 2017 Milos Bazelides a.k.a. baze/3SC

; The intro showcases a 2D particle system rendered in basic but fast 2x2 dithering "graphics mode".
; Thanks to Pavel "Zilog" Cimbal for valuable input during our traditional brain storming sessions.
; Dedicated to the memory of my late grand father whose birthday regularly interfered with the party date :)
; Respect to party organizers who keep doing a great job for unbelievable 17 years in a row.

SCR_W	equ	32			; Screen width (in videoram bytes).
SCR_H	equ	64			; Screen height (in frame buffer pixels).
P_OFFST	equ	220			; Offset to particle data (implicitly determines the number of particles).

BANK_D0	equ	#50			; Non-contended memory banks used for dithering.
BANK_D1	equ	#54

BANK_I0	equ	#51			; Contended memory banks used for image processing.
BANK_I1	equ	#53			; (Intro should run OK also on Amstrad +2A/+3 machines without any changes though.)
BANK_I2	equ	#57

Nibbles	equ	#7E00
PrtData	equ	#7B00

MACRO	RESET_POSITIONS

	ld	hl,PrtData + P_OFFST	; Copy-pasted blocks of code can be suboptimal but they compress well.
	ld	a,157
_PrtRst	ld	(hl),a
	xor	157 xor 68
	inc	l
	jr	nz,_PrtRst
ENDM
	; So here we go...

	org	25620

	di

	; Initialize AY.

	ld	hl,AyRegs
	ld	d,c			; We assume zero after unpacker has finished its job.
AyInit	call	AyOut
	bit	4,d
	jr	z,AyInit

	; Generate lookup table used for conversion of signed 4.4 fixed point values to 8.8 fixed point.

	ld	hl,Nibbles + 256
NiblGen	dec	h
	ld	a,l
	rla
	sbc	a,a
	ld	d,a
	ld	e,l
	ex	de,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	ex	de,hl
	ld	(hl),e
	inc	h
	ld	(hl),d
	inc	l
	jr	nz,NiblGen

	; Initialize frame buffer.

	inc	h
	ld	a,%01000000
PixInit	ld	(hl),a
	xor	%10000000
	inc	hl
	bit	6,h
	jr	z,PixInit

	; Generate plain pixel copy lookup table.

	ld	a,BANK_I2
	out	(#FD),a

CopyGen	ld	(hl),l
	inc	hl
	ld	a,h
	or	l
	jr	nz,CopyGen

	; Generate fade out and color cycle lookup tables.

	ld	b,2
	ld	a,BANK_I0

PixLoop	out	(#FD),a
	ld	h,#C0
PixGen	ld	a,l
	and	%111
	jr	z,PixGen1
	dec	a
PixJr1	jr	PixGen1
	ld	a,%110
PixGen1	ld	e,a
	ld	a,l
	and	%111000
	jr	z,PixGen2
	sub	%1000
PixJr2	jr	PixGen2
	ld	a,%110000
PixGen2	or	e
	xor	l
	and	%00111111
	xor	l
	ld	(hl),a
	inc	hl
	ld	a,h
	or	l
	jr	nz,PixGen

	ld	a,#20			; Opcode of JR NZ.
	ld	(PixJr1),a
	ld	(PixJr2),a
	ld	a,BANK_I1

	djnz	PixLoop

	; Initialize particle system.

PrtInit	ld	h,PrtData / 256 + 1
	ld	(hl),b
	inc	h
	ld	(hl),b
	inc	l
	jr	nz,PrtInit

	; Clear screen.

	xor	a
	out	(#FE),a

	ld	h,#58
	ld	de,#5801
	ld	c,#80
	ld	(hl),b
	ldir
	ld	b,2
	ld	(hl),%01001101
	ldir
	ld	c,127
	ld	(hl),b
	ldir

	; Generate addresses of videoram and frame buffer scanlines.

	ld	de,#4080
	ld	h,e
	ld	b,d
AddrGen	ld	l,c
	ld	(hl),e
	inc	l
	ld	(hl),d
	ld	l,#42
	ld	(hl),c
	inc	l
	ld	(hl),h
	inc	(hl)
	ld	a,d
	inc	d
	inc	d
	xor	d
	and	%11111000
	jr	z,DownDE
	ld	a,e
	add	a,32
	ld	e,a
	jr	c,DownDE
	ld	a,d
	sub	8
	ld	d,a
DownDE	inc	h
	djnz	AddrGen

	; Generate background texture using formula (((x + y) ^ (x - y)) >> 4) % 7.

	ld	h,#80
	ld	b,-32
TexHi	ld	l,#80
TexLo	call	TexPix
	ld	d,a
	call	TexPix
	add	a,a
	add	a,a
	add	a,a
	or	d
	or	(hl)
	ld	(hl),a
	inc	l
	jr	nz,TexLo
	inc	b
	inc	h
	bit	6,h
	jr	z,TexHi

	; Generate raster lookup tables used for dithering.

	ld	d,Raster0 / 256

	ld	h,#C0
	call	SwpBank
RasGen1	ld	a,h
	call	RastMix
	ld	a,(de)
	ld	c,a
	ld	a,l
	call	RastMix
	ld	a,(de)
	xor	c
	and	%11110000
	xor	c
	ld	(hl),a
	inc	hl
	ld	a,h
	or	l
	jr	nz,RasGen1

	ld	a,Raster1 % 256
	ld	(RastOff + 1),a

	ld	h,#C0
	call	SwpBank
RasGen2	ld	a,h
	call	RastMix
	ld	a,(de)
	ld	c,a
	ld	a,l
	call	RastMix
	ld	a,(de)
	xor	c
	and	%11110000
	xor	c
	ld	(hl),a
	inc	hl
	ld	a,h
	or	l
	jr	nz,RasGen2

	RESET_POSITIONS

	; Effect 1: Fade-out on moving particles.

Effect1	ld	a,BANK_I0
	out	(#FD),a

	call	FrmCnt
	sub	2
	jr	nc,Eff1End

	xor	a
	call	ImgDef

	call	UpdtDef
	jr	Effect1

Eff1End	ld	hl,AyAC
	ld	d,7
	call	AyOut

	; Effect 2: Fade-out interlaced with vertical background scroll.

Effect2	ld	a,BANK_I2
	out	(#FD),a

	call	FrmCnt
	sub	4
	jr	nc,Eff2End

	ld	a,l
	rra
	jr	c,Eff2Odd

	ld	a,BANK_I0
	out	(#FD),a

	ld	a,2			; packable?
	call	ImgDef

	call	UpdtDef
	jr	Effect2

Eff2Odd	ld	a,l
	and	31
	rla
	ld	ixl,128
	call	ImgProc

	call	UpdtDef
	jr	Effect2

Eff2End	ld	hl,AyABC
	ld	d,7
	call	AyOut

	; Effect 3: Horizontal and diagonal background scroll.

Effect3	ld	a,BANK_I2
	out	(#FD),a

	call	FrmCnt
	sub	6
	jr	nc,Eff3End

	inc	a
	jr	nz,Eff3Atr

	ld	a,BANK_I1
	out	(#FD),a

	ld	bc,#5656
	ld	(Color + 1),bc

Eff3Atr	ld	a,l
	and	%10011111
	or	%01000000
	rla
	ld	ixl,a

	sbc	a,a
	and	l
	and	31
	rla

	call	ImgProc

	ld	bc,#0804
	call	Update
	jr	Effect3

Eff3End	ld	hl,#5757
	ld	(Color + 1),hl

	RESET_POSITIONS

	; Effect 4: Color cycle on sprites and background.

Effect4	ld	a,BANK_I1
	out	(#FD),a

	call	FrmCnt
	sub	6
	jr	nz,Eff4End

	xor	a			; Redundant but compresses better.
	call	ImgDef

	call	UpdtDef
	jr	Effect4

Eff4End	ld	a,Pattrn1 % 256
	ld	(PattAdr + 1),a

	ld	hl,#4E4F
	ld	(Color + 1),hl

	RESET_POSITIONS

	; Effect 5: Feedback scroll.

Effect5	ld	a,BANK_I0
	out	(#FD),a

	call	FrmCnt
	sub	9
	jr	nc,Eff5End

	inc	a
	jr	nz,Eff5Atr

	ld	hl,#4E4D
	ld	(Color + 1),hl

Eff5Atr	and	8
	add	a,7
	call	ImgDef

	call	UpdtDef
	jr	Effect5

Eff5End	ld	hl,#5756
	ld	(Color + 1),hl

	RESET_POSITIONS

	; Effect 6: Feedback scroll with periodical background refresh.

Effect6	ld	a,BANK_I2
	out	(#FD),a

	call	FrmCnt
	sub	9
	jr	nz,Basic

	ld	a,l
	dec	a
	and	15
	jr	nz,Eff6Scr

	ld	ixl,128
	call	ImgProc

	call	UpdtDef
	jr	Effect6

Eff6Scr	ld	a,191
	cp	l
;	ld	d,7
	jr	nc,Eff6Mix

	ld	hl,AyBC
	ld	d,7
	call	AyOut

Eff6Mix	sbc	a,a
	and	BANK_I1 - BANK_I0
	add	a,BANK_I0
	out	(#FD),a

;	ld	a,d
	ld	a,7
	call	ImgDef

	ld	bc,#0804
	call	Update
	jr	Effect6

	; Mute sound and exit to BASIC.

Basic	ld	hl,AyRegs
	ld	d,13
	call	AyOut
	ei

	; Frame counter used to synchronize effects and to determine even/odd scanline fields.

FrmCnt	ld	hl,#FFFF
	inc	hl
	ld	(FrmCnt + 1),hl
	ld	a,l
	and	1
	or	#7E
	ld	(ImgProc + 1),a
	ld	a,h
	ret

	; Intensities 0..7 map to one of five possible 2x2 rasters using 01122334 mapping obtained as y = (x + 1) >> 1.

RastMix	push	af
	and	7
	inc	a
	rra
	ld	e,a
	add	a,a
	add	a,a
	add	a,e
	ld	e,a
	pop	af
	rra
	rra
	rra
	and	7
	inc	a
	rra
	add	a,e
RastOff	add	a,Raster0 % 256
	ld	e,a
	ret

	; Texture generator.

TexPix	ld	a,c
	add	a,b
	ld	e,a
	ld	a,c
	sub	b
	xor	e
	rra
	rra
	rra
	rra
	and	15
	inc	c
TexMod	cp	7
	ret	c
	sub	7
	jr	TexMod

	; ZX Spectrum 128K memory paging.

SwpBank	ld	a,BANK_D1
	xor	BANK_D0 xor BANK_D1
	ld	(SwpBank + 1),a
	out	(#FD),a
	ret

	; Raster definitons. Data must reside inside a single aligned 256 byte memory bank.

Raster0	db	%00000000
	db	%00000000
	db	%00010001
	db	%00010001
	db	%00110011
	db	%10001000
	db	%10001000
	db	%10011001
	db	%10011001
	db	%10111011
	db	%10001000
	db	%10001000
	db	%10011001
	db	%10011001
	db	%10111011
	db	%11001100
	db	%11001100
	db	%11011101
	db	%11011101
	db	%11111111
	db	%11001100
	db	%11001100
	db	%11011101
	db	%11011101
	db	%11111111

Raster1	db	%00000000
	db	%00100010
	db	%00100010
	db	%00110011
	db	%00110011
	db	%00000000
	db	%00100010
	db	%00100010
	db	%00110011
	db	%00110011
	db	%01000100
	db	%01100110
	db	%01100110
	db	%01110111
	db	%01110111
	db	%01000100
	db	%01100110
	db	%01100110
	db	%01110111
	db	%01110111
	db	%11001100
	db	%11101110
	db	%11101110
	db	%11111111
	db	%11111111

	; Per frame update - random particle acceleration, sprites, music and dithering.

	; BC - Acceleration scale and bias.
	; L - Particle data offset.

UpdtDef	ld	bc,#0402
Update	ld	l,P_OFFST
UpdLoop	push	hl

	; Simple 16-bit Galois linear-feedback shift register (reversed) with 65535 possible states.

Random	ld	hl,#2017
	add	hl,hl
	ld	a,l
	jr	nc,RndSkip
	xor	%00101101
	ld	l,a
RndSkip	ld	(Random + 1),hl

	pop	hl
	and	b
	sub	c

	; A - Signed 4.4 fixed point value representing acceleration in the respective axis.

	ld	h,PrtData / 256 + 2
	add	a,(hl)
	ld	(hl),a
	dec	h
	ld	e,a
	ld	d,Nibbles / 256
	ld	a,(de)
	add	a,(hl)
	ld	(hl),a
	dec	h
	inc	d
	ld	a,(de)
	adc	a,(hl)
	ld	(hl),a
	inc	l
	jr	nz,UpdLoop

	; Clamp particle coordinates to screen dimensions.

	ld	l,P_OFFST
	ld	bc,128 * 256 + 188
	ld	de,6 * 256 + 130

ClampY1	ld	a,(hl)
	cp	b
	jr	nc,ClampY2
	ld	(hl),b

	ld	h,PrtData / 256 + 2	; Ugly but compresses well.
	ld	(hl),0
	ld	h,PrtData / 256

ClampY2	cp	c
	jr	c,ClampX1
	ld	(hl),c
	dec	(hl)

	ld	h,PrtData / 256 + 2
	ld	(hl),0
	ld	h,PrtData / 256

ClampX1	inc	l
	ld	a,(hl)
	cp	d
	jr	nc,ClampX2
	ld	(hl),d

	ld	h,PrtData / 256 + 2
	ld	(hl),0
	ld	h,PrtData / 256

ClampX2	cp	e
	jr	c,NoClamp
	ld	(hl),e
	dec	(hl)

	ld	h,PrtData / 256 + 2
	ld	(hl),0
	ld	h,PrtData / 256

NoClamp	inc	l
	jr	nz,ClampY1

	; Draw particle sprites.

	ld	l,P_OFFST
	ld	bc,%0011100000000111
	or	a

PrtDraw	ld	d,(hl)
	inc	l
	ld	a,(hl)
	rra
	ld	e,a
	jr	c,Sprite1

Sprite0	rrca
	or	%01111111
	ld	(de),a
	inc	d
	ld	(de),a
	inc	d
	ld	(de),a
	inc	d
	ld	(de),a
	inc	d
	ld	(de),a
	dec	e
	ex	af,af'
	ld	a,(de)
	or	b
	ld	(de),a
	ex	af,af'
	xor	%10000000
	dec	d
	ld	(de),a
	dec	d
	ld	(de),a
	dec	d
	ld	(de),a
	dec	d
	ld	a,(de)
	or	b
	ld	(de),a
	inc	d
	inc	e
	inc	e
	ld	a,(de)
	or	c
	ld	(de),a
	inc	d
	ld	a,(de)
	or	c
	ld	(de),a
	inc	d
	ld	a,(de)
	or	c
	ld	(de),a
	jr	Sprite

Sprite1	rrca
	or	%01111111
	ld	(de),a
	inc	d
	ld	(de),a
	inc	d
	ld	(de),a
	inc	d
	ld	(de),a
	inc	d
	ld	(de),a
	inc	e
	ex	af,af'
	ld	a,(de)
	or	c
	ld	(de),a
	ex	af,af'
	xor	%10000000
	dec	d
	ld	(de),a
	dec	d
	ld	(de),a
	dec	d
	ld	(de),a
	dec	d
	ld	a,(de)
	or	c
	ld	(de),a
	inc	d
	dec	e
	dec	e
	ld	a,(de)
	or	b
	ld	(de),a
	inc	d
	ld	a,(de)
	or	b
	ld	(de),a
	inc	d
	ld	a,(de)
	or	b
	ld	(de),a

Sprite	inc	l
	jr	nz,PrtDraw

	; Update music player.

	call	Music

	call	SwpBank
	ld	(DthRet + 1),sp

	; Update background colors.

	ld	h,32
Attrib	ld	a,128
	sub	h
	ld	(Attrib + 1),a
	xor	h
	ld	l,a
	add	hl,hl
	ld	bc,#18C0
	add	hl,bc
	ld	sp,hl

Color	ld	bc,#4D4D
	ld	d,c
	ld	e,c

	REPT	8
	push	bc
	push	de
	ENDM

	REPT	8
	push	de
	push	bc
	ENDM

	; For each quadruple of pixels with intensities %AAA %BBB %CCC %DDD register HL (when popped) equals %11DDDCCC01BBBAAA.
	; Lookup tables stored in separate memory banks for even/odd scanlines contain rasters corresponding to the value of HL.
	; The otherwise unnecessary zero bit prevents lookup table overflows in a separate image processing routine.

	ld	bc,SCR_H * (SCR_W - 1)
	ld	hl,#8000

Dither	ld	sp,hl
	pop	de
DthNop	nop				; Alternating NOP/INC D for even/odd scanlines (ugly but space saving).

	REPT	SCR_W - 1
	pop	hl			; Awkward pixel format pays off because we achieve fill rate of 6.5 T-states per pixel.
	ldi
	ENDM

	pop	hl
	ld	a,(hl)
	ld	(de),a

	pop	hl
	jp	pe,Dither

	ld	hl,DthNop
	ld	a,(hl)
	xor	#14			; Opcode of INC D.
	ld	(hl),a

DthRet	ld	sp,0

	; Update AY bass drum which needs roughly 50 fps refresh.

AyDrum	ld	a,1			; The bass drum kicks off with value 5.
	dec	a
	ret	z
	ld	(AyDrum + 1),a

	add	a,DrumFrq % 256 - 1
	ld	h,DrumFrq / 256
	ld	l,a
	ld	d,11
	jr	AyOut

	; Music player must reside inside a single aligned 256 byte memory bank.

Music	ld	a,1			; Music tempo is set to six 50 Hz interrupts.
	dec	a
	jr	nz,NoMusic
	ld	d,a
	ld	a,4
NoMusic	ld	(Music + 1),a
	ret	nz

PattPos	ld	a,15
	inc	a
	and	15
	ld	(PattPos + 1),a

PattAdr	add	a,Pattrn0 % 256
	ld	h,Pattrn0 / 256
	ld	l,a

	ld	e,(hl)
	ld	a,e
	and	7
	adc	a,ToneFrq		; ADC is "useless" but combined with the following part it compressess well.
	call	AyTone
	inc	d
	xor	a
	rl	e
	adc	a,ToneFrq
	call	AyTone
	inc	d
	ld	a,e
	rlca
	rlca
	rlca
	jr	nc,NoDrum
	ld	l,(AyDrum + 1) % 256
	ld	(hl),5
NoDrum	and	6
	ld	e,a
	add	a,BassFrq
	call	AyTone
	call	AyOut
	ld	d,11
	ld	a,e
	rrca
	add	a,EnvlFrq

AyTone	ld	l,a
AyOut	ld	bc,#FFFD
	out	(c),d
	ld	b,#BF
	outi
	inc	d
	ret

	; A music pattern is defined by 16 bytes. Each byte has the %BCCD0AAA format where:

	; AAA - 3-bit tone number for channel A (melody track).
	;   B - 1-bit tone number for channel B (bleep track).
	;  CC - 2-bit tone number for channel C (bass track).
	;   D - Bass drum flag.

Pattrn0	db	(0 << 7) | (3 << 5) | 6 | 16
	db	(0 << 7) | (2 << 5) | 6 | 0
	db	(0 << 7) | (0 << 5) | 6 | 0
	db	(0 << 7) | (0 << 5) | 6 | 0
	db	(1 << 7) | (3 << 5) | 6 | 16
	db	(1 << 7) | (0 << 5) | 0 | 0
	db	(0 << 7) | (0 << 5) | 0 | 0
	db	(0 << 7) | (0 << 5) | 0 | 0
	db	(0 << 7) | (0 << 5) | 1 | 0
	db	(0 << 7) | (3 << 5) | 2 | 16
	db	(0 << 7) | (0 << 5) | 3 | 0
	db	(0 << 7) | (0 << 5) | 4 | 0
	db	(1 << 7) | (3 << 5) | 5 | 16
	db	(1 << 7) | (0 << 5) | 6 | 0
	db	(1 << 7) | (1 << 5) | 7 | 0
	db	(0 << 7) | (1 << 5) | 5 | 0

	; Instead of using two patterns it would be possible to modify the existing pattern but packer does a better job.

Pattrn1	db	(0 << 7) | (3 << 5) | 6 | 16
	db	(0 << 7) | (2 << 5) | 3 | 0
	db	(0 << 7) | (0 << 5) | 5 | 0
	db	(0 << 7) | (0 << 5) | 5 | 0
	db	(1 << 7) | (3 << 5) | 1 | 16
	db	(1 << 7) | (0 << 5) | 0 | 0
	db	(0 << 7) | (0 << 5) | 0 | 0
	db	(0 << 7) | (0 << 5) | 0 | 0
	db	(0 << 7) | (0 << 5) | 1 | 0
	db	(0 << 7) | (3 << 5) | 2 | 16
	db	(0 << 7) | (0 << 5) | 3 | 0
	db	(0 << 7) | (0 << 5) | 4 | 0
	db	(1 << 7) | (3 << 5) | 5 | 16
	db	(1 << 7) | (0 << 5) | 6 | 0
	db	(1 << 7) | (1 << 5) | 7 | 0
	db	(1 << 7) | (1 << 5) | 5 | 0

	; We use Pythagorean pentatonic scale. All but the highest frequencies can be represented in their ideal ratios.

ToneFrq	db	#00, #60, #51, #48, #40, #36, #30, #29
EnvlFrq	db	#60, #36, #29, #16
DrumFrq	db	#C0, #40, #20, #18
BassFrq	dw	#0402, #0241, #0288

AyRegs	db	0, 0, 0, 0, #82, #4, 0, %11111011, %11111010, %11111000, %11111001, #6C, 0, 14

AyAC	equ	AyRegs + 8
AyABC	equ	AyRegs + 9
AyBC	equ	AyRegs + 10

	; Image processing routine remaps pixel values using lookup tables stored in dedicated memory banks.

	;   A - Source buffer vertical offset.
	; IXL - Source buffer horizontal offset.

SPLIT	equ	4
PART1	equ	(SCR_H / 2 - SPLIT) * SCR_W * 2
PART2	equ	SPLIT * SCR_W * 2

ImgDef	ld	ixl,2
ImgProc	ld	d,#7E
	add	a,d

	; Image processing is split into two parts due to synchronization with vertical refresh.

	ld	bc,PART1
	call	ImgPart

	ei
	halt				; We run at 25 fps in full sync.
	di

	ld	bc,PART2
ImgPart	ld	(ImgRet + 1),sp
ImgRow	inc	d
	inc	d
	ld	e,2

	add	a,e
	and	%10111111
	ld	ixh,a
	ld	sp,ix

	REPT	SCR_W
	pop	hl
	ldi
	ld	l,h			; This is the crux of the demo. We achieve processing rate of 11.5 T-states per pixel.
	ldi				; However, the first LDI must not change H which is prevented by the pixel format.
	ENDM

	jp	pe,ImgRow
ImgRet	ld	sp,0
	ret
