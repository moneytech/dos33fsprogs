#include <stdio.h>
#include <stdlib.h>

#include "gr-sim.h"
#include "tfv_utils.h"
#include "tfv_zp.h"
#include "tfv_defines.h"
#include "tfv_definitions.h"

#include "tfv_items.h"


/*
          1         2         3         4
01234567890123456789012345678901234567890
****************************************  1
* DEATER	    * LEVEL 1          *  2
****************************************  3
* INVENTORY         * STATS            *  4
****************************************  5
*		    * HP:      50/100  *  6
*		    * MP:         0/0  *  7
*                   *                  *  8
*		    * EXPERIENCE:   0  *  9
*		    * NEXT LEVEL:  16  * 10
*                   *                  * 11
*		    * MONEY: $1        * 12   0-256
*		    * TIME: 00:00      * 13
*		    *		       * 14
*		    *		       * 15
*		    *		       * 16
*		    *		       * 17
*		    *		       * 18
*		    *		       * 19
*		    *		       * 20
*		    *		       * 21
*		    *		       * 22
*		    *	               * 23
**************************************** 24

EXPERIENCE = 0...255
LEVEL = EXPERIENCE /  = 0...63
NEXT LEVEL =
MONEY   = 0...255
MAX_HP  = 32+EXPERIENCE (maxing at 255)
*/

char item_names[3][8][15]={
	{
	"CUPCAKE",
	"CARROT",
	"SMARTPASS",
	"ELF RUNES",
	"LIZBETH STAR",
	"KARTE SPIEL",
	"GLAMDRING",
	"VEGEMITE",
	},
	{
	"BLUE LED",
	"RED LED",
	"1K RESISTOR",
	"4.7K RESISTOR",
	"9V BATTERY",
	"1.5V BATTERY",
	"LINUX CD",
	"ARMY KNIFE",
	},
	{
	"CHEX MIX",
	"CLASS RING",
	"VORTEX CANNON",
	}
};

void print_info(void) {
	int i;
	int current_y;

	text();
	home();

	/* Inverse Space */
	/* 0x30=COLOR */
	ram[0x30]=0x20;

	/* Draw boxes */
	hlin_double(0,0,39,0);
	hlin_double(0,0,39,4);
	hlin_double(0,0,39,8);
	hlin_double(0,0,39,46);

	basic_vlin(0,48,0);
	basic_vlin(0,48,20);
	basic_vlin(0,48,39);

	basic_htab(3);
	basic_vtab(2);
	basic_print(nameo);

	basic_htab(23);
	basic_print("LEVEL ");
	print_u8(level);

	basic_htab(3);
	basic_vtab(4);
	basic_print("INVENTORY");
	basic_htab(23);
	basic_print("STATS");


	current_y=6;

	for(i=0;i<8;i++) {
		basic_htab(4);
		basic_vtab(current_y);
		if (items1&(1<<i)) {
			basic_print(item_names[0][i]);
			current_y++;
		}
	}
	for(i=0;i<8;i++) {
		basic_htab(4);
		basic_vtab(current_y);
		if (items2&(1<<i)) {
			basic_print(item_names[1][i]);
			current_y++;
		}
	}
	for(i=0;i<8;i++) {
		basic_htab(4);
		basic_vtab(current_y);
		if (items3&(1<<i)) {
			basic_print(item_names[2][i]);
			current_y++;
		}
	}

	basic_htab(23);
	basic_vtab(6);
	basic_print("HP:      ");
	print_u8(hp);
	basic_print("/");
	print_u8(max_hp);

	basic_htab(23);
	basic_vtab(7);
	basic_print("MP:       ");
	print_u8(mp);
	basic_print("/");
	print_u8(max_mp);

	basic_htab(23);
	basic_vtab(9);
	basic_print("EXPERIENCE: ");
	print_u8(experience);

	basic_htab(23);
	basic_vtab(10);
	basic_print("NEXT LEVEL: ");

	basic_htab(23);
	basic_vtab(12);
	basic_print("MONEY: $");
	print_u8(money);

	basic_htab(23);
	basic_vtab(13);
	basic_print("TIME: ");
	if (time_hours<10) basic_print("0");
	print_u8(time_hours);
	basic_print(":");
	if (time_minutes<10) basic_print("0");
	print_u8(time_minutes);

	grsim_update();

	repeat_until_keypressed();
	home();
	gr();
}
