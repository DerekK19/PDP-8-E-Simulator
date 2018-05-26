/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2015 Bernhard Baehr
 *
 *	PC8Eiot.c - PC8-E Paper Tape Reader & Punch IOTs
 *
 *	This file is part of PDP-8/E Simulator.
 *
 *	PDP-8/E Simulator is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#import <Cocoa/Cocoa.h>

#define USE_PC8E_REGISTERS_DIRECTLY 1
#define USE_PDP8_REGISTERS_DIRECTLY 1

#import "PluginFramework/PluginAPI.h"
#import "PluginFramework/PDP8.h"

#import "PC8E.h"
#import "PC8Eiot.h"


void i6010 (void)				/* RPE		6010	*/
{
	pdp8->IMASK |= PLUGIN_POINTER(PC8E)->inflag | PLUGIN_POINTER(PC8E)->outflag;
	EXECUTION_TIME (12);
}


void i6011 (void)				/* RSF		6011	*/
{
	if (pdp8->IOFLAGS & PLUGIN_POINTER(PC8E)->inflag)
		pdp8->PC++;
	EXECUTION_TIME (12);
}


unsigned s6011 (void)				/* RSF		6011	skiptest */
{
	return pdp8->IOFLAGS & PLUGIN_POINTER(PC8E)->inflag;
}


void i6012 (void)				/* RRB		6012	*/
{
	pdp8->AC |= PLUGIN_POINTER(PC8E)->RBF;
	pdp8->IOFLAGS &= ~PLUGIN_POINTER(PC8E)->inflag;
	EXECUTION_TIME (12);
}


void i6014 (void)				/* RFC		6014	*/
{
	pdp8->IOFLAGS &= ~PLUGIN_POINTER(PC8E)->inflag;
	[PLUGIN_POINTER(PC8E) canContinueInput];
	EXECUTION_TIME (12);
}


void i6016 (void)				/* RCC		6016	*/
{
	pdp8->AC |= PLUGIN_POINTER(PC8E)->RBF;
	i6014 ();
}


void i6020 (void)				/* PCE		6020	*/
{
	pdp8->IMASK &= ~(PLUGIN_POINTER(PC8E)->inflag | PLUGIN_POINTER(PC8E)->outflag);
	EXECUTION_TIME (12);
}


void i6021 (void)				/* PSF		6021	*/
{
	if (pdp8->IOFLAGS & PLUGIN_POINTER(PC8E)->outflag)
		pdp8->PC++;
	EXECUTION_TIME (12);
}


unsigned s6021 (void)				/* PSF		6021	skiptest */
{
	return pdp8->IOFLAGS & PLUGIN_POINTER(PC8E)->outflag;
}


void i6022 (void)				/* PCF		6022	*/
{
	pdp8->IOFLAGS &= ~PLUGIN_POINTER(PC8E)->outflag;
	PLUGIN_POINTER(PC8E)->output = 0;
	EXECUTION_TIME (12);
}


void i6024 (void)				/* PPC		6024	*/
{
	PLUGIN_POINTER(PC8E)->output |= pdp8->AC & 0377;
	[PLUGIN_POINTER(PC8E) canContinueOutput];
	EXECUTION_TIME (12);
}


void i6026 (void)				/* PLS		6026	*/
{
	pdp8->IOFLAGS &= ~PLUGIN_POINTER(PC8E)->outflag;
	PLUGIN_POINTER(PC8E)->output = pdp8->AC & 0377;
	[PLUGIN_POINTER(PC8E) canContinueOutput];
	EXECUTION_TIME (12);
}
