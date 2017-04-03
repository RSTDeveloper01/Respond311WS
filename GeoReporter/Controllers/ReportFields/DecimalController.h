//
//  NumberController.h
//  RESPOND
//
//  Created by RSTDeveloper01 on 8/28/13.
//  Copyright (c) 2013 Rock Solid Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextEntryDelegate.h"

@interface DecimalController : UIViewController
@property (strong, nonatomic) NSDictionary *attribute;
@property (strong, nonatomic) NSString *currentValue;
@property id<TextEntryDelegate>delegate;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *textField;
- (IBAction)done:(id)sender;
@end
