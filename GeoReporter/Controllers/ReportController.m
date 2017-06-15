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

#import "ReportController.h"
#import "Strings.h"
#import "Preferences.h"
#import "Open311.h"
#import "StringController.h"
#import "PersonalInfoController.h"
#import <MessageUI/MessageUI.h>
#import "TextController.h"
#import "SingleValueListController.h"
#import "MultiValueListController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
@interface ReportController ()

@end

@implementation ReportController {
    NSMutableArray *fields;
    NSIndexPath *currentIndexPath;
    NSString *currentServerName;
    
    // In the ServiceRequest, we are only storing the URL for the photo asset.
    // Retrieving the actual image data from the asset is an async call.
    // We need to know what the current |mediaUrl| is, that way, we can invalidate
    // the |mediaThumnail| when the |mediaUrl| changes
    ALAssetsLibrary *library;
    NSURL   *mediaUrl;
    UIImage *mediaThumbnail;
    
    UIActivityIndicatorView *busyIcon;
    Open311 *open311;
    UIView *headerView;
}
@synthesize report=_report;

static NSString * const kReportCell      = @"report_cell";
static NSString * const kReportImageCell = @"report_image_cell";
static NSString * const kFieldname       = @"fieldname";
static NSString * const kLabel           = @"label";
static NSString * const kType            = @"type";
static NSString * const kTypeDescription = @"type_description";
static NSString * const kWholeNumber     = @"wholenumber";
static NSString * const kDecimalNumber   = @"decimalnumber";

static NSString * const kSegueToLocation        = @"SegueToLocation";
static NSString * const kSegueToNumber          = @"SegueToNumber";
static NSString * const kSegueToDecimal         = @"SegueToDecimal";
static NSString * const kSegueToText            = @"SegueToText";
static NSString * const kSegueToString          = @"SegueToString";
static NSString * const kSegueToSingleValueList = @"SegueToSingleValueList";
static NSString * const kSegueToMultiValueList  = @"SegueToMultiValueList";
static NSString * const kSegueToDateTime        = @"SegueToDateTime";
static NSString * const kSegueToSettings        = @"SegueToSettings";


