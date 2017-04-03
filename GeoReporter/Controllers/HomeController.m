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

#import "HomeController.h"
#import "Strings.h"
#import "Preferences.h"
#import "Open311.h"
#import "AFJSONRequestOperation.h"
#import "ChooseServiceController.h"


@interface HomeController ()

@end

static NSString * const kSegueToSettings = @"SegueToSettings";
static NSString * const kSegueToArchive  = @"SegueToArchive";
static NSString * const kSegueToServices = @"SegueToChooseServiceFromAccount";
@implementation HomeController {
    Open311 *open311;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    UIActivityIndicatorView *busyIcon;
    NSDictionary *selectedAccount;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.reportLabel     .text = NSLocalizedString(kUI_Report,  nil);

    
    self.archiveLabel    .text = NSLocalizedString(kUI_Archive, nil);
    self.reportingAsLabel.text = NSLocalizedString(kUI_ReportingAs, nil);
    self.currentLocationLabel.text = NSLocalizedString(kUI_CurrentLocation, nil);
    self.locationLabel.text = NSLocalizedString(kUI_LocationNotAvailable, nil);
    
    self.navigationItem.title = NSLocalizedString(kUI_AppTitle,nil);
    [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(kUI_HelpTitle, nil)];
    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(kUI_Settings, nil)];
    
    [[self.tabBarController.tabBar.items objectAtIndex:kTab_Home]  setTitle:NSLocalizedString(kUI_TitleHome,  nil)];
    [[self.tabBarController.tabBar.items objectAtIndex:kTab_Report]  setTitle:NSLocalizedString(kUI_Report,  nil)];
    [[self.tabBarController.tabBar.items objectAtIndex:kTab_Archive] setTitle:NSLocalizedString(kUI_Archive, nil)];
   [[self.tabBarController.tabBar.items objectAtIndex:kTab_Profile] setTitle:NSLocalizedString(kUI_Profile, nil)];
    
    self.tabBarController.delegate = self;
 
    //removes the extra separators from the tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}




- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    open311 = [Open311 sharedInstance];
    
    if(open311.accounts == nil || (open311.accounts!= nil && open311.accounts.count == 0)){
        Preferences *preferences = [Preferences sharedInstance];
        NSDictionary *currentServer = [preferences getCurrentServer];
     
        if(currentServer == nil)
        {
            NSDictionary* server= [[NSDictionary alloc]initWithObjectsAndKeys:
                               [NSNumber numberWithBool:TRUE],kOpen311_SupportsMedia,
                               @"json",kOpen311_Format,
                               @"http://respond311api.respondcrm.com/dev/V2.0/Open311API.svc/",kOpen311_Url,
                               //@"http://192.168.3.17/RESPOND-Open311API/Open311API.svc/",kOpen311_Url,
                               @"00000000-0000-0000-0000-000000000000",kOpen311_ApiKey,
                               @"Municipios PR",kOpen311_Name,
                               @"municipiospr",kOpen311_Jurisdiction,nil];
            currentServer = server;
            [preferences setCurrentServer:server];
            
        }
    

        [self startBusyIcon];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountListReady)
                                                 name:kNotification_AccountListReady
                                               object:open311];
        
        [open311 loadAllMetadataForServer:currentServer];
    }
    [self refreshPersonalInfo];
}


- (void)startBusyIcon
{
    if(!busyIcon.isAnimating)
        busyIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        busyIcon.center = self.tabBarController.view.center;
        [busyIcon setFrame:self.tabBarController.view.frame];

        [busyIcon setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
        [busyIcon startAnimating];
        [self.tabBarController.view addSubview:busyIcon];
    
}

- (void)serviceListReady
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotification_ServiceListReady object:nil];
    [busyIcon stopAnimating];
    [busyIcon removeFromSuperview];
}

-(void)accountListReady
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotification_AccountListReady object:nil];
    [busyIcon stopAnimating];
    [busyIcon removeFromSuperview];
}

