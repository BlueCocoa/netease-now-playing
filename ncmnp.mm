//
//  ncmnp.mm
//  ncmnp
//
//  Created by Cocoa on 05/02/2020.
//  Copyright © 2020 Cocoa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#include <unistd.h>

#define PYTHON_INTERPRETER "/usr/local/bin/python3"
#define PATHON_SCRIPT      "/Applications/NeteaseMusic.app/Contents/MacOS/script.py"

/// small header for YYYApp
@interface YYYApp : NSObject
+ (instancetype)sharedApplication;
- (void)setDockMenus;
@end

/// Netease Cloud Music Now Playing
@interface NCMNP : NSObject
@property (nonatomic, retain, nullable) NSString * songName;
@property (nonatomic, retain, nullable) NSString * artist;
@property (nonatomic, retain, nullable) NSString * album;
@end

// Netease Cloud Music Now Playing Instance
static NCMNP * neteaseNowPlayingWatcher = nil;
// `Class` variable of YYYApp
static Class YYYAppClass;
// Shared instance of YYYApp +[YYYApp sharedApplication]
static id YYYAppSharedApplication = nil;
// Original implementation of -[YYYApp setDockMenus]
static void(*orig)(id);
// Instance variables of YYYApp
static NSMenuItem * songNameMenuItem;
static NSMenuItem * artistAndAlbumMenuItem;

@implementation NCMNP
/// Observe value changes of `songNameMenuItem` and `artistAndAlbumMenuItem`
/// @param keyPath "title"
/// @param object `songNameMenuItem` or `artistAndAlbumMenuItem`
/// @param change unused
/// @param context unused
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == songNameMenuItem) {
        self.songName = [[songNameMenuItem title] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    } else if (object == artistAndAlbumMenuItem) {
        NSArray * artistAndAlbum = [[artistAndAlbumMenuItem title] componentsSeparatedByString:@" - "];
        self.artist = [artistAndAlbum[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        self.album = [artistAndAlbum[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    // if we have all three
    // then pass them to python script
    if (self.songName && self.artist && self.album) {
        const char * songName = [self.songName UTF8String];
        const char * artist = [self.artist UTF8String];
        const char * album = [self.album UTF8String];
        
        // basically copy and paste from Makito
        printf("Now playing:\n");
        printf("Song:   %s\n", songName);
        printf("Artist: %s\n", artist);
        printf("Album:  %s\n", album);
        
        
        
        int pid = fork();
        if (pid == -1) {
            fprintf(stderr, "failed to fork child process to call Python script\n");
        } else if (pid == 0) {
            char buf[4096];
            getcwd(buf, 4095);
            
            char * const args[] = {(char * const)PYTHON_INTERPRETER, (char * const)PATHON_SCRIPT, (char * const)buf, (char * const)artist, (char * const)album, 0};
            execve(PYTHON_INTERPRETER, args, NULL);
            exit(0);
        }
        
        // clean
        self.songName = nil;
        self.artist = nil;
        self.album = nil;
    }
}
@end

/// Our implementation of -[YYYApp setDockMenus]
static void hook(id self) {
    // call original implementation so that instance variable can be initialised
    orig(self);
    // do once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // get instance variables that we interested in
        songNameMenuItem = object_getIvar(YYYAppSharedApplication, class_getInstanceVariable(YYYAppClass, "_dockSongNameMenuItem"));
        artistAndAlbumMenuItem = object_getIvar(YYYAppSharedApplication, class_getInstanceVariable(YYYAppClass, "_dockArtistAndAlbumMenuItem"));
        
        // watch their "title" changes
        [songNameMenuItem addObserver:neteaseNowPlayingWatcher forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
        [artistAndAlbumMenuItem addObserver:neteaseNowPlayingWatcher forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    });
}

/// this constructor function will be invoked at loading
static void __attribute__((constructor))initializer(void) {
    // initialise global variables
    neteaseNowPlayingWatcher = [[NCMNP alloc] init];
    YYYAppClass = NSClassFromString(@"YYYApp");
    YYYAppSharedApplication = [YYYAppClass performSelector:@selector(sharedApplication)];
    
    // save old implementation of -[YYYApp setDockMenus]
    orig = (decltype(orig))class_getMethodImplementation(YYYAppClass, @selector(setDockMenus));
    // set new implementation of -[YYYApp setDockMenus]
    method_setImplementation(class_getInstanceMethod(YYYAppClass, @selector(setDockMenus)), (IMP)hook);
}
