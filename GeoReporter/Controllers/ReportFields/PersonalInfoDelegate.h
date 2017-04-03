//
//  PersonalInfoDelegate.h
//  RESPOND
//
//  Created by RSTDeveloper01 on 11/30/15.
//  Copyright (c) 2015 Rock Solid Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PersonalInfoDelegate <NSObject>
@required
- (void)personalInfoUpdated:(bool)value;
@end
