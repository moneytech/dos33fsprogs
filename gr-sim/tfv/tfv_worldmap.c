#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "gr-sim.h"
#include "tfv_utils.h"
#include "tfv_zp.h"
#include "tfv_defines.h"
#include "tfv_definitions.h"

#include "tfv_sprites.h"
#include "tfv_backgrounds.h"

#include "tfv_items.h"
#include "tfv_dialog.h"

#include "tfv_mapinfo.h"

// debug
static int random_encounters=1;

unsigned char map_location=LANDING_SITE;

/* Puzzle Room */
/* Get through office */
/* Have to run away?  What happens if die?  No save game?  Code? */

/* Construct the LED circuit */
/* Zaps through cloud */
/* Susie joins your party */

/* Final Battle */
/* Play music, lightning effects? */
/* TFV only hit for one damage, susie for 100 */


/* Load background to 0xc00 */
static int load_map_bg(void) {

	int i,temp;
	int start,end;

	ground_color=map_info[map_location].ground_color;

	/* Load background image, if applicable */
	if (map_info[map_location].background_image) {
		grsim_unrle(map_info[map_location].background_image,0xc00);
		return 0;
	}

	/* Sky */
	color_equals(COLOR_MEDIUMBLUE);
	for(i=0;i<10;i+=2) {
		hlin_double(PAGE2,0,39,i);
	}

	/* grassland/sloped left beach */
	if (map_info[map_location].land_type&LAND_LEFT_BEACH) {
		for(i=10;i<40;i+=2) {
			temp=4+(39-i)/8;
			color_equals(COLOR_DARKBLUE);
			hlin_double(PAGE2,0,temp,i);
			color_equals(COLOR_LIGHTBLUE);
			hlin_double_continue(2);
			color_equals(COLOR_YELLOW);
			hlin_double_continue(2);
			color_equals(ground_color);
			hlin_double_continue(35-temp);
		}
	}

	/* Grassland */
	if (map_info[map_location].land_type&LAND_GRASSLAND) {
		for(i=10;i<40;i+=2) {
			color_equals(ground_color);
			hlin_double(PAGE2,0,39,i);
		}
	}

	/* Mountain */
	if (map_info[map_location].land_type&LAND_MOUNTAIN) {
		for(i=10;i<40;i+=2) {
			color_equals(ground_color);
			hlin_double(PAGE2,0,39,i);
		}
	}

	/* Right Beach */
	if (map_info[map_location].land_type&LAND_RIGHT_BEACH) {
		for(i=10;i<40;i+=2) {
			temp=24+(i/4);	/* 26 ... 33 */
			color_equals(ground_color);
			hlin_double(PAGE2,0,temp,i);
			color_equals(COLOR_YELLOW);
			hlin_double_continue(2);	/* 28 ... 35 */
			color_equals(COLOR_LIGHTBLUE);
			hlin_double_continue(2);	/* 30 ... 37 */
			color_equals(COLOR_DARKBLUE);
			hlin_double_continue(35-temp);
		}

	}

	/* Draw north shore */
	if (map_info[map_location].land_type&LAND_NORTHSHORE) {
		color_equals(COLOR_DARKBLUE);
		hlin_double(PAGE2,0,39,10);
	}

	/* Draw south shore */
	if (map_info[map_location].land_type&LAND_SOUTHSHORE) {
		start=0; end=39;
		color_equals(COLOR_DARKBLUE);
		hlin_double(PAGE2,0,39,38);
		color_equals(COLOR_LIGHTBLUE);
		if (map_location==12) start=6;
		if (map_location==15) end=35;
		hlin_double(PAGE2,start,end,36);
		if (map_location==12) start=8;
		if (map_location==15) end=32;
		color_equals(COLOR_YELLOW);
		hlin_double(PAGE2,start,end,34);
	}

	/* Mountains */
	if (map_info[map_location].land_type&LAND_MOUNTAIN) {
		for(i=0;i<4;i++) {
			grsim_put_sprite_page(PAGE2,mountain,10+(i%2)*5,(i*8)+2);
		}
	}

	return 0;
}

