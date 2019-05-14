/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	PC8E.h - PC8-E Paper Tape Reader and Punch for the PDP-8/E Simulator
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


#define RBF_CHANGED_NOTIFICATION	@"pc8eReaderBufferChangedNotification"
#define PBF_CHANGED_NOTIFICATION	@"pc8ePunchBufferChangedChangedNotification"


@class NSCondition, KeepInMenuWindow, RegisterTextField, PaperTapeController;


@interface PC8E : PDP8Plugin <NSCoding>
{
@public
/* The attributes are public, so the C functions implementing the PDP-8 instructions can
   access them directly. No other Cocoa code should use them directly. To ensure this,
   the register names are mapped to dummy names with the #defines below. In the source
   codes files with the instruction C functions, #define USE_PC8E_REGISTERS_DIRECTLY
   to make the registers available. */
	unsigned short				RBF;
	unsigned long				inflag;
	unsigned long				outflag;
	unsigned short				output;
@private
	unsigned short				PBF;		// private: not accessed by IOTs
	int					input;		// int: can be EOF == -1
	IBOutlet KeepInMenuWindow		*window;
	IBOutlet RegisterTextField		*rbfCell;
	IBOutlet RegisterTextField		*pbfCell;
	IBOutlet PaperTapeController		*reader;
	IBOutlet PaperTapeController		*punch;
	NSConditionLock				*inputLock;
	NSConditionLock				*outputLock;
}

- (void) canContinueInput;
- (void) canContinueOutput;
- (unsigned short) getRBF;
- (void) setRBF:(unsigned short)rbf;
- (unsigned short) getPBF;
- (void) setPBF:(unsigned short)pbf;

@end


#if ! USE_PC8E_REGISTERS_DIRECTLY
#define RBF		__dont_use_RBF__
#define PBF		__dont_use_PBF__
#define inflag		__dont_use_inflag__
#define outflag		__dont_use_outflag__
#define input		__dont_use_input__
#define output		__dont_use_output__
#endif
