#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "gr-sim.h"

int main(int argc, char **argv) {

	int xx,yy,ch;

	grsim_init();

	home();

	hgr();


	/* Put horizontal lines on screen */
	for(yy=0;yy<100;yy++) {
		hcolor_equals(yy%8);
		hplot(yy,yy);
		hplot_to(200,yy);
	}

	/* Put vertical lines on screen */
	for(xx=0;xx<100;xx+=2) {
		hcolor_equals((xx%16)/2);
		hplot(xx,159);
		hplot_to(xx,100);
	}

	while(1) {
		grsim_update();

		ch=grsim_input();

		if (ch=='q') break;

		usleep(100000);

	}
	int i;
	printf("20D0: ");
	for(i=0;i<16;i++) printf("%x ",ram[0x20d0+i]);
	printf("\n");

	return 0;
}
