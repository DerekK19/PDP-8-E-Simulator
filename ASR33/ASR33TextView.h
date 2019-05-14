/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	ASR33TextView.h - NSTextView for the ASR 33 Teletype
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
 

@class TypeaheadBuffer;


@interface ASR33TextView : NSTextView
{
@private
	IBOutlet TypeaheadBuffer	*typeaheadBuffer;
}

- (void) putChar:(unichar)c;

@end
