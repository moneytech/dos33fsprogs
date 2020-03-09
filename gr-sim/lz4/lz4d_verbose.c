#include <stdio.h>
#include <string.h>

#include "6502_emulate.h"

#define MAX_INPUT	65536
static unsigned char input[MAX_INPUT];

#define src	0x0
#define dst	0x2
#define end	0x4
#define count	0x6
#define delta	0x8
#define A1L	0x3c
#define A1H	0x3d
#define A2L	0x3e
#define A2H	0x3f
#define A4L	0x42
#define A4H	0x43

static void getsrc(void) {
//getsrc:
	a=ram[y_indirect(src,y)];		// lda 	(src), y

	printf("LOAD %02X%02X: %02X\n",ram[src+1],ram[src],a);

	ram[src]++;				//inc	src
	if (ram[src]!=0) goto done_getsrc;	//bne	+
	ram[src+1]++;				//inc	src+1
done_getsrc: ;

	//+	rts
}

void buildcount(void) {
	printf("\tBUILDCOUNT: A=0x%x\n",a);
//buildcount:
	x=1;					// ??		// ldx	#1
	ram[count+1]=x; 			// ??		// stx	count+1
	cmp(0xf);				// if 15, more complicated // cmp	#$0f
	if (z==0) goto done_buildcount;		// otherwise A is count // bne	++
buildcount_loop:
	ram[count]=a;				//-	sta	count
//	printf("MBC ");
	getsrc();				//jsr	getsrc
	printf("\tADDITIONAL BUILDCOUNT 0x%x, adding 0x%x\n",a,ram[count]);
	x=a;					//tax
	c=0;					//clc
	adc(ram[count]);			//adc	count
	printf("\tGOT 0x%x c=%d\n",a,c);
	if (c==0) goto skip_buildcount;		// bcc	+
	ram[count+1]++;				//inc	count+1
skip_buildcount:
	printf("\tUPDATED COUNT %02X%02X\n",ram[count+1],a);
	x++;					// check if x is 255	//+	inx
	if (x==0) goto buildcount_loop;		// if so, add in next byte //beq	-
done_buildcount: ;				//++	rts
	printf("\tBUILDCOUNT= %02X%02X r[c+1]=%02X r[c]=%02X a=%02X x=%02X\n",
		ram[count+1],a,ram[count+1],ram[count],a,x);
}


static void putdst(void) {
//	printf("PUTADDR=%04X\n",y_indirect(dst,y));
						// putdst:
	ram[y_indirect(dst,y)]=a;		//	sta 	(dst), y
	if (y!=0) printf("ERROR ERROR ERROR ERROR ERROR\n");
	printf("\t\tPUT: %02X%02X = %02X\n",ram[dst+1],ram[dst],a);
	ram[dst]++;				//	inc	dst
	if (ram[dst]!=0) goto putdst_end;	//	bne	+
	ram[dst+1]++;				//	inc	dst+1
putdst_end:;
						//+	rts

}

static void getput(void) {
						// getput:
	printf("GP ");
	getsrc();				// jsr	getsrc
	putdst();				// ; fallthrough
}

// 202 -> 201 -> 100 -> 1FF
// 201 -> 100 -> 1FF
// 200 -> 2ff -> 2fe
// 1ff -> 1fe

static void docopy(void) {
	printf("\tDOCOPY ENTRY: %02X%02X\n",ram[count+1],x);
						// docopy:
docopy_label:
	printf("\tDOCOPY %02X%02X: ",ram[count+1],x);
	getput();				// jsr	getput
	x--;					// dex
	if (x!=0) goto docopy_label;		// bne	docopy
	ram[count+1]--;				// dec	count+1
	if (ram[count+1]!=0) goto docopy_label;	//bne	docopy
						//rts
}


#define ORGOFFSET	0x6000
#define PAKOFFSET	0x4000