// Creates a multi-dimensional array to represent the fields to display in
// the table view.
//
// You can access indivual cells like so:
// fields[section][row][fieldname]
//                     [label]
//                     [type]
//
// The actual stuff the user enters will be stored in the ServiceRequest
// This data structure is only for display
- (void)load
{
    //currentServerName = [[Preferences sharedInstance] getCurrentServer][kOpen311_Name];
    //self.navigationItem.title = _service[kOpen311_ServiceName];
    
    
    if([[[_service objectForKey:krst_Service_Category] stringValue] isEqualToString:rst_Service_Category_Service]){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(kUI_Submit,nil) style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
        
    }
    else{
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(kUI_Share,nil) style:UIBarButtonItemStyleDone target:self action:@selector(shareReport:)];
    }
    [self.navigationItem.rightBarButtonItem setTintColor:[UIColor colorWithRed:0.0 green:0.80 blue:0.15 alpha:1.0]];
    //[self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(kUI_Submit, nil)];
    _report = [[Report alloc] initWithService:_service];
    
    // First section: Photo and Location choosers
    fields = [[NSMutableArray alloc] init];
    
    NSMutableArray *tblRows = [[NSMutableArray alloc] init];
    if([[[_service objectForKey:krst_Service_Category] stringValue] isEqualToString:rst_Service_Category_Service])
    {
        //  header = [NSString stringWithFormat:@"%@ - %@", _service[kOpen311_ServiceName],_service[kOpen311_Description]];
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES
            && [[[Preferences sharedInstance] getCurrentServer][kOpen311_SupportsMedia] boolValue]) {
            [tblRows addObject:@{kFieldname:kOpen311_Media, kLabel:NSLocalizedString(kUI_AddPhoto, nil) ,kType:kOpen311_Media }];
            [tblRows addObject:@{kFieldname:kOpen311_Address, kLabel:NSLocalizedString(kUI_Location, nil), kType:kOpen311_Address}];
            
            //            [fields addObject:@[@{kFieldname:kOpen311_Media, kLabel:NSLocalizedString(kUI_AddPhoto, nil), kType:kOpen311_Media },@{kFieldname:kOpen311_Address, kLabel:NSLocalizedString(kUI_Location, nil), kType:kOpen311_Address}
            //             ]];
            
            // Initialize the Asset Library object for saving/reading images
            library = [[ALAssetsLibrary alloc] init];
        }
        else {
            [tblRows addObject:@{kFieldname:kOpen311_Media, kLabel:NSLocalizedString(kUI_AddPhoto, nil), kType:kOpen311_Media }];
            [tblRows addObject:@{kFieldname:kOpen311_Address, kLabel:NSLocalizedString(kUI_Location, nil), kType:kOpen311_Address}];
            
            //            [fields addObject:@[
            //                                @{kFieldname:kOpen311_Media, kLabel:NSLocalizedString(kUI_AddPhoto, nil), kType:kOpen311_Media },
            //            @{kFieldname:kOpen311_Address, kLabel:NSLocalizedString(kUI_Location, nil), kType:kOpen311_Address}
            //            ]];
            
            
        }
        
        // Second section: Report Description
        [tblRows addObject:
         @{kFieldname:kOpen311_Description, kLabel:NSLocalizedString(kUI_ReportDescription, nil), kType:kOpen311_Text}
         ];
        
        // Third section: Attributes
        // Attributes with variable=false will be appended to the section header
        
        if (_service[kOpen311_Metadata]) {
            _report.serviceDefinition= open311.serviceDefinitions[_service[kOpen311_ServiceCode]];
            NSMutableArray *attributes = [[NSMutableArray alloc] init];
            if(_report.serviceDefinition[kOpen311_Attributes]!=[NSNull null]){
                for (NSDictionary *attribute in _report.serviceDefinition[kOpen311_Attributes]) {
                    // According to the spec, attribute paramters need to be named:
                    // attribute[code]
                    //
                    // Multivaluelist values will be arrays.  Because of that, the HTTPClient
                    // will append the appropriate "[]" when the POST is created.  We do not
                    // need to use a special name here for the Multivaluelist attributes.
                    if ([attribute[kOpen311_Variable] boolValue]) {
                        NSString *code = [NSString stringWithFormat:@"%@[%@]", kOpen311_Attribute, attribute[kOpen311_Code]];
                        //NSString *code = [NSString stringWithFormat:@"%@", attribute[kOpen311_Code]];
                        NSString *type = attribute[kOpen311_Datatype];
                        NSString *typeDescription = attribute[kOpen311_DatatypeDescription];
                        [attributes addObject:@{kFieldname:code, kLabel:attribute[kOpen311_Description], kType:type, kTypeDescription:typeDescription}];
                    }
                    
                    
                }
                if (attributes.count > 0) {
                    [tblRows addObject:attributes];
                }
                
            }
            //Fourth section:Personal Info
            NSMutableArray *personalInfo = [[NSMutableArray alloc]init];
            [tblRows addObject:@{kFieldname:@"personal_info", kLabel:NSLocalizedString(kUI_ReportingAs, nil), kType:   kOpen311_UserInfo}];
            [fields addObject:tblRows];
        }
    }
    [[self tableView]reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    open311 = [Open311 sharedInstance];
    currentServerName = [[Preferences sharedInstance] getCurrentServer][kOpen311_Name];
    self.navigationItem.title = _service[kOpen311_ServiceName];
    
    if ([_service[kOpen311_Metadata]boolValue]==YES) {
        busyIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        busyIcon.center = self.tabBarController.view.center;
        
        
        [busyIcon setFrame:self.tabBarController.view.frame];
        [busyIcon setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
        [busyIcon startAnimating];
        [self.tabBarController.view addSubview:busyIcon];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serviceDefinitionReady)
                                                     name:kNotification_ServiceDefinitionReady
                                                   object:open311];
        [[Open311 sharedInstance]loadServiceDefinitions2:_service];
        
    }
    else{
        [self load];
    }
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 300;
    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}




