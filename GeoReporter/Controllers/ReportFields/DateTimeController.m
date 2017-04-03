//
//  DateTimeController.m
//  RESPOND
//
//  Created by RSTDeveloper01 on 8/22/13.
//  Copyright (c) 2013 Rock Solid Technologies. All rights reserved.
//

#import "DateTimeController.h"
#import "Strings.h"

@interface DateTimeController ()

@end

@implementation DateTimeController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.label.text = self.attribute[kOpen311_Description];
}

// Pre-select the |currentValue|
//
// Because of AutoLayout, we cannot change the picker's selection
// until after it has appeared.  Doing this in |viewWillAppear|
// will not work.
- (void)viewDidAppear:(BOOL)animated
{
}

- (void) viewWillDisappear:(BOOL)animated{
    NSLocale *usLocale = [[NSLocale alloc]
                           initWithLocaleIdentifier:@"en_US"];
    NSDate *pickerDate = [_picker date];
    NSObject *key = [[NSString alloc] initWithFormat:@"%@",
                     [pickerDate descriptionWithLocale:nil]];
    
    [self.delegate didProvideDateValue:pickerDate];
}

- (IBAction)done:(id)sender
{
    // Some servers use non-string keys.
    // We need to convert them to strings before saving them.
    // If they were unique to begin with, they should still be unique
    // after string conversion.
    NSLocale *usLocale = [[NSLocale alloc]
                           initWithLocaleIdentifier:@"en_US"];
    
    NSDate *pickerDate = [_picker date];
   NSObject *key = [[NSString alloc] initWithFormat:@"%@",
                                 [pickerDate descriptionWithLocale:usLocale]];
        
    [self.delegate didProvideDateValue:(NSString *)pickerDate];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
