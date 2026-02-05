//
//  HelperProtocol.h
//  TetherFlow
//
//  XPC Protocol definition for communication between TetherFlow UI App
//  and TetherFlowHelper (Privileged Helper Tool)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Constants

// Bundle identifiers (must match app and helper Info.plist)
static NSString * const kHelperBundleIdentifier = @"com.tetherflow.helper";
static NSString * const kMainAppBundleIdentifier = @"com.tetherflow.app";

// XPC service name (must match launchd.plist)
static NSString * const kXPCServiceName = @"com.tetherflow.helper";

#pragma mark - Error Domain

static NSString * const kHelperErrorDomain = @"com.tetherflow.helper.error";

typedef NS_ENUM(NSInteger, HelperErrorCode) {
    HelperErrorCodeSuccess = 0,
    HelperErrorCodeInvalidParameters = 1,
    HelperErrorCodePermissionDenied = 2,
    HelperErrorCodeTTLModificationFailed = 3,
    HelperErrorCodeMTUModificationFailed = 4,
    HelperErrorCodeInterfaceNotFound = 5,
    HelperErrorCodeUnknown = 99
};

#pragma mark - Helper Protocol

/**
 * Protocol defining the interface between the main app and the privileged helper tool.
 * 
 * All methods are asynchronous and use reply blocks for results.
 * The helper tool runs with root privileges and modifies system network parameters.
 */
@protocol HelperProtocol <NSObject>

@required

/**
 * Apply network cloaking settings to the specified interface.
 *
 * @param ttl The Time To Live value to set (typically 65 to arrive as 64)
 * @param mtu The Maximum Transmission Unit to set (typically 1400 for mobile)
 * @param interface The network interface name (e.g., "en0", "en1")
 * @param reply Block called with result: YES on success, NO on failure
 *
 * This method:
 * 1. Sets the IP TTL using sysctl
 * 2. Sets the interface MTU using networksetup
 * 3. Applies traffic shaping rules using pfctl
 * 4. Configures encrypted DNS if requested
 *
 * Errors are logged to system log; use getCurrentTTLWithReply: to verify.
 */
- (void)applyCloakingWithTTL:(int)ttl
                         mtu:(int)mtu
                   interface:(NSString *)interface
                   withReply:(void (^)(BOOL success))reply;

/**
 * Reset network settings to system defaults.
 *
 * @param interface The network interface name (e.g., "en0", "en1")
 * @param reply Block called with result: YES on success, NO on failure
 *
 * This method:
 * 1. Restores default TTL (64)
 * 2. Restores default MTU (1500)
 * 3. Removes traffic shaping rules
 * 4. Reverts DNS configuration
 *
 * Should be called:
 * - When disconnecting from hotspot
 * - When user disables cloaking
 * - When emergency kill-switch activated
 */
- (void)resetNetworkSettingsWithInterface:(NSString *)interface
                                withReply:(void (^)(BOOL success))reply;

/**
 * Get the current system TTL value.
 *
 * @param reply Block called with current TTL value (64-255), or -1 on error
 *
 * Use this to verify cloaking is active (expecting 65 or configured value)
 * or has been properly reset (expecting 64).
 */
- (void)getCurrentTTLWithReply:(void (^)(int ttl))reply;

/**
 * Get the current MTU for a specific interface.
 *
 * @param interface The network interface name
 * @param reply Block called with current MTU, or -1 on error
 */
- (void)getCurrentMTUForInterface:(NSString *)interface
                        withReply:(void (^)(int mtu))reply;

/**
 * Apply traffic shaping rules to delay background traffic.
 *
 * @param enable YES to enable shaping, NO to disable
 * @param reply Block called with result: YES on success, NO on failure
 *
 * When enabled, this delays traffic to:
 * - Apple CDN (software updates)
 * - iCloud services (large syncs)
 * - App Store downloads
 */
- (void)applyTrafficShaping:(BOOL)enable
                  withReply:(void (^)(BOOL success))reply;

/**
 * Verify the helper tool is running and responsive.
 *
 * @param reply Block called with result: YES if healthy, NO if not responding
 *
 * Use this to check XPC connection status before operations.
 */
- (void)pingWithReply:(void (^)(BOOL isResponsive))reply;

@end

#pragma mark - Version Protocol

/**
 * Protocol for version checking between app and helper.
 * Ensures compatibility before operations.
 */
@protocol HelperVersionProtocol <NSObject>

/**
 * Get the helper tool version.
 *
 * @param reply Block called with version string (e.g., "1.0.0")
 */
- (void)getVersionWithReply:(void (^)(NSString *version))reply;

/**
 * Check if helper version is compatible with app version.
 *
 * @param appVersion The main app's version string
 * @param reply Block called with result: YES if compatible, NO if update needed
 */
- (void)checkCompatibilityWithAppVersion:(NSString *)appVersion
                               withReply:(void (^)(BOOL isCompatible))reply;

@end

#pragma mark - Audit Protocol

/**
 * Protocol for security auditing and logging.
 */
@protocol HelperAuditProtocol <NSObject>

/**
 * Get recent audit log entries.
 *
 * @param maxEntries Maximum number of entries to return (1-100)
 * @param reply Block called with array of log entry dictionaries
 *
 * Log entries contain:
 * - timestamp: ISO8601 date string
 * - operation: "applyCloaking", "resetNetwork", etc.
 * - interface: Network interface affected
 * - success: Boolean result
 * - sourcePID: Process ID of requesting app
 */
- (void)getRecentAuditLogs:(NSInteger)maxEntries
                 withReply:(void (^)(NSArray<NSDictionary *> *logs))reply;

@end

NS_ASSUME_NONNULL_END
