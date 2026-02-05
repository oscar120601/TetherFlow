//
//  Helper.h
//  TetherFlowHelper
//
//  Privileged helper tool implementation
//

#import <Foundation/Foundation.h>
#import "HelperProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface Helper : NSObject <NSXPCListenerDelegate, HelperProtocol>

@end

NS_ASSUME_NONNULL_END