- (void)refreshPersonalInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *text = @"";
    NSString *firstname = [defaults stringForKey:kOpen311_FirstName];
    NSString *lastname  = [defaults stringForKey:kOpen311_LastName];
    NSString *email     = [defaults stringForKey:kOpen311_Email];
    NSString *phone     = [defaults stringForKey:kOpen311_Phone];
    NSString *city      = [defaults stringForKey:kOpen311_City];
    if ([firstname length] > 0 || [lastname length] > 0) {
        text = [text stringByAppendingFormat:@"%@ %@", firstname, lastname];
    }
    if ([email length] > 0) {
        text = [text stringByAppendingFormat:@"\r%@", email];
    }
    if ([phone length] > 0) {
        text = [text stringByAppendingFormat:@"\r%@", phone];
    }
    
    if ([city length] > 0) {
        text = [text stringByAppendingFormat:@"\r%@", city];
    }
    
    if ([text length] == 0) {
        text = NSLocalizedString(kUI_Anonymous,  nil);
    }
    self.personalInfoLabel.text = text;
    [self.tableView reloadData];
}

#pragma mark - Table Handler Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 2) {
        
        
        CGRect textRect = [self.personalInfoLabel.text boundingRectWithSize:CGSizeMake(300, 140)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName:self.personalInfoLabel.font}
                                             context:nil];
        
        CGSize size = textRect.size;
        
        
        NSInteger height = size.height + 35;
        return (CGFloat)height;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            
        
            [self startBusyIcon];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(locationUpdated)
                                                         name:@"currentLocationUpdated"
                                                       object:open311];
            [open311 clearGpsCity];
            [open311 refreshLocation];
        }
        if (indexPath.row == 1) {
            [self.tabBarController setSelectedIndex:kTab_Archive];
        }
        if(indexPath.row == 2){
             [self performSegueWithIdentifier:kSegueToSettings sender:self];
        }
    }
    if (indexPath.section == 1 && indexPath.row==0) {
        [self performSegueWithIdentifier:kSegueToSettings sender:self];
    }
}

-(void) locationUpdated{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"currentLocationUpdated" object:nil];
    [busyIcon stopAnimating];
    [busyIcon removeFromSuperview];

    NSString *gpsCity=@"";
    NSString *userCity=@"";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if([userDefaults objectForKey:kOpen311_City]!=nil)
    {
        userCity= [userDefaults objectForKey:kOpen311_City];
    }
    if(open311.gpsCity != nil)
    {
        gpsCity = open311.gpsCity;
    }
    
    if(![gpsCity isEqualToString:@""] || ![userCity isEqualToString:@""])
    {
        [self showActionSheet];
    }
    else if([[open311 accounts]count]>0){
        [self.tabBarController setSelectedIndex:kTab_Report];
    }
}

