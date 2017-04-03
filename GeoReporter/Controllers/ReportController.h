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
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import "Report.h"
#import "LocationController.h"
#import "TextEntryDelegate.h"
#import "MultiValueDelegate.h"
#import <MessageUI/MessageUI.h>
#import "DateValueDelegate.h"
@interface ReportController : UITableViewController <UINavigationControllerDelegate,
                                                     UIActionSheetDelegate,
                                                     UIImagePickerControllerDelegate,
                                                     LocationChooserDelegate,
                                                     TextEntryDelegate,
                                                     DateEntryDelegate,
                                                     MultiValueDelegate,
                                                    MFMailComposeViewControllerDelegate>
@property NSDictionary *service;
@property (weak, nonatomic) IBOutlet UILabel *personalInfoLabel;
@property Report *report;
@property (strong, nonatomic) IBOutlet UIImageView *reportImage;
- (IBAction)done:(id)sender;
- (IBAction)share:(id)sender;
- (void)postSucceeded;
- (void)postFailed;
- (void)popViewAndReloadTable;
- (void)refreshMediaThumbnail;
@end