int world_map(void) {

	int ch;
	int direction=1;
	int i,tree_limit;
	int newx=0,newy=0,moved;
	int special_destination=NOEXIT,destination_type=LOCATION_PLACE;
	int next_encounter=32;
	int odd=0;
	int refresh=1;
	int entry=0;
	int on_bird=0;
	int conversation_started=0;
	int conversation_person=0;
	int conversation_count=0;
	int item_received=-1,health_restored=0,buy_smartpass=0;
	int in_query=0;

	/************************************************/
	/* Landed					*/
	/************************************************/

	gr();

	color_equals(COLOR_BLACK);

	direction=1;


	while(1) {
		moved=0;
		newx=tfv_x;
		newy=tfv_y;

		ch=grsim_input();

		if (hp==0) break;

		if ((ch=='q') || (ch==27))  break;

		if ((ch=='t')) {
			for(i=0;i<12;i++) printf("scrn(%d,%d)=%d\n",
				tfv_x+1,tfv_y+i,scrn_page(tfv_x+1,tfv_y+i,8));
		}

		if ((ch=='w') || (ch==APPLE_UP)) {
			newy=tfv_y-2;
			moved=1;
		}
		if ((ch=='s') || (ch==APPLE_DOWN)) {
			newy=tfv_y+2;
			moved=1;
		}
		if ((ch=='a') || (ch==APPLE_LEFT)) {
			if (direction>0) {
				direction=-1;
				odd=0;
			}
			else {
				newx=tfv_x-1;
				moved=1;
			}
		}
		if ((ch=='d') || (ch==APPLE_RIGHT)) {
			/* Update random seed */
			random_8();

			if (direction<0) {
				direction=1;
				odd=0;
			}
			else {
				newx=tfv_x+1;
				moved=1;
			}
		}

		if (moved) conversation_started=0;

		if (ch==13) {

			health_restored=0;

			if (destination_type==LOCATION_CONVERSATION) {
				conversation_started=1;
				conversation_person=special_destination;

				/* HACK */

				/* Action Done */
				conversation_count=dialog[conversation_person].count;
				if (dialog[conversation_person].statement[conversation_count].action==ACTION_DONE) {
					conversation_started=0;
					dialog[conversation_person].count=-1;
					goto skip_all_this;
				}

				/* Get on Large Bird */
				if (dialog[conversation_person].statement[conversation_count].action==ACTION_BIRD) {
					printf("BIRD BIRD BIRD BIRD!\n");
					on_bird=1;
					conversation_started=0;
					dialog[conversation_person].count=-1;
					map_location=COLLEGE_PARK;
					tfv_x=32;
					tfv_y=5;
					refresh=1;
					goto skip_all_this;
				}



				/* Action Time */
				if (dialog[conversation_person].statement[conversation_count].action==ACTION_TIME) {
					conversation_started=0;
					dialog[conversation_person].count=-1;
					if (time_hours<95) time_hours+=4;
					goto skip_all_this;
				}

				/* Move to next conversation */
				if (dialog[conversation_person].count==-1) {
					dialog[conversation_person].count=0;
				}
				else {
					dialog[conversation_person].count=
					dialog[conversation_person].statement[dialog[conversation_person].count].next;
				}
				conversation_count=dialog[conversation_person].count;


				/* Check for items */
				if (dialog[conversation_person].statement[conversation_count].action==ACTION_ITEM) {

					item_received=dialog[conversation_person].statement[conversation_count].item;
					printf("ACTION ITEM %d\n",item_received);

					/* Action Smartpass */
					/* FIXME: make generic item buy? */
					if (item_received==ITEM_SMARTPASS) {
						if (buy_smartpass) {

							printf("Trying to get smartpass!\n");
							if (money<5) {
								item_received=-1;
								goto no_smartpass;
							}
							else {
								money-=5;
							}
						}
						else {
							item_received=-1;
							goto no_smartpass;
						}
					}


					if (item_received<8) {
						items1|=(1<<item_received);
					}
					else if (item_received<16) {
						items2|=(1<<(item_received&0x7));
					}
					else if (item_received<24) {
						items3|=(1<<(item_received&0x7));
					}
					dialog[conversation_person].statement[conversation_count].action=ACTION_NONE;
no_smartpass:;
				}
				else {
					item_received=-1;
				}
				if (dialog[conversation_person].statement[conversation_count].action==ACTION_QUERY) {
					in_query=1;
				}
			}
			else if (destination_type==LOCATION_SPACESHIP) {
				return LOCATION_SPACESHIP;
			}
			else if (destination_type==LOCATION_PUZZLE) {
				do_ending();
			}
			else if (special_destination!=NOEXIT) {
				map_info[map_location].saved_x=tfv_x;
				map_info[map_location].saved_y=tfv_y;

				map_location=special_destination;
				entry=1;
				refresh=1;
			}
skip_all_this: ;
		}

		if (ch=='h') {
			print_help();
		}
		if (ch=='i') {
			print_info();
		}

		if (ch=='m') {
			show_map();
			refresh=1;
		}

		/* Only have encounters on world map */
		if ((moved) && (map_location<16)) {
			if (random_encounters) next_encounter--;
			if (next_encounter==0) {
				do_battle(map_info[map_location].ground_color);
				refresh=1;
				next_encounter=32+(random_8()%32);
			}
		}

		/* debugging routines */
		if (ch=='b') {
			do_battle(map_info[map_location].ground_color);
			refresh=1;
		}

		if (ch=='e') {
			do_ending();
			refresh=1;
		}



		/* Handle entry to a new area */
		if (entry) {
			printf("Entering!\n");

			/* Y can never be 0 by accident */
			if (map_info[map_location].saved_y) {
				newx=map_info[map_location].saved_x;
				newy=map_info[map_location].saved_y;
				map_info[map_location].saved_x=0;
				map_info[map_location].saved_y=0;
				goto done_entry;
			}


			if (map_info[map_location].entry_type&ENTRY_R_OR_L) {
				if (tfv_x<20) newx=10;
				else newx=30;
				newy=26;
			}
			if (map_info[map_location].entry_type&ENTRY_EXPLICIT) {
				newx=map_info[map_location].entry_x;
				newy=map_info[map_location].entry_y;
			}
			if (map_info[map_location].entry_type&ENTRY_CENTER) {
				newx=19;
				newy=26;
			}
			if (map_info[map_location].entry_type&ENTRY_MINX) {
				if (newx<map_info[map_location].entry_x) {
					newx=map_info[map_location].entry_x;
				}
			}
			if (map_info[map_location].entry_type&ENTRY_MAXX) {
				if (newx>map_info[map_location].entry_x) {
					newx=map_info[map_location].entry_x;
				}
			}
			if (map_info[map_location].entry_type&ENTRY_MAXY) {
				if (newy>map_info[map_location].entry_y) {
					newy=map_info[map_location].entry_y;
				}
			}

done_entry:

			entry=0;
			//moved=1;
			printf("Newx=%d,Newy=%d\n",newx,newy);
			tfv_x=newx; tfv_y=newy;
		}


		/* Collision detection + Movement */
		if (moved) {
			odd=!odd;
			steps++;

			if (newx>36) {
				if (map_info[map_location].e_exit!=NOEXIT) {
					map_location=map_info[map_location].e_exit;
					tfv_x=1;
					refresh=1;
					entry=1;
				}
			}
			else if (newx<=0) {
				if (map_info[map_location].w_exit!=NOEXIT) {
					map_location=map_info[map_location].w_exit;
					tfv_x=35;
					refresh=1;
					entry=1;
				}
			}
			else if (newy<map_info[map_location].miny) {
				if (map_info[map_location].n_exit!=NOEXIT) {
					map_location=map_info[map_location].n_exit;
					tfv_y=26;
					refresh=1;
					entry=1;
				}
			}
			else if (newy>=28) {
				if (map_info[map_location].s_exit!=NOEXIT) {
					map_location=map_info[map_location].s_exit;
					tfv_y=4;
					refresh=1;
					entry=1;
				}
			}
			else if ((scrn_page(newx+1,newy+11,8)==
					(map_info[map_location].ground_color&
					0xf)) &&
				(scrn_page(newx+1,newy+11,8)==
					(map_info[map_location].ground_color&
					0xf))) {

				tfv_x=newx;
				tfv_y=newy;
			}
			else {
				printf("scrn(%d,%d)==%d,scrn(%d,%d)==%d\n",
					newx+1,newy+11,scrn_page(newx+1,newy+11,8),
					newx+2,newy+11,scrn_page(newx+2,newy+11,8));
				// make sad noise
			}

		}

		if (refresh) {
			int s;
			s=ram[DRAW_PAGE];
			ram[DRAW_PAGE]=PAGE2;
			clear_bottom();
			ram[DRAW_PAGE]=s;
			load_map_bg();
			refresh=0;
		}

		gr_copy_to_current(0xc00);

		/* Draw Background Ground Scatter */
		if ((map_info[map_location].scatter) &&
			(tfv_y>=map_info[map_location].scatter_cutoff)) {

			if (map_info[map_location].scatter&SCATTER_SNOWYPINE) {
				grsim_put_sprite(snowy_tree,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}

			if (map_info[map_location].scatter&SCATTER_PINE) {
				grsim_put_sprite(pine_tree,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}


			if (map_info[map_location].scatter&SCATTER_PALM) {
				grsim_put_sprite(palm_tree,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}

			if (map_info[map_location].scatter&SCATTER_CACTUS) {
				grsim_put_sprite(cactus,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}

			if (map_info[map_location].scatter&SCATTER_SPOOL) {
				grsim_put_sprite(spool,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}

			if (map_info[map_location].scatter&SCATTER_JEN_LIZ) {
				grsim_put_sprite(jen_liz,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}


		}

		/* Draw Background Trees */
		if (map_info[map_location].land_type&LAND_FOREST) {
			for(i=10;i<tfv_y+8;i+=2) {
				tree_limit=22+(i/4);
				color_equals(COLOR_DARKGREEN);
				hlin_double(ram[DRAW_PAGE],0,tree_limit,i);
			}
		}

		if (on_bird) {
			if (direction==-1) {
				if (odd) grsim_put_sprite(bird_rider_walk_left,tfv_x,tfv_y);
				else grsim_put_sprite(bird_rider_stand_left,tfv_x,tfv_y);
			}
			if (direction==1) {
				if (odd) grsim_put_sprite(bird_rider_walk_right,tfv_x,tfv_y);
				else grsim_put_sprite(bird_rider_stand_right,tfv_x,tfv_y);
			}
		}
		else {
			if (direction==-1) {
				if (odd) grsim_put_sprite(tfv_walk_left,tfv_x,tfv_y);
				else grsim_put_sprite(tfv_stand_left,tfv_x,tfv_y);
			}
			if (direction==1) {
				if (odd) grsim_put_sprite(tfv_walk_right,tfv_x,tfv_y);
				else grsim_put_sprite(tfv_stand_right,tfv_x,tfv_y);
			}
		}

		/* Draw Below Ground Scatter */
		if ((map_info[map_location].scatter) &&
			(tfv_y<map_info[map_location].scatter_cutoff)) {

			if (map_info[map_location].scatter&SCATTER_SNOWYPINE) {
				grsim_put_sprite(snowy_tree,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}

			if (map_info[map_location].scatter&SCATTER_PINE) {
				grsim_put_sprite(pine_tree,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}


			if (map_info[map_location].scatter&SCATTER_PALM) {
				grsim_put_sprite(palm_tree,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}

			if (map_info[map_location].scatter&SCATTER_CACTUS) {
				grsim_put_sprite(cactus,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}

			if (map_info[map_location].scatter&SCATTER_SPOOL) {
				grsim_put_sprite(spool,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}

			if (map_info[map_location].scatter&SCATTER_JEN_LIZ) {
				grsim_put_sprite(jen_liz,
					map_info[map_location].scatter_x,
					map_info[map_location].scatter_y);
			}


		}

		if (map_info[map_location].land_type&LAND_FOREST) {

			/* Draw Below Forest */
			for(i=tfv_y+8;i<36;i+=2) {
				tree_limit=22+(i/4);
				color_equals(COLOR_DARKGREEN);
				hlin_double(ram[DRAW_PAGE],0,tree_limit,i);
			}

			int f;
			/* Draw tree trunks */
			for(f=36;f<40;f+=2) {

				color_equals(COLOR_BROWN);
				hlin_double(ram[DRAW_PAGE],0,0,f);

				for(i=0;i<13;i++) {
					color_equals(COLOR_GREY);
					hlin_double_continue(1);
					color_equals(COLOR_BROWN);
					hlin_double_continue(1);
				}
			}
		}

		if (map_info[map_location].land_type&LAND_LIGHTNING) {
			if ((steps&0xf)==0) {
				grsim_put_sprite(lightning,25,4);
				/* Hurt hit points if in range? */
				if ((tfv_x>25) && (tfv_x<30) && (tfv_y<12)) {
					printf("HIT! %d %d\n\n",steps,hp);
					if (hp>11) {
						hp=10;
					}
				}
			}
		}

		special_destination=NOEXIT;
		destination_type=LOCATION_PLACE;
		for(i=0;i<map_info[map_location].num_locations;i++) {

			if ( (tfv_x>=map_info[map_location].location[i].x0) &&
			     (tfv_x<=map_info[map_location].location[i].x1) &&
			     (tfv_y+11>=map_info[map_location].location[i].y0) &&
			     (tfv_y+11<=map_info[map_location].location[i].y1)) {

				ram[CH]=(40-strlen(map_info[map_location].location[i].name))/2;
				ram[CV]=20;
				move_and_print(map_info[map_location].location[i].name);

				special_destination=map_info[map_location].location[i].destination;
				destination_type=map_info[map_location].location[i].type;

				break;
			}
		}

		if (conversation_started) {
			char *item_name;
			ram[CH]=1;
			ram[CV]=21;
			move_and_print(
				dialog[conversation_person].statement[dialog[conversation_person].count].words);
//			printf("%s\n",dialog[conversation_person].statement[0].words);
			if (item_received!=-1) {
				item_name=item_names[item_received>>3][item_received%8];
				ram[CH]=(40-(15+strlen(item_name)))/2;
				ram[CV]=23;
				move_and_print("RECEIVED ITEM: ");
				ram[CH]+=15;
				move_and_print(item_name);
			}

			if (health_restored) {
				ram[CH]=10;
				ram[CV]=23;
				move_and_print("HEALTH/MP RESTORED");
			}

		}

		page_flip();

		/* Take over keyboard if in query */
		if (in_query) {
			int saved_draw;
			int which_line=0;

			saved_draw=ram[DRAW_PAGE];

			ram[DRAW_PAGE]=ram[DISP_PAGE]*4;

			ram[CH]=5;
			ram[CV]=22;
			move_and_print(
				dialog[conversation_person].statement[dialog[conversation_person].count+1].words);

			printf("Printing %s at %d,%d page %d\n",
				dialog[conversation_person].statement[dialog[conversation_person].count+1].words,
				ram[CH],ram[CV],ram[DRAW_PAGE]);

			ram[CH]=5;
			ram[CV]=23;
			move_and_print(
				dialog[conversation_person].statement[dialog[conversation_person].count+2].words);

			while(1) {
				if (which_line==0) {
					ram[CH]=0;
					ram[CV]=22;
					move_and_print("--> ");
					ram[CH]=0;
					ram[CV]=23;
					move_and_print("    ");
				}
				else {
					ram[CH]=0;
					ram[CV]=22;
					move_and_print("    ");
					ram[CH]=0;
					ram[CV]=23;
					move_and_print("--> ");
				}
				grsim_update();
//				printf("Waiting\n");
				ch=grsim_input();
//				printf("OOGAH %d\n",ch);
				if ((ch==APPLE_UP) || (ch==APPLE_DOWN)) {
					which_line=!which_line;
				}
				if (ch==13) break;
				usleep(100000);
			}
			dialog[conversation_person].count=
				dialog[conversation_person].count+1+which_line;
//				dialog[conversation_person].statement[dialog[conversation_person].count]+1+which_line;
			ram[DRAW_PAGE]=saved_draw;
			in_query=0;

			/* Handle health restore */
			conversation_count=dialog[conversation_person].count;
			if (dialog[conversation_person].statement[conversation_count].action==ACTION_RESTORE) {
				printf("RESTORE RESTORE RESTORE!\n");
				hp=max_hp;
				mp=max_mp;
				health_restored=1;
			}

			if (dialog[conversation_person].statement[conversation_count].action==ACTION_SMARTPASS) {
				printf("Attempt to buy!\n");
				buy_smartpass=1;
			}

			dialog[conversation_person].count=
				dialog[conversation_person].statement[dialog[conversation_person].count].next;


		}


		if (steps>=60) {
			steps=0;
			time_minutes++;
			if (time_minutes>=60) {
				time_hours++;
				time_minutes=0;
			}
		}

		usleep(10000);
	}

	return 0;
}


