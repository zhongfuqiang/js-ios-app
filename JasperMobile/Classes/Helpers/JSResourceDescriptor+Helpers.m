/*
 * Jaspersoft Mobile SDK
 * Copyright (C) 2001 - 2012 Jaspersoft Corporation. All rights reserved.
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
//  JSResourceDescriptor+Helpers.m
//  JasperMobile
//
//  Created by Vlad Zavadskii on 05.09.12.
//  Copyright (c) 2012 Jaspersoft. All rights reserved.
//

#import "JSListItem.h"
#import "JSResourceDescriptor+Helpers.h"

@implementation JSResourceDescriptor (Helpers)

- (NSArray *)listOfItems {
    JSResourceProperty *property = [self propertyByName:[JSConstants sharedInstance].PROP_LOV];
    
	NSMutableArray *listOfItems = [NSMutableArray array];
    
    for (JSResourceProperty *child in property.childResourceProperties) {
        JSListItem *listItem = [[JSListItem alloc] initWithName:(child.value ?: child.name) 
                                                        andValue:child.name];
        [listOfItems addObject:listItem];
    }
	
	return listOfItems;
}

@end