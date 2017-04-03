/**
 * @copyright 2013 Rock Solid Technologies,Inc. All Rights Reserved
 * @author Cliff Ingham <inghamn@bloomington.in.gov>
 * @editor Samuel Rivera <srivera@rocksolid.com>
 * @license http://www.gnu.org/licenses/gpl.txt GNU/GPLv3, see LICENSE.txt
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

#import "SingleValueListController.h"
#import "Strings.h"

@interface SingleValueListController ()

@end

@implementation SingleValueListController

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
    if ([self.currentValue length] > 0) {
        NSArray *values = self.attribute[kOpen311_Values];
        int count = [values count];
        for (int i=0; i<count; i++) {
            // Some servers use non-string keys.
            // We need to convert them to strings before comparing them.
            // If they were unique to begin with, they should still be unique
            // after string conversion.
            NSObject *valueKey = values[i][kOpen311_Key];
            if ([valueKey isKindOfClass:[NSNumber class]]) {
                valueKey = [(NSNumber *)valueKey stringValue];
            }
            if ([(NSString *)valueKey isEqualToString:self.currentValue]) {
                [self.picker selectRow:(NSInteger)i+1 inComponent:0 animated:YES];
            }
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated{
    if([self.picker selectedRowInComponent:0]!=0){
        NSObject *key = self.attribute[kOpen311_Values][[self.picker selectedRowInComponent:0]-1][kOpen311_Key];
        if ([key isKindOfClass:[NSNumber class]]) {
            key = [(NSNumber *)key stringValue];
        }
        [self.delegate didProvideValue:(NSString *)key];
    }
    else{
        [self.delegate didProvideValue:@""];
    }


}

- (IBAction)done:(id)sender
{
    // Some servers use non-string keys.
    // We need to convert them to strings before saving them.
    // If they were unique to begin with, they should still be unique
    // after string conversion.
    if([self.picker selectedRowInComponent:0]!=0){
        NSObject *key = self.attribute[kOpen311_Values][[self.picker selectedRowInComponent:0]-1][kOpen311_Key];
        if ([key isKindOfClass:[NSNumber class]]) {
            key = [(NSNumber *)key stringValue];
        }
        [self.delegate didProvideValue:(NSString *)key];
    }
    else{
        [self.delegate didProvideValue:@""];
    }

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Picker handlers
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.attribute[kOpen311_Values] count] + 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(row == 0){
        return @"";
    }
    else{
        if([self.attribute[kOpen311_Values][row-1][kOpen311_Name] isEqualToString:@"YES"])
        {
            return NSLocalizedString(kUI_Yes, nil);
        }
        else if([self.attribute[kOpen311_Values][row-1][kOpen311_Name] isEqualToString:@"NO"]){
            return NSLocalizedString(kUI_No, nil);
        }
        return self.attribute[kOpen311_Values][row-1][kOpen311_Name];
    }
}

@end