#pragma mark Action Sheet Delegate Methods
-(void) showActionSheet{
    UIActionSheet *popupQuery= [[UIActionSheet alloc]initWithTitle:NSLocalizedString(kUI_SelectCityTitle,nil)delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    NSString *userCity = @"";
    NSString *gpsCity  = @"";
    
    if([preferences objectForKey:kOpen311_City]!=nil)
    {
       userCity= [preferences objectForKey:kOpen311_City];
    }
    if(open311.gpsCity != nil)
    {
        gpsCity = open311.gpsCity;
    }
    
    if(![userCity isEqualToString:@""] && ![gpsCity isEqualToString:@""])
    {
        
            if([userCity isEqualToString:gpsCity])
            {
                [popupQuery addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@",NSLocalizedString(kUI_GPSCity,  nil),gpsCity]];
            }
            else
            {
                [popupQuery addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@",NSLocalizedString(kUI_UserCity,  nil),userCity]];
                [popupQuery addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@",NSLocalizedString(kUI_GPSCity,  nil),gpsCity]];
            }

    }
    else if(![gpsCity isEqualToString:@""]){
                [popupQuery addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@",NSLocalizedString(kUI_GPSCity,  nil),gpsCity]];
    }
    
    else if(![userCity isEqualToString:@""])
    {
                [popupQuery addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@",NSLocalizedString(kUI_UserCity,  nil),userCity]];
    }
    
      
    [popupQuery addButtonWithTitle:NSLocalizedString(kUI_Other,nil)];
    [popupQuery addButtonWithTitle:NSLocalizedString(kUI_Cancel,nil)];
    
    [popupQuery setCancelButtonIndex:(popupQuery.numberOfButtons-1)];
    
    popupQuery.actionSheetStyle=UIActionSheetStyleBlackTranslucent;
    popupQuery.tintColor = [UIColor colorWithRed:0.09 green:0.65 blue:0.74 alpha:1.0];

    [popupQuery showFromTabBar:self.tabBarController.tabBar];
    
}

-(void) actionSheet:(UIActionSheet *) actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([actionSheet cancelButtonIndex] != buttonIndex){
        if(![[actionSheet buttonTitleAtIndex:buttonIndex]isEqualToString:NSLocalizedString(kUI_Other,nil)])
        {
        
            NSString *city=[[[actionSheet buttonTitleAtIndex:buttonIndex]componentsSeparatedByString:@" - "]objectAtIndex:1];
            
            if([city isEqualToString:open311.gpsCity] && ![open311.gpsAdministrativeArea isEqualToString:@""] && (![open311.gpsAdministrativeArea isEqualToString:@"Puerto Rico"] && ![open311.gpsAdministrativeArea isEqualToString:@"PR"]))
            {
                UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(kUI_OutOfPRTitle, nil) message:NSLocalizedString(kUI_OutOfPRMessage, nil)delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [alertView show];
                return;
            }
            int i = 0;
            for(NSDictionary *account in open311.accounts){
                if([[account objectForKey:@"account_name"]isEqualToString:city]){
                    selectedAccount = account;
                    break;
                }
                i++;
            }
            if(selectedAccount!=nil){
                [self.navigationController popToRootViewControllerAnimated:NO];
                [self.tabBarController setSelectedIndex:kTab_Home];
                
                open311.currentAccount = selectedAccount;
                //[[self.tabBarController.tabBar.items objectAtIndex:kTab_Report]setEnabled:NO];
                [self performSegueWithIdentifier:kSegueToServices sender:self];
            }
        }
        else if([[open311 accounts]count]>0)
        {
            [[[self.tabBarController viewControllers] objectAtIndex:kTab_Report]popToRootViewControllerAnimated:NO];
            [self.tabBarController setSelectedIndex:kTab_Report];
        }
    }
    else{
        return;
    }
}

#pragma mark Tab Bar Controller Delegate Methods

-(void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    
    
    NSString *gpsCity=@"";
    NSString *userCity=@"";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if([userDefaults objectForKey:kOpen311_City]!=nil)
    {
        userCity= [userDefaults objectForKey:kOpen311_City];
    }
    
    if(open311.gpsCity != nil)
    {
        gpsCity = open311.gpsCity;
    }
    
    
    if([tabBarController.tabBar.items objectAtIndex:kTab_Report] == viewController.tabBarItem
       && (![gpsCity isEqualToString:@""] || ![userCity isEqualToString:@""]))
    {

        
        [self startBusyIcon];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(locationUpdated)
                                                     name:@"currentLocationUpdated"
                                                   object:open311];
        [open311 clearGpsCity];
        [open311 refreshLocation];
        //[self.tabBarController setSelectedIndex:kTab_Home];
    }
    else {
        if([viewController isKindOfClass:[UINavigationController class]]){
            [(UINavigationController*)viewController popToRootViewControllerAnimated:NO];
        }
    }
}

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if([tabBarController.tabBar.items objectAtIndex:kTab_Report] == viewController.tabBarItem)
    {
        [self startBusyIcon];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(locationUpdated)
                                                     name:@"currentLocationUpdated"
                                                   object:open311];
        [open311 clearGpsCity];
        [open311 refreshLocation];
        return NO;
    }

    return YES;


    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:kSegueToServices]){
        ChooseServiceController *chooseService = [segue destinationViewController];
        chooseService.account = selectedAccount;
        selectedAccount=nil;
    }
}
@end
