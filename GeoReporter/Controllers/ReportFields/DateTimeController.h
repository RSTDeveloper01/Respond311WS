//
//  DateTimeController.h
//  RESPOND
//
//  Created by RSTDeveloper01 on 8/22/13.
//  Copyright (c) 2013 Rock Solid Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DateValueDelegate.h"

@interface DateTimeController : UIViewController
@property (strong, nonatomic) NSDictionary *attribute;
@property (strong, nonatomic) NSString *currentValue;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIDatePicker *picker;
@property id<DateEntryDelegate>delegate;
- (IBAction)done:(id)sender;
@end


