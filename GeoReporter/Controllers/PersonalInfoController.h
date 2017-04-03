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

#import <UIKit/UIKit.h>
#import "PersonalInfoDelegate.h"

@interface PersonalInfoController : UITableViewController <UITableViewDataSource, UITableViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate,UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *labelFirstName;
@property (nonatomic, weak) IBOutlet UILabel *labelLastName;
@property (nonatomic, weak) IBOutlet UILabel *labelEmail;
@property (nonatomic, weak) IBOutlet UILabel *labelPhone;
@property (nonatomic, weak) IBOutlet UILabel *labelCity;
@property (nonatomic, weak) IBOutlet UITextField *textFieldFirstName;
@property (nonatomic, weak) IBOutlet UITextField *textFieldLastName;
@property (nonatomic, weak) IBOutlet UITextField *textFieldEmail;
@property (nonatomic, weak) IBOutlet UITextField *textFieldPhone;
@property (nonatomic, weak) IBOutlet UITextField *textFieldCity;
@property (nonatomic, weak) IBOutlet UIPickerView *cityPickerView;


@property id<PersonalInfoDelegate>delegate;
-(IBAction)done:(id)sender;
@end
