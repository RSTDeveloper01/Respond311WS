//
//  NumberController.m
//  RESPOND
//
//  Created by RSTDeveloper01 on 8/28/13.
//  Copyright (c) 2013 Rock Solid Technologies. All rights reserved.
//

#import "DecimalController.h"
#import "Strings.h"

@implementation DecimalController
- (void)viewDidLoad
{
    self.label    .text = self.attribute[kOpen311_Description];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.textField.text = self.currentValue;
    [self.textField becomeFirstResponder];
}

-(void) viewWillDisappear:(BOOL)animated{
    [self.delegate didProvideValue:self.textField.text];
    
}

- (IBAction)done:(id)sender
{
    [self.delegate didProvideValue:self.textField.text];
    [self.navigationController popViewControllerAnimated:YES];
}

@end