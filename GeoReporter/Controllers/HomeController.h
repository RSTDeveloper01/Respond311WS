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
#import "CoreLocation/CoreLocation.h"

@interface HomeController : UITableViewController <UITabBarControllerDelegate,UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *splashImage;
@property (weak, nonatomic) IBOutlet UILabel *reportLabel;
@property (weak, nonatomic) IBOutlet UILabel *archiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *reportingAsLabel;
@property (weak, nonatomic) IBOutlet UILabel *personalInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

- (void)serviceListReady;

- (void)accountListReady;
- (void)startBusyIcon;
- (void)refreshPersonalInfo;
//- (void)verifyCurrentLocationAndPreferredLocation;
@end