// Check if it is still valid for the user to enter information for a report.
//
// The user can always change tabs, select a different server, then try to come back to the report.
//
// Also, once we've successfully submitted a report, we do not want the user to resubmit
// the same report.  So, what we do is delete the service upon success.
//
// Either way, bounce the user back to the Group Chooser screen, starting the report
// process over from scratch.
- (void)viewWillAppear:(BOOL)animated
{
    // If the user has changed servers
    // or if we don't have a service
    if (![currentServerName isEqualToString:[[Preferences sharedInstance] getCurrentServer][kOpen311_Name]]
        || _service==nil) {
        
        currentServerName = nil;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    [self refreshPersonalInfo];
}

/**
 * POST the service request to the endpoint
 */
- (IBAction)done:(id)sender
{
    if(_report.postData[kOpen311_Media]==nil &&
       (_report.postData[kOpen311_AddressString] == nil || [_report.postData[kOpen311_AddressString] isEqualToString:@""])&&
       (_report.postData[kOpen311_Description] ==nil || [_report.postData[kOpen311_Description] isEqualToString:@""])){
        UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:nil message:NSLocalizedString(kUI_PleaseProvideDetails, nil)delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
        [alertView show];
        return;
    }
    
    busyIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    busyIcon.center = self.tabBarController.view.center;
    [busyIcon setFrame:self.tabBarController.view.frame];
    [busyIcon setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [busyIcon startAnimating];
    [self.tabBarController.view addSubview:busyIcon];
    
    //Open311 *open311 = [Open311 sharedInstance];
    
    NSNotificationCenter *notifications = [NSNotificationCenter defaultCenter];
    [notifications addObserver:self selector:@selector(postSucceeded) name:kNotification_PostSucceeded object:open311];
    [notifications addObserver:self selector:@selector(postFailed)    name:kNotification_PostFailed    object:open311];
    
    if([[open311.currentAccount objectForKey:@"url"] isEqualToString:@""])
    {
        _report.postData[@"accountname"]= [open311.currentAccount objectForKey:@"account_name"];
        _report.postData[@"accountid"]= [open311.currentAccount objectForKey:@"account_id"];
    }
    
    [open311 startPostingServiceRequest:_report];
}

- (void)serviceDefinitionReady
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kNotification_ServiceDefinitionReady object:nil];
    [busyIcon stopAnimating];
    [busyIcon removeFromSuperview];
    [self load];
}


- (void)postSucceeded
{
    [busyIcon stopAnimating];
    [busyIcon removeFromSuperview];
    
    _service = nil;
    
    [[[self.tabBarController viewControllers] objectAtIndex:kTab_Archive]popToRootViewControllerAnimated:NO];
    [self.tabBarController setSelectedIndex:kTab_Archive];
}

- (void)postFailed
{
    [busyIcon stopAnimating];
    [busyIcon removeFromSuperview];
}

/**
 * Refresh the view after a response from user data entry
 */
- (void)popViewAndReloadTable
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.tableView reloadData];
    currentIndexPath = nil;
}

#pragma mark - Table view handlers
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if([[[_service objectForKey:krst_Service_Category] stringValue] isEqualToString:rst_Service_Category_Service])
    {
        return [fields count];
    }
    else{
        return 1;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([[[_service objectForKey:krst_Service_Category] stringValue] isEqualToString:rst_Service_Category_Service])
    {
        return [fields[section] count];
    }
    else{
        return 0;
    }
    
}

