#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {

	int x,y,cycles,desired,range=10;

	desired=3116;

	if (argc>1) desired=atoi(argv[1]);

	printf("You want %d cycles\n",desired);
	for(x=0;x<255;x++) {
		for(y=0;y<255;y++) {
			cycles=1+5*y+y*(5*x+1);
			if (((cycles-desired)<range) && ((cycles-desired)>-range)) {
				printf("Try X=%d Y=%d cycles=%d\n",
					x,y,cycles);
			}
		}
	}
	return 0;
}
