#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <fcntl.h>

#include "gr-sim.h"

int main(int argc, char **argv) {

	int ch,fd;

	if (argc<1) {
		fprintf(stderr,"Usage: hgr_view FILENAME\n");
		fprintf(stderr,"  where FILENAME is an 1k AppleII LORES image\n\n");
	}

	grsim_init();

	home();

	gr();
	/* Show all 40x48, no bottom text */
	soft_switch(MIXCLR);

	fd=open(argv[1],O_RDONLY);
	if (fd<0) {
		printf("Error opening!\n");
		return -1;
	}
	read(fd,&ram[0x400],1024);
	close(fd);

	grsim_update();

	while(1) {
		ch=grsim_input();
		if (ch) break;
		usleep(100000);
	}

	return 0;
}