/*- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
 {
 if (section == 0) {
 return header;
 }
 return nil;
 }*/

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(section == 0){
        UILabel *title = [[UILabel alloc]init];
        title.frame = CGRectMake(10, 6, 300, 20);
        title.textAlignment= UITextAlignmentLeft;
        title.lineBreakMode = UILineBreakModeWordWrap;
        title.numberOfLines = 0;
        title.backgroundColor= [UIColor clearColor];
        title.textColor = [UIColor blackColor];
        title.shadowColor = [UIColor whiteColor];
        title.shadowOffset= CGSizeMake(0.0,1.0);
        title.font=[UIFont systemFontOfSize:14];
        if([[[_service objectForKey:krst_Service_Category] stringValue] isEqualToString:rst_Service_Category_Service]){
            title.text= self.service[kOpen311_ServiceName];
        }
        else{
            title.text= [NSString stringWithFormat:@"%@\n\n%@",NSLocalizedString(kRst_InformationalTopicHeader, nil),self.service[kOpen311_ServiceName]];
        }
        [title sizeToFit];
        
        UILabel *description = [[UILabel alloc]init];
        description.textAlignment= UITextAlignmentLeft;
        description.frame = CGRectMake(10, title.frame.size.height+6, 300, 20);
        description.lineBreakMode = UILineBreakModeWordWrap;
        description.numberOfLines = 0;
        description.backgroundColor= [UIColor clearColor];
        description.textColor = [UIColor blackColor];
        description.shadowColor = [UIColor whiteColor];
        description.shadowOffset= CGSizeMake(0.0,1.0);
        description.font=[UIFont systemFontOfSize:16];
        description.text= self.service[kOpen311_Description];
        [description sizeToFit];
        
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0,0, 320, title.frame.size.height+description.frame.size.height+15)];
        [view addSubview:title];
        [view addSubview:description];
        headerView=view;
        return view.frame.size.height;
    }
    else{
        return 0;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if(section == 0 && headerView!=nil){
        return headerView;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if(indexPath.row == 0){
//        return 100;
//    }
    //    if (indexPath.row == 3) {
    //
    //
    //        CGRect textRect = [self.personalInfoLabel.text boundingRectWithSize:CGSizeMake(300, 140)
    //                                                                    options:NSStringDrawingUsesLineFragmentOrigin
    //                                                                 attributes:@{NSFontAttributeName:self.personalInfoLabel.font}
    //                                                                    context:nil];
    //
    //        CGSize size = textRect.size;
    //
    //
    //        NSInteger height = size.height + 35;
    //        return (CGFloat)height;
    //    }
    
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell;
    
    
    if (indexPath.row == 0) {
         cell = [tableView dequeueReusableCellWithIdentifier:kReportImageCell];
        
        NSURL *url = _report.postData[kOpen311_Media];
        if (url != nil) {
           
            
            UIImageView *pic = (UIImageView *)[cell viewWithTag:1111];
            [pic setImage:_reportImage];
            
        }
        
    }
    else{
        //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReportCell forIndexPath:indexPath];
        cell = [tableView dequeueReusableCellWithIdentifier:kReportCell];
        cell.detailTextLabel.text = @"";
        
        NSDictionary *field = fields[indexPath.section][indexPath.row];
        NSString *fieldname = field[kFieldname];
        cell.textLabel.text = field[kLabel];
        [cell.imageView setImage:nil];
        // Media cell
       /* if ([fieldname isEqualToString:kOpen311_Media]) {
            NSURL *url = _report.postData[kOpen311_Media];
            if (url != nil) {
                // When the user-selected mediaUrl changes, we need to load a fresh thumbnail image
                // This is an async call, that could take some time.
                if (![mediaUrl isEqual:url]) {
                    [library assetForURL:url
                             resultBlock:^(ALAsset *asset) {
                                 // Once we finally get the image loaded, we need to tell the
                                 // table to redraw itself, which should pick up the new |mediaThumbnail|
                                 mediaThumbnail = [UIImage imageWithCGImage:[asset thumbnail]];
                             }
                            failureBlock:^(NSError *error) {
                                DLog(@"Failed to load thumbnail from library");
                            }];
                }
                
                if (mediaThumbnail != nil) {
                    [cell.imageView setImage:mediaThumbnail];
                }
            }
            else{
                UIImage *img = [UIImage imageNamed:@"camera"];
                [cell.imageView setImage:img];
            }
        }
        // Location cell
        else */if ([fieldname isEqualToString:kOpen311_Address]) {
            NSString *address   = _report.postData[kOpen311_AddressString];
            NSString *latitude  = _report.postData[kOpen311_Latitude];
            NSString *longitude = _report.postData[kOpen311_Longitude];
            if (address.length==0 && latitude.length!=0 && longitude.length!=0) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", latitude, longitude];
            }
            else {
                cell.detailTextLabel.text = address;
            }
            
        }
        // Attribute cells
        else if([fieldname isEqualToString:@"personal_info"]){
            
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
            cell.detailTextLabel.text = text;
            
            [cell.imageView  setImage:[UIImage imageNamed:@"h_profile"]];
        }
        else{
            NSString *datatype  = field[kType];
            
            // SingleValueList and MultiValueList values are a set of key:name pairs
            // The |postData| will contain the key - but we want to display
            // the name associated with each key
            if ([datatype isEqualToString:kOpen311_SingleValueList]) {
                NSString *userInput = _report.postData[fieldname];
                if(userInput){
                    if ([userInput isEqualToString:@"true"]) {
                        cell.detailTextLabel.text = NSLocalizedString(kUI_Yes, nil);
                    }
                    else if ([userInput isEqualToString:@"false"]) {
                        cell.detailTextLabel.text = NSLocalizedString(kUI_No, nil);
                    }
                    else{
                        cell.detailTextLabel.text = [_report attributeValueForKey:userInput atIndex:indexPath.row];
                    }
                }
            }
            else if ([datatype isEqualToString:kOpen311_MultiValueList]) {
                NSString *display = @"";
                NSArray *userInput = _report.postData[fieldname];
                int count = [userInput count];
                for (int i=0; i<count; i++) {
                    NSString *name = [_report attributeValueForKey:userInput[i] atIndex:indexPath.row];
                    display = [display stringByAppendingFormat:@"%@,", name];
                }
                cell.detailTextLabel.text = display;
            }
            else if([datatype isEqualToString:kOpen311_Datetime]){
                NSDate *userInput = _report.postData[fieldname];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                NSString *formattedString =[dateFormatter stringFromDate:userInput];
                
                cell.detailTextLabel.text = formattedString;
            }
            else{
                NSString *userInput = _report.postData[fieldname];
                cell.detailTextLabel.text = userInput;
            }
            
        }
    }
    
    return cell;
}

// We do the data entry for each field in a seperate view.
// This is because:
// 1) The questions being asked can be very long.
// and
// 2) The form controls displayed can take up a lot of room.
// It just makes sense to devote a full screen to each field
//

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *type = fields[indexPath.section][indexPath.row][kType];
    NSString *typeDescription = fields[indexPath.section][indexPath.row][kTypeDescription];
    
    if ([type isEqualToString:kOpen311_Media]) {
        
        
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
            
//            ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
//            
//            if (status != ALAuthorizationStatusAuthorized) {
//                
//                
//                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted){
//                    if(granted){
//                        NSLog(@"Granted access");
//                    }
//                    else{
//                        NSLog(@"Not Granted access");
//                        
//                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(kUI_PhotosPermissionTitle, nil) message:NSLocalizedString(kUI_PhotosPermission, nil) delegate:nil cancelButtonTitle:NSLocalizedString(kUI_Cancel, nil) otherButtonTitles:nil, nil];
//                        [alert show];
//                        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//                        return;
//                        
//                    }
//                }];
//                
//                
//            }
            
            UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(kUI_ChooseMediaSource, nil)
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:nil, nil];
            [popup setTag:0];
            popup.actionSheetStyle = UIActionSheetStyleBlackOpaque;
            [popup addButtonWithTitle:NSLocalizedString(kUI_Camera,  nil)];
            [popup addButtonWithTitle:NSLocalizedString(kUI_Gallery, nil)];
            [popup addButtonWithTitle:NSLocalizedString(kUI_Cancel,  nil)];
            [popup setCancelButtonIndex:2];
            [popup showFromTabBar:self.tabBarController.tabBar];
        }
    }
    else if ([type isEqualToString:kOpen311_Address])         { [self performSegueWithIdentifier:kSegueToLocation        sender:self]; }
    else if ([type isEqualToString:kOpen311_SingleValueList]) { [self performSegueWithIdentifier:kSegueToSingleValueList sender:self]; }
    else if ([type isEqualToString:kOpen311_MultiValueList])  { [self performSegueWithIdentifier:kSegueToMultiValueList  sender:self]; }
    else if ([type isEqualToString:kOpen311_Text])            { [self performSegueWithIdentifier:kSegueToText            sender:self]; }
    else if ([type isEqualToString:kOpen311_UserInfo])        { [self performSegueWithIdentifier:kSegueToSettings        sender:self]; }
    else if ([type isEqualToString:kOpen311_Datetime])        { [self performSegueWithIdentifier:kSegueToDateTime        sender:self]; }
    else if ([type isEqualToString:kOpen311_Number])
    {
        if([typeDescription isEqualToString:kWholeNumber]){
            [self performSegueWithIdentifier:kSegueToNumber        sender:self];
        }
        else if([typeDescription isEqualToString:kDecimalNumber]){
            [self performSegueWithIdentifier:kSegueToDecimal        sender:self];
        }
    }
    else {
        [self performSegueWithIdentifier:kSegueToString sender:self];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



#pragma mark - Attribute result delegate handlers
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Because we're pushing a new view and responding to delegate
    // calls later on, we need to remember what indexPath we were working on
    // We'll refer to this later, in the delegate response methods
    currentIndexPath = [self.tableView indexPathForSelectedRow];
    
    if([segue.identifier isEqualToString:@"SegueToSettings"]){
        return;
    }
    else{
        [segue.destinationViewController setDelegate:self];
        // If this is data entry for an attribute, send the attribute definition
        if (currentIndexPath.section == 2) {
            NSDictionary *attribute = _report.serviceDefinition[kOpen311_Attributes][currentIndexPath.row];
            [segue.destinationViewController setAttribute:attribute];
            // The fieldname is different from the attribute code.
            // Fieldnames for attributes are in the form of "attribute[code]"
            // It is fieldname that we use as the key for the value in |postData|.
            // |postData| contains the raw key:value pairs we will be sending to the
            // Open311 endpoint
            NSString *fieldname = fields[currentIndexPath.section][currentIndexPath.row][kFieldname];
            [segue.destinationViewController setCurrentValue:_report.postData[fieldname]];
            
        }
        // The only other common field is "description"
        // We're going to have it use the same data entry view that any other
        // text attribute would use
        else {
            NSString *fieldname = fields[currentIndexPath.section][currentIndexPath.row][kFieldname];
            if ([fieldname isEqualToString:kOpen311_Description]) {
                // Create an attribute definition so we can use the same TextController
                // that all the other attribute definitions use
                NSDictionary *attribute = @{
                                            kOpen311_Code       :kOpen311_Description,
                                            kOpen311_Datatype   :kOpen311_Text,
                                            kOpen311_Description:NSLocalizedString(kUI_ReportDescription, nil)
                                            };
                [segue.destinationViewController setAttribute:attribute];
                [segue.destinationViewController setCurrentValue:_report.postData[kOpen311_Description]];
            }
        }
    }
}


