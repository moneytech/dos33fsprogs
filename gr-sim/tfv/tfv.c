#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "gr-sim.h"
#include "tfv_utils.h"
#include "tfv_zp.h"
#include "tfv_definitions.h"
#include "tfv_dialog.h"

/* stats */
unsigned char level=0;
unsigned char hp=95,max_hp=100;
unsigned char mp=45,max_mp=50;
unsigned char limit=1;
unsigned char money=10,experience=0;
unsigned char time_hours=0,time_minutes=0;
//unsigned char items1=0xff,items2=0xff,items3=0x07;
unsigned char items1=0,items2=0,items3=0;
unsigned char steps=0;

/* location */
//unsigned char map_x=5;
char tfv_x=15,tfv_y=20; // tfv_y should always be even
unsigned char ground_color;

char nameo[9];


int main(int argc, char **argv) {

	int result;

	init_dialog();

	grsim_init();

	home();
	gr();

	/* Clear bottom of zero page */
	apple_memset(&ram[0],0,16);

	/* clear top page0 */
	/* clear top page1 */
	//clear_top(PAGE0);
	//clear_top(PAGE1);

	/* clear bottom page0 */
	/* clear bottom page1 */
	//clear_bottom(PAGE0);
	//clear_bottom(PAGE1);

	clear_screens();

	/* Do Opening */
	opening();

	/* Title Screen */
title_loop:
	result=title();
	if (result==0) goto play_game;
	if (result==2) credits();
	goto title_loop;


play_game:
	nameo[0]=0;

	/* Get player */
	player_select();

	/* Get Name */
	name_screen();
	if (nameo[0]==0) {
		strcpy(nameo,"DEATER");
	}

	/* Flying */
	home();
back_to_flying:
	flying();

	/* World Map */
	result=world_map();

	if (result!=0) goto back_to_flying;

	/* Game Over, Man */
	game_over();

	return 0;
}