int main(int argc, char **argv) {

	FILE *fff;
	int size;
	short orgoff,paksize,pakoff;
	int token_count=0;

	init_6502();

	if (argc<2) {
		fprintf(stderr,"\nUsage: %s filename\n\n",argv[0]);
	}

//	fff=fopen("../mockingboard/outi.raw.lz4","r");
	fff=fopen(argv[1],"r");
	if (fff==NULL) {
		fprintf(stderr,"Error opening %s!\n",argv[1]);
		return -1;
	}

	size=fread(input,sizeof(unsigned char),MAX_INPUT,fff);
	printf("Read %d bytes\n",size);

	fclose(fff);

	memcpy(&ram[PAKOFFSET],input,size);

	//LZ4 data decompressor for Apple II
	//Peter Ferrie (peter.ferrie@gmail.com)

	//init	=	0 ;set to 1 if you know the values
	//hiunp	=	0 ;unpacker entirely in high memory
	//hipak	=	0 ;packed data entirely in high memory (requires hiunp)

	//oep = 0; //first unpacked byte to run, you must set this by yourself
	orgoff = ORGOFFSET; //offset of first unpacked byte, you must set this by yourself
	paksize	= size-0xb-8;
			// minus 4 for checksum at end
			// not sure what other 4 is from?
			// block checksum? though had that disabled?

		//size of packed data, you must set this by yourself if hiunp=0
	pakoff = PAKOFFSET+11; // 11 byte offset to data?


//LCBANK2	=	$c083
//MOVE	=	$fe2c

	a=(pakoff&0xff);	//lda	#<pakoff ;packed data offset
	ram[src]=a;		//sta	src
	a=(pakoff+paksize)&0xff;//lda	#<(pakoff+paksize) ;packed data size
	ram[end]=a;		// sta	end
	a=(pakoff>>8);		//lda	#>pakoff
	ram[src+1]=a;		//sta	src+1
	a=(pakoff+paksize)>>8;	//lda	#>(pakoff+paksize)
	ram[end+1]=a;		//	sta	end+1
	a=(orgoff>>8);		//lda	#>orgoff ;original unpacked data offset
	ram[dst+1]=a;		//sta	dst+1
	a=(orgoff&0xff);	//lda	#<orgoff
	ram[dst]=a;		// sta	dst

	printf("packed size: raw=%x, adj=%x\n",size,paksize);
	printf("packed addr: %02X%02X\n",ram[src+1],ram[src]);
	printf("packed end : %02X%02X\n",ram[end+1],ram[end]);
	printf("dest addr  : %02X%02X\n",ram[dst+1],ram[dst]);

// https://github.com/lz4/lz4/wiki/lz4_Frame_format.md

// Should: check for magic number 04 22 4d 18
//	FLG: 64 in our case (01=version, block.index=1, block.checksum=0
//		size=0, checksum=1, reserved
//	MAX Blocksize: 40 (64kB)
//	HEADER CHECKSUM: a7
//	BLOCK HEADER: 4 bytes (le)  If highest bit set, uncompressed!


//unpack:				//;unpacker entrypoint
//	goto unpmain;			// jmp	unpmain

//unpack:
	y=0;				// used for offset	//ldy	#0

parsetoken:
	token_count++;
	printf("LOAD TOKEN %d: ",token_count);
	getsrc();						// jsr	getsrc
					// get token
	pha();				// save for later	// pha
	lsr();				// num literals in top 4	// lsr
	lsr();							// lsr
	lsr();							// lsr
	lsr();							// lsr
	if (a==0) goto copymatches; 	// if zero, no literals // beq	copymatches

	buildcount();			// otherwise, build the count // jsr	buildcount

	x=a;				// tax
	docopy();			// jsr	docopy
	a=ram[src];			// lda	src
	cmp(ram[end]);			// cmp	end
	a=ram[src+1];			// lda	src+1

	sbc(ram[end+1]);		// sbc	end+1
	if (c) {
		printf("Done!\n");
		printf("src        : %02X%02X\n",ram[src+1],ram[src]);
		printf("packed end : %02X%02X\n",ram[end+1],ram[end]);
		goto done;		// bcs	done
	}

copymatches:
	printf("\tDELTAL ");
	getsrc();					// jsr	getsrc
	ram[delta]=a;					// sta	delta
	printf("\tDELTAH ");
	getsrc();					// jsr	getsrc
	ram[delta+1]=a;					// sta	delta+1
	printf("\tDELTA is %02X%02X\n",ram[delta+1],ram[delta]);
	pla();				// restore token	// pla
	a=a&0xf;			// get bottom 4 bits	// and	#$0f
	buildcount();			// jsr	buildcount

	c=0;				// clc
	adc(4);				// adc	#4
	x=a;				// tax
	if (x==0) goto copy_skip;	//BUGFIX // beq  +
	if (c==0) goto copy_skip;	// bcc	+
	ram[count+1]++;			// inc	count+1
copy_skip:
	a=ram[src+1];			//+	lda	src+1
	pha();				// pha
	a=ram[src];			// lda	src
	pha();				// pha
	printf("\tSAVED SRC: %02X%02X\n",ram[src+1],ram[src]);
//	printf("CALCULATING: DST %02X%02X - DELTA %02X%02X\n",ram[dst+1],ram[dst],ram[delta+1],ram[delta]);
	c=1;				// sec
	a=ram[dst];			// lda	dst
	sbc(ram[delta]);		// sbc	delta
	ram[src]=a;			// sta	src
	a=ram[dst+1];			// lda	dst+1
	sbc(ram[delta+1]);		// sbc	delta+1
	ram[src+1]=a;			// sta	src+1
	printf("\tNEW SRC: %02X%02X\n",ram[src+1],ram[src]);
	docopy();			// jsr	docopy
	pla();				// pla
	ram[src]=a;			// sta	src
	pla();				// pla
	ram[src+1]=a;			// sta	src+1
	printf("\tRESTORED SRC: %02X%02X\n",ram[src+1],ram[src]);
	goto parsetoken;		// jmp	parsetoken

done:
	pla();				// pla


	int out_size=(ram[dst+1]<<8)+ram[dst];
	out_size-=ORGOFFSET;

	printf("dest addr  : %02X%02X\n",ram[dst+1],ram[dst]);

	int i,j,addr,temp;
	addr=ORGOFFSET;

	printf("\n");
	for(i=0;i<256;i++) {
		if (i%16==0) printf("%04X: ",addr+i);
		printf("%02X ",ram[addr+i]);
		if (i%16==15) {
			for(j=0;j<16;j++) {
				temp=ram[((addr+i)&0xfff0)+j];
				if ((temp<' ') || (temp>127)) printf(".");
				else printf("%c",temp);
			}
			printf("\n");
		}
	}

	printf("\n");
					// rts

	fff=fopen("out.out","w");
	if (fff==NULL) {
		fprintf(stderr,"Error opening!\n");
		return -1;
	}

	printf("Out size=%d\n",out_size);

	printf("Total tokens: %d\n",token_count);

	fwrite(&ram[ORGOFFSET],1,out_size,fff);

	fclose(fff);

	return 0;
}