-(IBAction)shareReport:(id)sender{
    
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    [popup setTag:1];
    popup.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    
    if ([MFMailComposeViewController canSendMail])
    {
        [popup addButtonWithTitle:@"Email"];
    }
    
    [popup addButtonWithTitle:NSLocalizedString(kUI_Cancel,nil)];
    popup.cancelButtonIndex = popup.numberOfButtons-1;
    [popup showFromTabBar:self.tabBarController.tabBar];
}


// The controllers for String, Text, and SingleValueList will
// call this delegate method when the user clicks "Done"
- (void)didProvideValue:(NSString *)value
{
    NSString *fieldname = fields[currentIndexPath.section][currentIndexPath.row][kFieldname];
    _report.postData[fieldname] = value;
}

- (void)didProvideValues:(NSArray *)values
{
    NSString *fieldname = fields[currentIndexPath.section][currentIndexPath.row][kFieldname];
    _report.postData[fieldname] = values;
}

-(void)didProvideDateValue:(NSDate *)value{
    NSString *fieldname = fields[currentIndexPath.section][currentIndexPath.row][kFieldname];
    _report.postData[fieldname] = value;
}

#pragma mark - Location choosing handlers
- (void)didChooseLocation:(CLLocationCoordinate2D)location
{
    _report.postData[kOpen311_Latitude]  = [NSString stringWithFormat:@"%f", location.latitude];
    _report.postData[kOpen311_Longitude] = [NSString stringWithFormat:@"%f", location.longitude];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude]
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                     /*  if([[placemarks[0] administrativeArea] isEqualToString:@"Puerto Rico"] || [[placemarks[0] administrativeArea] isEqualToString:@"PR"])
                       {*/
                           NSString *address = [NSString stringWithFormat:@"%@ %@ %@ %@", [placemarks[0] name],[placemarks[0] locality],[placemarks[0] administrativeArea],[placemarks[0] postalCode]];
                           _report.postData[kOpen311_AddressString] = address ? address : @"";
                           [self.tableView reloadData];
                   /*    }
                       else{
                           _report.postData[kOpen311_Latitude]  = @"";
                           _report.postData[kOpen311_Longitude] = @"";
                           UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(kUI_OutOfPRTitle, nil) message:NSLocalizedString(kUI_OutOfPRMessage, nil)delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                           [alertView show];
                           _report.postData[kOpen311_AddressString] = @"";
                           [self.tableView reloadData];
                       }*/
                   }];
    
    [self popViewAndReloadTable];
}




