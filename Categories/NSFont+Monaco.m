/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	NSFont+Monaco.m - Category with class method to get the Monaco font
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

#import "NSFont+Monaco.h"


@implementation NSFont (Monaco)


+ (NSFont *) monaco11
{
#if __LP64__
	// With 64-bit, text drawn with [NSFont fontWithName:@"Monaco" size:11] has a smaller kerning,
	// most obvious in the memory inspector octal column when a multi-word format is selected.
	NSFontDescriptor *desc = [NSFontDescriptor fontDescriptorWithName:@"Monaco" size:11];
	desc = [desc fontDescriptorByAddingAttributes:
		[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:7] forKey:NSFontFixedAdvanceAttribute]];
	return [NSFont fontWithDescriptor:desc size:11];
#else
	return [NSFont fontWithName:@"Monaco" size:11];
#endif
}


@end
