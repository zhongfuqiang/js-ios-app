/*
 * JasperMobile for iOS
 * Copyright (C) 2011 - 2013 Jaspersoft Corporation. All rights reserved.
 * http://community.jaspersoft.com/project/jaspermobile-ios
 *
 * Unless you have purchased a commercial license agreement from Jaspersoft,
 * the following license terms apply:
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/lgpl>.
 */

//
//  JMCancelRequestPopup.m
//  Jaspersoft Corporation
//

#import "JMCancelRequestPopup.h"
#import "JMLocalization.h"
#import "JMUtils.h"
#import "UIViewController+MJPopupViewController.h"
#import "JMRequestDelegate.h"
#import <QuartzCore/QuartzCore.h>

static NSString * const kJMCancelRequestPopupNib = @"JMCancelRequestPopup";

static JMCancelRequestPopup *instance;

@interface JMCancelRequestPopup ()
@property (nonatomic, strong) JSRESTBase *restClient;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, copy) JMCancelRequestBlock cancelBlock;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UILabel *progressLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewController:(UIViewController *)viewController restClient:(JSRESTBase *)restClient cancelBlock:(JMCancelRequestBlock)cancelBlock;
@end

@implementation JMCancelRequestPopup

#pragma mark - Class Methods

+ (void)presentInViewController:(UIViewController *)viewController message:(NSString *)message restClient:(JSRESTBase *)client cancelBlock:(JMCancelRequestBlock)cancelBlock
{
    instance = [[JMCancelRequestPopup alloc] initWithNibName:kJMCancelRequestPopupNib
                                                      bundle:nil
                                              viewController:viewController
                                                  restClient:client
                                                 cancelBlock:cancelBlock];
    
    [instance.cancelButton setTitle:JMCustomLocalizedString(@"dialog.button.cancel", nil) forState:UIControlStateNormal];
    instance.progressLabel.text = JMCustomLocalizedString(message, nil);
    
    [viewController presentPopupViewController:instance animationType:MJPopupViewAnimationFade];
}

+ (void)dismiss
{
    if (instance) {
        [JMUtils hideNetworkActivityIndicator];
        [instance.viewController dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
        // Remove all targets for cancel button before releasing instance (instance = nil)
        // to avoid memory issue: when click is performed but instance was released already
        [instance.cancelButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        instance = nil;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.layer.cornerRadius = 5.0f;
}

#pragma mark - Actions

- (IBAction)cancelRequests:(id)sender
{
    [self.restClient cancelAllRequests];
    [JMRequestDelegate clearRequestPool];
    [self.viewController dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    
    if (self.cancelBlock) {
        self.cancelBlock();
    }

    [JMCancelRequestPopup dismiss];
}

#pragma mark - Private

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewController:(UIViewController *)viewController restClient:(JSRESTBase *)restClient cancelBlock:(JMCancelRequestBlock)cancelBlock
{
    self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.restClient = restClient;
        self.viewController = viewController;
        self.cancelBlock = cancelBlock;
    }
    
    return self;
}

@end
