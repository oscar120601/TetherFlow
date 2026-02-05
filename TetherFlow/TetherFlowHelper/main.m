//
//  main.m
//  TetherFlowHelper
//
//  Privileged helper tool entry point
//

#import <Foundation/Foundation.h>
#import "Helper.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSLog(@"[TetherFlowHelper] Starting up...");
        
        // Create and register the helper service
        Helper *helper = [[Helper alloc] init];
        
        // Get the XPC listener
        NSXPCListener *listener = [NSXPCListener serviceListener];
        listener.delegate = helper;
        
        NSLog(@"[TetherFlowHelper] XPC listener registered, waiting for connections...");
        
        // Start listening for connections
        [listener resume];
        
        // Keep the helper running
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
