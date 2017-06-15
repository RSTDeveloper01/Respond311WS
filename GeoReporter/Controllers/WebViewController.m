//
//  WebViewController.m
//  RESPOND
//
//  Created by RSTDeveloper01 on 4/7/17.
//  Copyright © 2017 Rock Solid Technologies. All rights reserved.
//

#import "WebViewController.h"

@implementation WebViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *temp = _viewURL;
    NSString *fullURL = _viewURL;//@"http://311explorer.nola.gov/main/GERT%2BTOWN/All%2BCategories/All%2BSubcategories/";
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [_viewWeb loadRequest:requestObj];
}

@end
