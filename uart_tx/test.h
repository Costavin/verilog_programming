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

#include <stdio.h>
#include <stdint.h>
#include <verilated_vcd_c.h>


template <class T>
class TESTB {
	public:
        	T		*m_core;
		VerilatedVcdC	*m_trace;
	        uint64_t        m_tickcount;

        	TESTB(void) : m_trace(NULL), m_tickcount(0l) {
                	m_core = new T;
	                Verilated::traceEverOn(true);
        	        m_core->clk = 0;
                	eval(); // Get our initial values set properly.
        	}
	        virtual ~TESTB(void) {
        		closetrace();
			m_core = NULL;
        	}

        	virtual void opentrace(const char *vcdname) {
                	if (!m_trace) {
                        	m_trace = new VerilatedVcdC;
                        	m_core->trace(m_trace, 99);
                        	m_trace->open(vcdname);
                	}
        	}

	        virtual void closetrace(void) {
        	        if (m_trace) {
                	        m_trace->close();
                        	delete m_trace;
	                        m_trace = NULL;
        	        }
        	}

	        virtual void eval(void) {
        	        m_core->eval();
        	}

	        virtual void tick(void) {
        	        m_tickcount++;
	                if (m_trace) m_trace->dump((vluint64_t)(10*m_tickcount-2));
        	        m_core->clk = 1;
               		eval();
	                if (m_trace) m_trace->dump((vluint64_t)(10*m_tickcount));
        	        m_core->clk = 0;
                	eval();
	                if (m_trace) {
        	                m_trace->dump((vluint64_t)(10*m_tickcount+5));
                	        m_trace->flush();
                	}
	        }

	        unsigned long tickcount(void) {
        	        return m_tickcount;
	        }
};


