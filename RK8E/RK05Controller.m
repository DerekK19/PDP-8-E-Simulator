/*
 *    PDP-8/E Simulator
 *
 *    Copyright © 1994-2015 Bernhard Baehr
 *
 *    RK05Controller.m - Controller for RK05 view
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

#import "PluginFramework/PluginAPI.h"
#import "PluginFramework/Utilities.h"
#import "PluginFramework/Unicode.h"
#import "PluginFramework/NSControl+FileDrop.h"
#import "PluginFramework/FileDropControlTargetProtocol.h"

#import "RK05Controller.h"
#import "RK05.h"


#define DECPACK_HFS_TYPE_CODE        0x524b3845l    // 'RK8E', for compatibility with the old simulator
#define DECPACK_EXTENSION_RK05        @"rk05"
#define DECPACK_EXTENSION_DECPACK    @"decpack"

#define CODER_KEY_RK05_PATH_FMT        @"rk05path%d"
#define CODER_KEY_RK05_LOCK_FMT        @"rk05lock%d"


@implementation RK05Controller


- (IBAction) writeProtectClicked:(id)sender
{
    [rk05 setWriteProtected:[sender intValue]];
}


- (void) notifyWriteProtectChanged:(NSNotification *)notification
{
    // NSLog (@"RK05Controller notifyWriteProtectChanged");
    [writeProtectCheckbox setIntValue:[rk05 isWriteProtected]];
}


- (void) updateMountButton:(NSString *)path
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    if (path) {
        decpackPath = path;
        [filenameField setStringValue:[[NSFileManager defaultManager] displayNameAtPath:path]];
        [filenameField setHidden:NO];
        [mountUnmountButton setTitle:
            NSLocalizedStringFromTableInBundle(@"Unmount", nil, bundle, @"")];
        [mountUnmountButton unregisterAsFileDropTarget];
    } else {
        [mountUnmountButton setTitle:
            NSLocalizedStringFromTableInBundle(@"Mount", nil, bundle, @"")];
        [mountUnmountButton registerAsFileDropTarget];
        [filenameField setHidden:YES];
        decpackPath = nil;
    }
}


- (BOOL) mount:(NSString *)path create:(BOOL)create
{
    int err = [rk05 mount:path create:create];
    if (err) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:err == -1 ?
            (create ?
                NSLocalizedStringFromTableInBundle(
                    @"Cannot create this DECpack.", nil, bundle, @"") :
                NSLocalizedStringFromTableInBundle(
                    @"Cannot mount this DECpack, maybe it is write protected.",
                    nil, bundle, @"")) :
            NSLocalizedStringFromTableInBundle(
            @"This DECpack is already mounted to another RK05 drive.", nil, bundle, @"")
        ];
        [alert setInformativeText:path];
        [alert beginSheetModalForWindow:[mountUnmountButton window] completionHandler:^(NSModalResponse returnCode) { }];
    } else
        [self updateMountButton:path];
    return err == 0;
}


- (void) panelDidEnd:(NSSavePanel *)panel result:(NSModalResponse)result
{
    if (result == NSModalResponseOK) {
        [panel close];
        [self mount:[[panel URL] path] create:[panel isMemberOfClass:[NSSavePanel class]]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[[panel directoryURL] path] forKey:LAST_FILE_PANEL_DIR_KEY];
}


- (NSArray *) openFileTypes
{
    return [NSArray arrayWithObjects:DECPACK_EXTENSION_RK05, DECPACK_EXTENSION_DECPACK,
        NSFileTypeForHFSTypeCode(DECPACK_HFS_TYPE_CODE), nil];
}


- (IBAction) mountUnmountClicked:(id)sender
{
    if ([rk05 isMounted]) {
        if ([rk05 unmount]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedStringFromTableInBundle(
                @"An error occured while closing the DECpack. "
                "The data on that DECpack might be corrupt.", nil,
                [NSBundle bundleForClass:[self class]], @"")];
            [alert setInformativeText:[filenameField stringValue]];
            [alert beginSheetModalForWindow:[mountUnmountButton window] completionHandler:^(NSModalResponse returnCode) { }];
        }
        [self updateMountButton:nil];
    } else {
        if ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagOption) {
            NSSavePanel *savePanel = [NSSavePanel savePanel];
            [savePanel setDirectoryURL: [NSURL fileURLWithPath: [[NSUserDefaults standardUserDefaults] stringForKey:LAST_FILE_PANEL_DIR_KEY] isDirectory: YES]];
            [savePanel setAllowedFileTypes: [NSArray arrayWithObject:@"rk05"]];
            [savePanel beginSheetModalForWindow:[mountUnmountButton window]
                              completionHandler:^(NSModalResponse result) {
                [self panelDidEnd:savePanel result:result];
            }];
        } else {
            NSOpenPanel *openPanel = [NSOpenPanel openPanel];
            [openPanel setDirectoryURL: [NSURL fileURLWithPath: [[NSUserDefaults standardUserDefaults] stringForKey:LAST_FILE_PANEL_DIR_KEY] isDirectory: YES]];
            [openPanel setAllowedFileTypes: [self openFileTypes]];
            [openPanel beginSheetModalForWindow:[mountUnmountButton window]
                              completionHandler:^(NSModalResponse result) {
                                  [self panelDidEnd:openPanel result:result];
                              }];
        }
//        [nsUrl autorelease];
    }
}


- (void) setDecpackPathAndMountAtStartup:(NSString *)path
{
    if (path == nil)
        return;
    if ([rk05 mount:path create:NO]) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(
            @"The following DECpack could not be found. It was mounted on RK05 drive %d. "
            "Do you want to locate it?", nil, bundle, @""), [rk05 driveNumber]]];
        [alert setInformativeText:path];
        [[alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Yes", nil, bundle, @"")]
            setKeyEquivalent:@"\r"];
        [[alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"No", nil, bundle, @"")]
            setKeyEquivalent:@"\e"];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            [panel setTitle:[NSString stringWithFormat:
                NSLocalizedStringFromTableInBundle(@"Locate the DECpack %C%@%C",
                    nil, bundle, @""),
                    UNICODE_LEFT_DOUBLEQUOTE,
                    [[NSFileManager defaultManager] displayNameAtPath:path],
                    UNICODE_RIGHT_DOUBLEQUOTE]];
            [panel setDirectoryURL: [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] stringForKey:LAST_FILE_PANEL_DIR_KEY] isDirectory: YES]];
            [panel setAllowedFileTypes: [self openFileTypes]];
            if ([panel runModal] == NSModalResponseOK)
                [self mount:[[panel URL] path] create:NO];
            [[NSUserDefaults standardUserDefaults]
                setObject:[[panel directoryURL] path] forKey:LAST_FILE_PANEL_DIR_KEY];
        }
    } else
        [self updateMountButton:path];
}


#pragma mark FileDropControlTarget Protocol


- (BOOL) willAcceptFile:(NSString *)path
{
    NSString *extension = [path pathExtension];
    if ([extension isEqualToString:DECPACK_EXTENSION_RK05] ||
        [extension isEqualToString:DECPACK_EXTENSION_DECPACK] ||
        [NSHFSTypeOfFile(path) isEqualToString:NSFileTypeForHFSTypeCode(DECPACK_HFS_TYPE_CODE)]) {
        return [rk05 canMount:path];
    }
    return NO;
}


- (BOOL) acceptFile:(NSString *)path
{
    return [self mount:path create:NO];
}


#pragma mark Initialization


- (id) initWithCoder:(NSCoder *)coder
{
    self = [super init];
    [self loadCoder:coder];
    return self;
}

- (void) loadCoder:(NSCoder *)coder
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyWriteProtectChanged:)
                                                 name:WRITEPROTECT_CHANGED_NOTIFICATION object:nil];
    [mountUnmountButton registerAsFileDropTarget];
    if (runningOnLionOrNewer()) {
        // Make the textured button a normal push button of the same size, otherwise
        // the label is not centered vertically and aligned with the "Write Proctect" label
        NSRect rect = [mountUnmountButton frame];
        [mountUnmountButton setBezelStyle:NSRoundedBezelStyle];
        [mountUnmountButton setFrame:NSInsetRect(NSOffsetRect(rect, 0, -1), -5, -2)];
    }
    int drive = (int)([mountUnmountButton tag]);
    [rk05 setDriveNumber:drive];
    [self setDecpackPathAndMountAtStartup:
     [coder decodeObjectForKey:[NSString stringWithFormat:CODER_KEY_RK05_PATH_FMT, drive]]];
    [rk05 setWriteProtected:
     [coder decodeBoolForKey:[NSString stringWithFormat:CODER_KEY_RK05_LOCK_FMT, drive]]];
}

- (void) encodeWithCoder:(NSCoder *)coder
{
    int drive = [rk05 driveNumber];
    [coder encodeObject:decpackPath forKey:
        [NSString stringWithFormat:CODER_KEY_RK05_PATH_FMT, drive]];
    [coder encodeBool:[rk05 isWriteProtected] forKey:
        [NSString stringWithFormat:CODER_KEY_RK05_LOCK_FMT, drive]];
    [rk05 flush];
}


@end
