//
//  NetworkModifier.h
//  TetherFlowHelper
//
//  C-level network parameter modification wrappers
//

#ifndef NetworkModifier_h
#define NetworkModifier_h

#include <sys/types.h>

// MARK: - TTL Operations

/**
 * Set the system-wide IP TTL (Time To Live) value.
 *
 * @param ttl The TTL value to set (typically 65 for cloaking, 64 for default)
 * @return 0 on success, non-zero on failure
 */
int set_ttl(int ttl);

/**
 * Get the current system-wide IP TTL value.
 *
 * @return The current TTL value, or -1 on error
 */
int get_current_ttl(void);

// MARK: - MTU Operations

/**
 * Set the MTU for a specific network interface.
 *
 * @param interface The interface name (e.g., "en0")
 * @param mtu The MTU value to set
 * @return 0 on success, non-zero on failure
 */
int set_mtu(const char *interface, int mtu);

/**
 * Get the current MTU for a specific network interface.
 *
 * @param interface The interface name (e.g., "en0")
 * @return The current MTU value, or -1 on error
 */
int get_current_mtu(const char *interface);

// MARK: - Utility Functions

/**
 * Execute a shell command with elevated privileges.
 *
 * @param command The command to execute
 * @return The command's exit status
 */
int execute_command(const char *command);

#endif /* NetworkModifier_h */