#pragma mark - Image choosing handlers
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    switch ([actionSheet tag]){
        case 0:
        {
            if (buttonIndex != 2) {
                if(buttonIndex == 0){
                    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
                    if(authStatus == AVAuthorizationStatusAuthorized)
                    {
                        [self popCamera];
                    }
                    else if(authStatus == AVAuthorizationStatusNotDetermined)
                    {
                        NSLog(@"%@", @"Camera access not determined. Ask for permission.");
                        
                        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
                         {
                             if(granted)
                             {
                                 NSLog(@"Granted access to %@", AVMediaTypeVideo);
                                 [self popCamera];
                             }
                             else
                             {
                                 NSLog(@"Not granted access to %@", AVMediaTypeVideo);
                                 [self camDenied];
                             }
                         }];
                    }
                    
                    else
                    {
                        [self camDenied];
                    }
                }
                else{
                    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
                    
                    if (status == PHAuthorizationStatusAuthorized) {
                        // Access has been granted.
                        [self openPhotos];
                    }
                    
                    else if (status == PHAuthorizationStatusNotDetermined) {
                        
                        // Access has not been determined.
                        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                            
                            if (status == PHAuthorizationStatusAuthorized) {
                                // Access has been granted.
                                [self openPhotos];
                            }
                            
                            else {
                                // Access has been denied.
                                [self photosDenied];
                            }
                        }];  
                    }
                    else  {
                        // Access has been denied.
                        [self photosDenied];
                    }
                    
                    
                
           
                }
               
            }
            break;
        }
        case 1:
        {
            if([actionSheet cancelButtonIndex]!= buttonIndex){
                NSString *serviceDescription	= [_service objectForKey:krst_Service_DescriptionHTML];
                NSString *serviceName			= [_service objectForKey:kOpen311_ServiceName];
                
                MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                mailer.mailComposeDelegate = self;
                [mailer setDelegate:self];
                [mailer setSubject:serviceName];
                
                NSString *emailBody = serviceDescription;
                [mailer setMessageBody:emailBody isHTML:YES];
                
                [self presentModalViewController:mailer animated:YES ];
                
            }
            //[self dismissModalViewControllerAnimated:YES];
            break;
        }
    }
    return;
}

