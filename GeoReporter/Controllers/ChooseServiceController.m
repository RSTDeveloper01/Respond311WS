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

#import "ChooseServiceController.h"
#import "Preferences.h"
#import "Open311.h"
#import "Strings.h"
#import "ReportController.h"
@interface ChooseServiceController ()

@end

@implementation ChooseServiceController {
    Open311 *open311;
    NSString *currentServerName;
    NSMutableArray *services;
    UIActivityIndicatorView *busyIcon;
    NSDictionary* selectedService;
    BOOL *hasRetrievedServDef;
}
static NSString * const kCellIdentifier = @"service_cell";
static NSString * const kSegueToReport  = @"SegueToReport";

- (void)viewDidLoad
{
    [super viewDidLoad];
    open311 = [Open311 sharedInstance];
    selectedService= [[NSDictionary alloc]init];
    currentServerName = [[Preferences sharedInstance] getCurrentServer][kOpen311_Name];
    self.navigationItem.title = [self.account objectForKey:kRst_AccountName];
    hasRetrievedServDef=NO;
    
    [self startBusyIcon];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serviceListReady)
                                                 name:kNotification_ServiceListReady
                                               object:open311];
    [self loadServices];
    
}

- (void) loadServices{

    [open311 getServicesForAccount:_account];

}

- (void)startBusyIcon
{
    busyIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    busyIcon.center = self.tabBarController.view.center;
    [busyIcon setFrame:self.tabBarController.view.frame];
    [busyIcon setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [busyIcon startAnimating];
    [self.tabBarController.view addSubview:busyIcon];
    
}



- (void)serviceListReady
{
    if([[open311 groups]count]==0)
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    [busyIcon stopAnimating];
    [busyIcon removeFromSuperview];
    [self.tableView reloadData];
}


#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [open311.groups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    for (NSDictionary *service in [open311 services]) {
        if ([[service objectForKey:@"group"] isEqualToString:[open311.groups objectAtIndex:section]]) {
            count= count+1;
        }
    }
    return count;
}

-(NSString *) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section{
    return [open311.groups objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *group= [open311.groups objectAtIndex:[indexPath section]];
    NSMutableArray *services=[[NSMutableArray alloc]init];
    
    if (group) {
        for (NSDictionary *service in [[Open311 sharedInstance] services]) {
            if ([[service objectForKey:@"group"] isEqualToString:group]) {
                [services addObject:service];
            }
        }
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    //    cell.textLabel.text = [self.groups objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    cell.textLabel.text=[[services objectAtIndex:[indexPath row]]objectForKey:@"service_name"];
    //cell.detailTextLabel.text=[[services objectAtIndex:[indexPath row]]objectForKey:@"description"];
    
    return cell;
}


//NEW SEPTEMBER
/*- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    NSString *group= [open311.groups objectAtIndex:indexPath.section];
    NSMutableArray *services=[[NSMutableArray alloc]init];
    if (group) {
        for (NSDictionary *service in [open311 services]) {
            if ([[service objectForKey:@"group"] isEqualToString:group]) {
                [services addObject:service];
            }
        }
    }
    selectedService= services[indexPath.row];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serviceDefinitionReady)
                                                 name:kNotification_ServiceDefinitionReady
                                               object:open311];
    [self startBusyIcon];
    [open311 loadServiceDefinitions2:selectedService];
}*/

//NEW SEPTEMBER 
/*-(BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
     [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    if([identifier isEqualToString:kSegueToReport] && hasRetrievedServDef && selectedService!=nil && [[selectedService objectForKey:kOpen311_Metadata] boolValue] == YES
       && [[open311 serviceDefinitions] objectForKey:[selectedService objectForKey:kOpen311_ServiceCode ]] != nil)
    {
        return YES;
    }
    else{
        NSString *group= [open311.groups objectAtIndex:[[self.tableView indexPathForSelectedRow]section]];
        NSMutableArray *services=[[NSMutableArray alloc]init];
        if (group) {
            for (NSDictionary *service in [open311 services]) {
                if ([[service objectForKey:@"group"] isEqualToString:group]) {
                    [services addObject:service];
                }
            }
        }
        selectedService= services[[[self.tableView indexPathForSelectedRow]row]] ;
        
        [self startBusyIcon];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serviceDefinitionReady)
                                                     name:kNotification_ServiceDefinitionReady
                                                   object:open311];
        [open311 loadServiceDefinitions2:selectedService];
    
        return NO;
    }
}*/


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *group= [open311.groups objectAtIndex:[[self.tableView indexPathForSelectedRow]section]];
    NSMutableArray *services=[[NSMutableArray alloc]init];
    if (group) {
        for (NSDictionary *service in [open311 services]) {
            if ([[service objectForKey:@"group"] isEqualToString:group]) {
                [services addObject:service];
            }
        }
    }
    selectedService= services[[[self.tableView indexPathForSelectedRow]row]] ;
    ReportController *report = [segue destinationViewController];
    report.service = selectedService;
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
}

@end
