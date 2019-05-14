/*
 *	PDP-8/E Simulator
 *
 *	Copyright © 1994-2018 Bernhard Baehr
 *
 *	PC8E.m - PC8-E Paper Tape Reader and Punch for the PDP-8/E Simulator
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
#import <mach/mach_time.h>

#import "PluginFramework/PluginAPI.h"
#import "PluginFramework/PDP8.h"
#import "PluginFramework/Utilities.h"
#import "PluginFramework/RegisterTextField.h"
#import "PluginFramework/KeepInMenuWindow.h"
#import "FileDropControlTargetProtocol.h"
#import "PluginFramework/PaperTapeController.h"

#define USE_PC8E_REGISTERS_DIRECTLY 1

#import "PC8E.h"
#import "PC8Eiot.h"


#define CODER_KEY_RBF		@"rbf"
#define CODER_KEY_PBF		@"pbf"
#define CODER_KEY_INFLAG	@"inflag"
#define CODER_KEY_INMASK	@"inmask"
#define CODER_KEY_OUTFLAG	@"outflag"
#define CODER_KEY_OUTMASK	@"outmask"

#define NO_OUTPUT		0
#define OUTPUT			1
#define NO_INPUT		0
#define INPUT			1

#define READER_CONTINUOUS_DELAY	3333333ull	// nanosec. * 300 = 1 sec. => delay for 300 char/sec.
#define READER_STARTSTOP_DELAY	40000000ull	// nanosec. * 25 = 1 sec. => delay for 25 char/sec.
#define PUNCH_DELAY		20000000ull	// nanosec. * 50 = 1 sec. => delay for 50 char/sec.
#define STOP_DELAY		6000000ull	// "stop delay" occurs 6 ms after RFC


@implementation PC8E


API_VERSION


#pragma mark Plugin Methods


- (NSArray *) iotsForAddress:(unsigned short)ioAddress
{
	return ioAddress == 01 ?
		[NSArray arrayWithObjects:
			[NSValue valueWithPointer:i6010],
			[NSValue valueWithPointer:i6011],
			[NSValue valueWithPointer:i6012],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:i6014],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:i6016],
			[NSValue valueWithPointer:nil],
			nil] :
		[NSArray arrayWithObjects:
			[NSValue valueWithPointer:i6020],
			[NSValue valueWithPointer:i6021],
			[NSValue valueWithPointer:i6022],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:i6024],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:i6026],
			[NSValue valueWithPointer:nil],
			nil];
}


- (NSArray *) skiptestsForAddress:(unsigned short)ioAddress
{
	return ioAddress == 01 ?
		[NSArray arrayWithObjects:
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:s6011],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			nil] :
		[NSArray arrayWithObjects:
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:s6021],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			[NSValue valueWithPointer:nil],
			nil];
}


- (void) setIOFlag:(unsigned long)flag forIOFlagName:(NSString *)name;
{
	if (inflag)
		outflag = flag;
	else
		inflag = flag;
}


- (void) CAF:(int)ioAddress
{
	if (ioAddress == 01) {		// CAF is called twice, ignore second call (01 == reader I/O address)
		RBF = 0;
		PBF = 0;		
		[pdp8 setInterruptMaskBits:inflag | outflag];
		[pdp8 clearIOFlagBits:inflag | outflag];
	}
}


- (void) clearAllFlags:(int)ioAddress
{
	if (ioAddress == 01)		// CAF is called twice, ignore second call (01 == reader I/O address)
		[self resetDevice];
}


- (void) resetDevice
{
	[self setRBF:0];
	[self setPBF:0];
	[pdp8 setInterruptMaskBits:inflag | outflag];
	[pdp8 clearIOFlagBits:inflag | outflag];
}


#pragma mark Thread Handling


- (void) realtimeDelay:(uint64_t)matStartTime lastStart:(uint64_t)matLastStartTime
{
	int speed = [pdp8 getGoSpeed];
	if (speed != GO_AS_FAST_AS_POSSIBLE) {
		uint64_t delay;
		if (matLastStartTime == 0)		// punch with 50 cps
			delay = PUNCH_DELAY;
		else {					// reader
			uint64_t delta = absolute2nanoseconds(matStartTime - matLastStartTime);
			if (delta > READER_STARTSTOP_DELAY)	// next char already buffered
				delay = 0;		
			else 
			if (delta > STOP_DELAY)			// start stop mode with 25 cps
				delay = READER_STARTSTOP_DELAY;
			else					// continuous read with 300 cps
				delay = READER_CONTINUOUS_DELAY;
		}
		if (speed == GO_WITH_PDP8_SPEED)
			mach_wait_until (matStartTime + nanoseconds2absolute(delay));
		else {
			while (mach_absolute_time() < matStartTime + nanoseconds2absolute(delay))
				;
		}
	}
}


- (void) canContinueInput
{
	if ([inputLock tryLockWhenCondition:NO_INPUT])
		[inputLock unlockWithCondition:INPUT];
#if ! defined(NS_BLOCK_ASSERTIONS)
	else
		NSLog (@"PDP-8 software bug: RFC or RCC executed before preceding tape read finished");
#endif
}


- (void) canContinueOutput
{
	if ([outputLock tryLockWhenCondition:NO_OUTPUT])
		[outputLock unlockWithCondition:OUTPUT];
#if ! defined(NS_BLOCK_ASSERTIONS)
	else
		NSLog (@"PDP-8 software bug: PPC or PLS executed before preceding tape punch finished");
#endif
}


- (void) pc8eReaderThread:(id)object
{
	[[NSAutoreleasePool alloc] init];
	uint64_t matStartTime = mach_absolute_time();
	uint64_t matLastStartTime;
	for (;;) {
		[inputLock lockWhenCondition:INPUT];
		matLastStartTime = matStartTime;
		matStartTime = mach_absolute_time();
		input = [reader getChar];
		if (input != EOF)
			[self setRBF:input & 0377];	// strip off Unicode characters etc.
		[inputLock unlockWithCondition:NO_INPUT];
		[self realtimeDelay:matStartTime lastStart:matLastStartTime];
		if (input != EOF)
			[pdp8 setIOFlagBits:inflag];
	}
}


- (void) pc8ePunchThread:(id)object
{
	[[NSAutoreleasePool alloc] init];
	for (;;) {
		[outputLock lockWhenCondition:OUTPUT];
		uint64_t matStart = mach_absolute_time();
		[self setPBF:output];
		BOOL done = [punch putChar:(unsigned char) output handleBackspace:NO];
		[outputLock unlockWithCondition:NO_OUTPUT];
		[self realtimeDelay:matStart lastStart:0];
		if (done)
			[pdp8 setIOFlagBits:outflag];
	}
}


#pragma mark Register Access


- (unsigned short) getRBF
{
	return RBF;
}


- (void) notifyRBF
{
	NSAssertRunningOnMainThread ();
	[[NSNotificationCenter defaultCenter] postNotificationName:RBF_CHANGED_NOTIFICATION object:self];
	
}


- (void) setRBF:(unsigned short)rbf
{
	NSAssert1 ((rbf & ~0377) == 0, @"Bad RBF: 0%o", rbf);
	RBF = rbf;
	if ([NSThread isMainThread])
		[[NSNotificationCenter defaultCenter]
			postNotificationName:RBF_CHANGED_NOTIFICATION object:self];
	else
		[self performSelectorOnMainThread:@selector(notifyRBF) withObject:self waitUntilDone:NO];
}


- (unsigned short) getPBF
{
	return PBF;
}


- (void) notifyPBF
{
	NSAssertRunningOnMainThread ();
	[[NSNotificationCenter defaultCenter] postNotificationName:PBF_CHANGED_NOTIFICATION object:self];
	
}


- (void) setPBF:(unsigned short)pbf
{
	NSAssert1 ((pbf & ~0377) == 0, @"Bad PBF: 0%o", pbf);
	PBF = pbf;
	if ([NSThread isMainThread])
		[[NSNotificationCenter defaultCenter]
			postNotificationName:PBF_CHANGED_NOTIFICATION object:self];
	else
		[self performSelectorOnMainThread:@selector(notifyPBF) withObject:self waitUntilDone:NO];
}


#pragma mark Notifications


- (void) notifyApplicationWillTerminate:(NSNotification *)notification
{
	// NSLog (@"PC8E notifyApplicationWillTerminate");
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification
		object:nil];
	NSMutableData *data = [NSMutableData data];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[self encodeWithCoder:archiver];
	[archiver finishEncoding];
	[archiver release];
	[[NSUserDefaults standardUserDefaults] setObject:data forKey:[self pluginName]];
}


- (void) notifyPluginsLoaded:(NSNotification *)notification
{
	[window orderBackFromDefaults:self];
}


#pragma mark Initialization


- (id) initWithCoder:(NSCoder *)coder
{
	self = [super init];
	[self setRBF:(unsigned short) [coder decodeIntForKey:CODER_KEY_RBF]];
	[self setPBF:(unsigned short) [coder decodeIntForKey:CODER_KEY_PBF]];
	[coder decodeBoolForKey:CODER_KEY_INFLAG] ?
		[pdp8 setIOFlagBits:inflag] : [pdp8 clearIOFlagBits:inflag];
	[coder decodeBoolForKey:CODER_KEY_INMASK] ?
		[pdp8 setInterruptMaskBits:inflag] : [pdp8 clearInterruptMaskBits:inflag];
	[coder decodeBoolForKey:CODER_KEY_OUTFLAG] ?
		[pdp8 setIOFlagBits:outflag] : [pdp8 clearIOFlagBits:outflag];
	[coder decodeBoolForKey:CODER_KEY_OUTMASK] ?
		[pdp8 setInterruptMaskBits:outflag] : [pdp8 clearInterruptMaskBits:outflag];
	return self;
}


- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:[self getRBF] forKey:CODER_KEY_RBF];
	[coder encodeInt:[self getPBF] forKey:CODER_KEY_PBF];
	[coder encodeBool:[pdp8 getIOFlagBits:inflag] ? YES : NO forKey:CODER_KEY_INFLAG];
	[coder encodeBool:[pdp8 getInterruptMaskBits:inflag] ? YES : NO forKey:CODER_KEY_INMASK];
	[coder encodeBool:[pdp8 getIOFlagBits:outflag] ? YES : NO forKey:CODER_KEY_OUTFLAG];
	[coder encodeBool:[pdp8 getInterruptMaskBits:outflag] ? YES : NO forKey:CODER_KEY_OUTMASK];
}


- (void) pluginDidLoad
{
	[rbfCell setupRegisterFor:self getRegisterValue:@selector(getRBF) setRegisterValue:@selector(setRBF:)
		changedNotificationName:RBF_CHANGED_NOTIFICATION mask:0377 base:8];
	[pbfCell setupRegisterFor:self getRegisterValue:@selector(getPBF) setRegisterValue:@selector(setPBF:)
		changedNotificationName:PBF_CHANGED_NOTIFICATION mask:0377 base:8];
	NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:[self pluginName]];
	if (data) {
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		self = [self initWithCoder:unarchiver];
		[unarchiver finishDecoding];
		[unarchiver release];
	} else
		[self resetDevice];
	inputLock = [[NSConditionLock alloc] initWithCondition:NO_INPUT];
	outputLock = [[NSConditionLock alloc] initWithCondition:NO_OUTPUT];
	[NSThread detachNewThreadSelector:@selector(pc8eReaderThread:) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(pc8ePunchThread:) toTarget:self withObject:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyApplicationWillTerminate:)
		name:NSApplicationWillTerminateNotification object:nil]; 
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(notifyPluginsLoaded:)
		name:PLUGINS_LOADED_NOTIFICATION object:nil];
}


@end
