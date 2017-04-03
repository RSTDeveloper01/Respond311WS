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

#import "HelpController.h"
#import "Strings.h"
@interface HelpController ()

@end

@implementation HelpController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(kUI_HelpTitle,nil);
    self.helpTextView.text= NSLocalizedString(kUI_HelpText,nil);
    //[self.helpTextView setFrame:CGRectMake(0,0,320,480)];
    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(kUI_About, nil)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
