//
//  DateValueDelegate.h
//  RESPOND
//
//  Created by RSTDeveloper01 on 9/10/13.
//  Copyright (c) 2013 Rock Solid Technologies. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol DateEntryDelegate <NSObject>
@required
- (void)didProvideDateValue:(NSDate *)value;
@end
