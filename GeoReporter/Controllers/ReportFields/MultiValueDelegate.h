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

#import <Foundation/Foundation.h>

@protocol MultiValueDelegate <NSObject>
@required
- (void)didProvideValues:(NSArray *)values;
@end
