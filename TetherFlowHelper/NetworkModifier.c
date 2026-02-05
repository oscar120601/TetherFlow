//
//  NetworkModifier.c
//  TetherFlowHelper
//
//  C-level implementation for network parameter modification using sysctl
//

#include "NetworkModifier.h"
#include <sys/sysctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// MARK: - TTL Operations

int set_ttl(int ttl) {
    int mib[] = { CTL_NET, PF_INET, IPPROTO_IP, IPCTL_DEFTTL };
    size_t len = sizeof(ttl);
    
    int result = sysctl(mib, 4, NULL, NULL, &ttl, len);
    
    if (result != 0) {
        perror("[TetherFlowHelper] Failed to set TTL");
    }
    
    return result;
}

int get_current_ttl(void) {
    int mib[] = { CTL_NET, PF_INET, IPPROTO_IP, IPCTL_DEFTTL };
    int ttl = -1;
    size_t len = sizeof(ttl);
    
    int result = sysctl(mib, 4, &ttl, &len, NULL, 0);
    
    if (result != 0) {
        perror("[TetherFlowHelper] Failed to get TTL");
        return -1;
    }
    
    return ttl;
}

// MARK: - MTU Operations

// Note: MTU modification on macOS is typically done via networksetup command
// rather than direct sysctl, as it requires interface-specific handling

int set_mtu(const char *interface, int mtu) {
    // Validate parameters
    if (interface == NULL || strlen(interface) == 0) {
        fprintf(stderr, "[TetherFlowHelper] Invalid interface name\n");
        return -1;
    }
    
    if (mtu < 1280 || mtu > 9000) {
        fprintf(stderr, "[TetherFlowHelper] Invalid MTU value: %d\n", mtu);
        return -1;
    }
    
    // Use networksetup to set MTU
    // Format: networksetup -setMTU <interface> <mtu>
    char command[256];
    snprintf(command, sizeof(command), "/usr/sbin/networksetup -setMTU %s %d", interface, mtu);
    
    int result = execute_command(command);
    
    if (result != 0) {
        fprintf(stderr, "[TetherFlowHelper] Failed to set MTU for %s\n", interface);
    }
    
    return result;
}

int get_current_mtu(const char *interface) {
    // Validate parameters
    if (interface == NULL || strlen(interface) == 0) {
        fprintf(stderr, "[TetherFlowHelper] Invalid interface name\n");
        return -1;
    }
    
    // Use networksetup to get MTU
    // Format: networksetup -getMTU <interface>
    char command[256];
    snprintf(command, sizeof(command), "/usr/sbin/networksetup -getMTU %s", interface);
    
    FILE *fp = popen(command, "r");
    if (fp == NULL) {
        perror("[TetherFlowHelper] Failed to run networksetup");
        return -1;
    }
    
    char output[128];
    int mtu = -1;
    
    // Parse output: "Active MTU: 1500 (Current Setting: 1500)"
    while (fgets(output, sizeof(output), fp) != NULL) {
        if (sscanf(output, "Active MTU: %d", &mtu) == 1) {
            break;
        }
    }
    
    pclose(fp);
    
    return mtu;
}

// MARK: - Utility Functions

int execute_command(const char *command) {
    if (command == NULL) {
        return -1;
    }
    
    FILE *fp = popen(command, "r");
    if (fp == NULL) {
        perror("[TetherFlowHelper] Failed to execute command");
        return -1;
    }
    
    // Read and log output for debugging
    char output[1024];
    while (fgets(output, sizeof(output), fp) != NULL) {
        // Log output if needed (remove trailing newline)
        size_t len = strlen(output);
        if (len > 0 && output[len - 1] == '\n') {
            output[len - 1] = '\0';
        }
        // Uncomment for verbose logging:
        // printf("[TetherFlowHelper] Command output: %s\n", output);
    }
    
    int status = pclose(fp);
    return WEXITSTATUS(status);
}
