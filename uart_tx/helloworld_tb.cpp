/*
 * This file is part of verilog_programming
 *
 * Copyright (C) 2026 Costantino
 *
 * This file is a modified version from: Verilog, Formal Verification and Verilator Beginner's Tutorial
 * Copyright (C) Dan Gisselquist, Ph.D.
 *               Gisselquist Technology, LLC
 * Licensed under GPLv3 or later.
 *
 * Modifications:
 * - minor modifications
 */

//#include <cstdio>
#include <stdio.h>
#include <stdlib.h>
#include "Vhelloworld.h"
#include "test.h"
#include "verilated.h"
#include "cosim.h"
#include <verilatedos.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <signal.h>

int main(int argc, char **argv) {

        Verilated::commandArgs(argc,argv);
        
	TESTB<Vhelloworld> *tb = new TESTB<Vhelloworld>;
	UARTSIM *uart = new UARTSIM;
	unsigned baudclocks;

	baudclocks = tb->m_core->o_setup;
	uart->setup(baudclocks);

	tb->opentrace("helloworld.vcd");	
	
	for (unsigned clocks = 0; clocks < 16*24*baudclocks; clocks++) {
		tb->tick();
		(*uart)(tb->m_core->uart);
	}

	printf("\nSimulation ended\n");
	tb->closetrace();
        return 0;
}



