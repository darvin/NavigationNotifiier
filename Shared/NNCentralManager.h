//
//  NNCentralManager.h
//  Client
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNConnectionManager.h"

@interface NNCentralManager : NNConnectionManager
- (void)disconnect;
@end
