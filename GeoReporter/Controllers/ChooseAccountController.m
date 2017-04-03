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

#import "ChooseAccountController.h"
#import "ChooseServiceController.h"
#import "Preferences.h"
#import "Open311.h"
#import "Strings.h"
#import "ReportController.h"

@interface ChooseAccountController ()

@end

@implementation ChooseAccountController{
    Open311 *open311;
    NSString *currentServerName;
    NSArray *accounts;
    UIActivityIndicatorView *busyIcon;

}
static NSString * const kCellIdentifier = @"account_cell";
static NSString * const kSegueToChooseService = @"SegueToChooseServiceFromAccount";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(kUI_Cities,nil);

}

- (void)viewWillAppear:(BOOL)animated
{
    open311 = [Open311 sharedInstance];
    currentServerName = [[Preferences sharedInstance] getCurrentServer][kOpen311_Name];
    accounts = [NSArray alloc];
    accounts = [open311 accounts];
    [self.tableView reloadData];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [accounts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    //NSDictionary *account = accounts[indexPath.row];
    //cell.textLabel      .text = account[kRst_AccountName];
    //cell.detailTextLabel.text = account[kRst_AccountURL];
    
    NSDictionary *account = [accounts objectAtIndex:[indexPath row]];
    cell.textLabel.text=[account objectForKey:kRst_AccountName];
    
    return cell;
}




- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ChooseServiceController *chooseService = [segue destinationViewController];
    chooseService.account = [accounts objectAtIndex:[[self.tableView indexPathForSelectedRow] row]];
    open311.currentAccount = [accounts objectAtIndex:[[self.tableView indexPathForSelectedRow] row]];
}
@end