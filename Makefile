include Makefile.inc

all:
	cd asoft_basic-utils && make
	cd asoft_presenter && make
#	cd asoft_sound && make
	cd bmp2dhr && make
#	cd chiptune_player && make
#	cd dlowres_mode7 && make
	cd dos33fs-utils && make
#	cd glados3.3 && make
#	cd gr-sim && make
#	cd gr-utils && make
	cd hgr-utils && make
#	cd mockingboard && make
#	cd mode7 && make
#	cd mode7_demo && make
#	cd still_alive && make
#	cd tfv && make
#	cd two-liners && make

install:
	cd asoft_basic-utils && make install
	cd asoft_presenter && make install
#	cd asoft_sound && make install
#	cd chiptune_player && make install
#	cd dlowres_mode7 && make install
	cd dos33fs-utils && make install
#	cd glados3.3 && make install
#	cd gr-sim && make install
#	cd gr-utils && make install
	cd hgr-utils && make install
#	cd mockingboard && make install
#	cd mode7 && make install
#	cd mode7_demo && make install
#	cd still_alive && make install
#	cd tfv && make install
#	cd two-liners && make install

clean:
	cd asoft_basic-utils && make clean
	cd asoft_presenter && make clean
	cd asoft_sound && make clean
	cd bmp2dhr && make clean
	cd chiptune_debug && make clean
	cd chiptune_player && make clean
	cd dlowres_mode7 && make clean
	cd dos33fs-utils && make clean
	cd electric_duet && make clean
	cd ethernet && make clean
	cd glados3.3 && make clean
	cd gr-sim && make clean
	cd gr-utils && make clean
	cd hgr-utils && make clean
	cd ksp && make clean
	cd mockingboard && make clean
	cd mode7 && make clean
	cd mode7_demo && make clean
	cd still_alive && make clean
	cd tfv && make clean
	cd two-liners && make clean
	rm -f *~

test:
