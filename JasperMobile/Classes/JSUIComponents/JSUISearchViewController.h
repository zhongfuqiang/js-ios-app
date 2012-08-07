/*
 * Jaspersoft Mobile SDK
 * Copyright (C) 2001 - 2011 Jaspersoft Corporation. All rights reserved.
 * http://www.jasperforge.org/projects/mobile
 *
 * Unless you have purchased a commercial license agreement from Jaspersoft,
 * the following license terms apply:
 *
 * This program is part of Jaspersoft Mobile SDK.
 *
 * Jaspersoft Mobile SDK is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Jaspersoft Mobile SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Jaspersoft Mobile. If not, see <http://www.gnu.org/licenses/>.
 */

//
//  JSUISearchViewController.h
//  Jaspersoft
//
//  Created by Giulio Toffoli on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <jasperserver-mobile-sdk-ios/JSClient.h>


@interface JSUISearchViewController : UIViewController  <JSResponseDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    UISearchBar *searchBar;
    UITableView *tableView;
    
}
@property (nonatomic, retain) JSResourceDescriptor *descriptor;
@property (nonatomic, retain) JSClient *client;
@property (nonatomic, retain) NSMutableArray *resources;


@end