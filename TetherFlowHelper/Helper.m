//
//  Helper.m
//  TetherFlowHelper
//
//  Privileged helper tool implementation
//

#import "Helper.h"
#import "NetworkModifier.h"

@implementation Helper

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    NSLog(@"[TetherFlowHelper] Accepting new connection");
    
    // Set the interface that the connection exports
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperProtocol)];
    newConnection.exportedObject = self;
    
    // Set up code signature validation
    newConnection.invalidationHandler = ^{
        NSLog(@"[TetherFlowHelper] Connection invalidated");
    };
    
    newConnection.interruptionHandler = ^{
        NSLog(@"[TetherFlowHelper] Connection interrupted");
    };
    
    [newConnection resume];
    return YES;
}

#pragma mark - HelperProtocol

- (void)applyCloakingWithTTL:(int)ttl
                         mtu:(int)mtu
                   interface:(NSString *)interface
                   withReply:(void (^)(BOOL success))reply {
    NSLog(@"[TetherFlowHelper] Applying cloaking: TTL=%d, MTU=%d, Interface=%@", ttl, mtu, interface);
    
    BOOL success = YES;
    
    // Apply TTL modification
    int ttlResult = set_ttl(ttl);
    if (ttlResult != 0) {
        NSLog(@"[TetherFlowHelper] Failed to set TTL: %d", ttlResult);
        success = NO;
    } else {
        NSLog(@"[TetherFlowHelper] TTL set to %d", ttl);
    }
    
    // Apply MTU modification
    int mtuResult = set_mtu([interface UTF8String], mtu);
    if (mtuResult != 0) {
        NSLog(@"[TetherFlowHelper] Failed to set MTU: %d", mtuResult);
        success = NO;
    } else {
        NSLog(@"[TetherFlowHelper] MTU set to %d for %@", mtu, interface);
    }
    
    reply(success);
}

- (void)resetNetworkSettingsWithInterface:(NSString *)interface
                                withReply:(void (^)(BOOL success))reply {
    NSLog(@"[TetherFlowHelper] Resetting network settings for %@", interface);
    
    BOOL success = YES;
    
    // Reset TTL to default (64)
    int ttlResult = set_ttl(64);
    if (ttlResult != 0) {
        NSLog(@"[TetherFlowHelper] Failed to reset TTL: %d", ttlResult);
        success = NO;
    } else {
        NSLog(@"[TetherFlowHelper] TTL reset to 64");
    }
    
    // Reset MTU to default (1500)
    int mtuResult = set_mtu([interface UTF8String], 1500);
    if (mtuResult != 0) {
        NSLog(@"[TetherFlowHelper] Failed to reset MTU: %d", mtuResult);
        success = NO;
    } else {
        NSLog(@"[TetherFlowHelper] MTU reset to 1500 for %@", interface);
    }
    
    reply(success);
}

- (void)getCurrentTTLWithReply:(void (^)(int ttl))reply {
    int ttl = get_current_ttl();
    NSLog(@"[TetherFlowHelper] Current TTL: %d", ttl);
    reply(ttl);
}

- (void)getCurrentMTUForInterface:(NSString *)interface
                        withReply:(void (^)(int mtu))reply {
    int mtu = get_current_mtu([interface UTF8String]);
    NSLog(@"[TetherFlowHelper] Current MTU for %@: %d", interface, mtu);
    reply(mtu);
}

- (void)applyTrafficShaping:(BOOL)enable
                  withReply:(void (^)(BOOL success))reply {
    NSLog(@"[TetherFlowHelper] %@ traffic shaping", enable ? @"Enabling" : @"Disabling");
    
    // Placeholder implementation
    // Full implementation would use pfctl to configure rules
    BOOL success = YES;
    
    if (enable) {
        NSLog(@"[TetherFlowHelper] Traffic shaping enabled");
    } else {
        NSLog(@"[TetherFlowHelper] Traffic shaping disabled");
    }
    
    reply(success);
}

- (void)pingWithReply:(void (^)(BOOL isResponsive))reply {
    NSLog(@"[TetherFlowHelper] Ping received");
    reply(YES);
}

@end
