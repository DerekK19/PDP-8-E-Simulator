/*
 *    PDP-8/E Simulator
 *
 *    Copyright © 1994-2015 Bernhard Baehr
 *
 *    RegisterFormCell.m - NSFormCell subclass for PDP-8/E registers
 *
 *    This file is part of PDP-8/E Simulator.
 *
 *    PDP-8/E Simulator is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#import <Cocoa/Cocoa.h>

#import "RegisterFormCell.h"
#import "OctalFormatter.h"
#import "Utilities.h"


@implementation RegisterFormCell


- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    if (command == @selector(cancelOperation:)) {
        // ESC aborts editing of the cell
        [control abortEditing];
        return YES;
    }
    return NO;
}


- (BOOL) control:(NSControl *)control didFailToFormatString:(NSString *)string
    errorDescription:(NSString *)error
{
    NSRange range;
    
    NSAlert *alert = [[NSAlert alloc] init];
        
    range.location = 0;
    range.length = -1;
    [[control currentEditor] setSelectedRange:range];
    [alert setMessageText:error];
    [alert beginSheetModalForWindow:[control window] completionHandler:^(NSModalResponse returnCode) { }];
    return NO;
}


- (void) controlTextDidEndEditing:(NSNotification *)notification
{
    if ([registerOwner respondsToSelector:setRegisterValue])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        unsigned int val = [self intValue];
        NSMethodSignature *signature = [registerOwner methodSignatureForSelector:setRegisterValue];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:setRegisterValue];
        [invocation setArgument:&val atIndex:2];
        [invocation invokeWithTarget:registerOwner];
#pragma clang diagnostic pop
    } else {
        NSLog(@"** Cannot performSelector:setRegisterValue");
    }
}


- (void) notifyRegisterHasChanged:(NSNotification *)notification
{
    if ([registerOwner respondsToSelector:getRegisterValue])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        unsigned int val = [registerOwner performSelector:getRegisterValue];
        [self setIntValue:val];
#pragma clang diagnostic pop
    } else {
        NSLog(@"** Cannot performSelector:getRegisterValue");
    }
}


- (void) setupRegisterFor:(id)owner getRegisterValue:(SEL)getter setRegisterValue:(SEL)setter
    changedNotificationName:(NSString *)notification
    mask:(unsigned)mask base:(short)base
{
    NSAssert (base == 8, @"Currently only base 8 is implemented for RegisterFormCell");
    [(NSForm *)[self controlView] setDelegate:self];
    [self setFormatter:[[OctalFormatter alloc] initWithBitMask:mask wildcardAllowed:NO]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyRegisterHasChanged:)
        name:notification object:nil];
    registerOwner = owner;
    getRegisterValue = getter;
    setRegisterValue = setter;
    if (runningOnYosemiteOrNewer()) {
        // with Helvetica Neue, the content digits are one pixel too small, so reset to Lucida Grande
        [self setFont:[NSFont fontWithName:@"LucidaGrande" size:11]];
        // with Helvetica Neue, many titles are too long and characters are clipped, so reset to Lucida Grande
        [self setTitleFont:[NSFont fontWithName:@"LucidaGrande" size:11]];
    }
}


@end