-(void) popCamera{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)openPhotos{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)camDenied
{
    NSLog(@"%@", @"Denied camera access");
    
    NSString *alertText;
    NSString *alertButton;
    
    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings)
    {
        alertText = @"It looks like your privacy settings are preventing us from accessing your camera to do barcode scanning. You can fix this by doing the following:\n\n1. Touch the Go button below to open the Settings app.\n\n2. Touch Privacy.\n\n3. Turn the Camera on.\n\n4. Open this app and try again.";
        
        alertButton = @"Go to Setings";
    }
    else
    {       alertText = @"It looks like your privacy settings are preventing us from accessing your camera to do barcode scanning. You can fix this by doing the following:\n\n1. Close this app.\n\n2. Open the Settings app.\n\n3. Scroll to the bottom and select this app in the list.\n\n4. Touch Privacy.\n\n5. Turn the Camera on.\n\n6. Open this app and try again.";
        
        alertButton = @"OK";
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Error"
                          message:alertText
                          delegate:self
                          cancelButtonTitle:alertButton
                          otherButtonTitles:nil];
    alert.tag = 3491832;
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 3491832 || alertView.tag == 3491833)
    {
        BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
        if (canOpenSettings)
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    
}


- (void)photosDenied
{
    NSLog(@"%@", @"Denied Photo access");
    
    NSString *alertText;
    NSString *alertButton;
    
    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings)
    {
        alertText = @"It looks like your privacy settings are preventing us from accessing your Photos. You can fix this by doing the following:\n\n1. Touch the Go button below to open the Settings app.\n\n2. Touch Privacy.\n\n3. Turn the Camera on.\n\n4. Open this app and try again.";
        
        alertButton = @"Go to Setings";
    }
    else
    {
        alertText = @"It looks like your privacy settings are preventing us from accessing your camera to do barcode scanning. You can fix this by doing the following:\n\n1. Close this app.\n\n2. Open the Settings app.\n\n3. Scroll to the bottom and select this app in the list.\n\n4. Touch Privacy.\n\n5. Turn the Camera on.\n\n6. Open this app and try again.";
        
        alertButton = @"OK";
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Error"
                          message:alertText
                          delegate:self
                          cancelButtonTitle:alertButton
                          otherButtonTitles:nil];
    alert.tag = 3491833;
    [alert show];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
    return;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (info[UIImagePickerControllerMediaMetadata] != nil) {
        // The user took a picture with the camera.
        // We need to save that picture and just use the reference to it from the Saved Photos library.
        [library writeImageToSavedPhotosAlbum:[image CGImage]
                                     metadata:info[UIImagePickerControllerMediaMetadata]
                              completionBlock:^(NSURL *assetURL, NSError *error) {
                                  _report.postData[kOpen311_Media] = assetURL;
                                  [self refreshMediaThumbnail];
                              }];
    }
    else {
        // The user chose an image from the library
        _report.postData[kOpen311_Media] = info[UIImagePickerControllerReferenceURL];
        [self refreshMediaThumbnail];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)refreshMediaThumbnail
{
    [library assetForURL:_report.postData[kOpen311_Media]
             resultBlock:^(ALAsset *asset) {
                 _reportImage = [UIImage imageWithCGImage:[asset aspectRatioThumbnail] ];
                // mediaThumbnail = [UIImage imageWithCGImage:[asset thumbnail]];
                 [self.tableView reloadData];
             }
            failureBlock:^(NSError *error) {
                DLog(@"Failed to load chosen image from library");
            }];
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


@end
