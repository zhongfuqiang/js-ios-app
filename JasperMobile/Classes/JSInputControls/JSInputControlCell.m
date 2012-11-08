/*
 * JasperMobile for iOS
 * Copyright (C) 2005 - 2012 Jaspersoft Corporation. All rights reserved.
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
//  JSInputControlCell.m
//  Jaspersoft Corporation
//

#import "JSInputControlCell.h"
#import "JSListSelectorViewController.h"
#import "JSDateTimeSelectorViewController.h"
#import "JSBooleanInputControlCell.h"
#import "JSTextInputControlCell.h"
#import "JSNumberInputControlCell.h"
#import "JSDateInputControlCell.h"
#import "JSDateTimeInputControlCell.h"
#import "JSSingleSelectListInputControlCell.h"
#import "JSMultiselectListInputControlCell.h"


// Left and right padding
@interface TargetAction : NSObject 

@property ( nonatomic) id target;
@property (nonatomic) SEL action;

@end

@implementation TargetAction
@synthesize target,action;
@end

@implementation JSInputControlCell

@synthesize descriptor;
@synthesize selectedValue;
@synthesize nameLabel;
@synthesize tableViewController;
@synthesize dataSourceUri;
@synthesize resourceClient;

+ (id)inputControlWithDescriptor:(JSResourceDescriptor *)rd tableViewController:(UITableViewController *)tv 
                   dataSourceUri:(NSString *)dsUri resourceClient:(JSRESTResource *)resourceClient {
    JSConstants *constants = [JSConstants sharedInstance];    
    NSInteger inputControlType = [[rd propertyByName:constants.PROP_INPUTCONTROL_TYPE].value integerValue] ?: constants.IC_TYPE_BOOLEAN;    
	JSInputControlCell *ic = nil;	
    
	if (inputControlType == constants.IC_TYPE_BOOLEAN) {
		ic = [[JSBooleanInputControlCell alloc] initWithDescriptor:rd tableViewController:tv];
	} else if (inputControlType == constants.IC_TYPE_SINGLE_VALUE) {		
		// Check the data type
		JSResourceDescriptor *datatTypeDescriptor = [self findDataType:rd forResourceClient:resourceClient];
        
		NSInteger dataType = [[datatTypeDescriptor propertyByName:constants.PROP_DATATYPE_TYPE].value integerValue] ?: constants.DT_TYPE_TEXT;
        
        if (dataType == constants.DT_TYPE_TEXT) {
			ic = [[JSTextInputControlCell alloc] initWithDescriptor:rd tableViewController:tv];
		} else if (dataType == constants.DT_TYPE_NUMBER) {
			ic = [[JSNumberInputControlCell alloc] initWithDescriptor:rd tableViewController:tv];
		} else if (dataType == constants.DT_TYPE_DATE) {
			ic = [[JSDateInputControlCell alloc] initWithDescriptor:rd tableViewController:tv];
		} else if (dataType == constants.DT_TYPE_DATE_TIME) {
			ic = [[JSDateTimeInputControlCell alloc] initWithDescriptor:rd tableViewController:tv];
		}
	} else if (inputControlType == constants.IC_TYPE_SINGLE_SELECT_LIST_OF_VALUES ||
               inputControlType == constants.IC_TYPE_SINGLE_SELECT_LIST_OF_VALUES_RADIO ||
               inputControlType == constants.IC_TYPE_SINGLE_SELECT_QUERY ||
               inputControlType == constants.IC_TYPE_SINGLE_SELECT_QUERY_RADIO)	{
        ic = [[JSSingleSelectListInputControlCell alloc] initWithDescriptor:rd 
                                                    tableViewController:tv 
                                                          dataSourceUri:dsUri 
                                                         resourceClient:resourceClient];
	} else if (inputControlType == constants.IC_TYPE_MULTI_SELECT_LIST_OF_VALUES ||
			   inputControlType == constants.IC_TYPE_MULTI_SELECT_LIST_OF_VALUES_CHECKBOX ||
			   inputControlType == constants.IC_TYPE_MULTI_SELECT_QUERY ||
			   inputControlType == constants.IC_TYPE_MULTI_SELECT_QUERY_CHECKBOX) {
        ic = [[JSMultiselectListInputControlCell alloc] initWithDescriptor:rd 
                                                   tableViewController:tv 
                                                         dataSourceUri:dsUri 
                                                        resourceClient:resourceClient];
	}
	
	if (ic == nil) ic = [[JSInputControlCell alloc] initWithDescriptor:rd tableViewController:tv];
    ic.resourceClient = resourceClient;
    return ic;	
}


- (id)initWithDescriptor:(JSResourceDescriptor *)rd tableViewController: (UITableViewController *)tv
{
	return [self initWithDescriptor:rd tableViewController:tv dataSourceUri: nil];
}


- (id)initWithDescriptor:(JSResourceDescriptor *)rd tableViewController: (UITableViewController *)tv dataSourceUri: (NSString *)dsUri
{
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil]))
	{
		self.descriptor = rd;
		tableViewController = tv;
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.dataSourceUri = dsUri;
		targetActionsOnChange = [[NSMutableArray alloc] initWithCapacity: 0];
		dependetByInputControls = [[NSMutableArray alloc] initWithCapacity:0];
		
		height = 44.0f; // standard height.
		[self createNameLabel];
	}
	
	return self;
}


// create the label to display the input control name
-(void)createNameLabel
{
	nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(JS_CELL_PADDING, 10.0, JS_LBL_DEFAULT_WIDTH, 21.0)];
	//[self.nameLabel.layer setBorderColor: [UIColor grayColor].CGColor];
	//[self.nameLabel.layer setBorderWidth: 1.0];
	
	[self addSubview: nameLabel];

	self.nameLabel.font = [UIFont systemFontOfSize:14.0];
	if (self.mandatory)
	{
		self.nameLabel.font = [UIFont boldSystemFontOfSize:14.0];
	}
	self.nameLabel.textColor = [UIColor blackColor];
	//self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
	self.nameLabel.autoresizingMask = UIViewAutoresizingNone;
	self.nameLabel.text = self.descriptor.label;
    self.nameLabel.backgroundColor = [UIColor clearColor];
	
	if (self.readonly)
	{
		self.nameLabel.textColor = [UIColor grayColor];
	}
}


- (void)cellDidSelected {
    
}

// Find the data type of this input control.
// The data type is always the first data type descriptor (if any)
///~ @TODO
+ (JSResourceDescriptor *)findDataType:(JSResourceDescriptor *)rd forResourceClient:(JSRESTResource *)resourceClient  {
	// The data type is always the first child of an input control
	JSResourceDescriptor *dataTypeDescriptor =  [rd.childResourceDescriptors objectAtIndex:0];
    JSConstants *constants = [JSConstants sharedInstance];
	
	// But it could be just a reference to another resource in the repository
	if ([dataTypeDescriptor.wsType isEqualToString:constants.WS_TYPE_REFERENCE] ) {
        
        ///~ @TODO
		// Load this resource descriptor
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSString *propUri = [dataTypeDescriptor propertyByName:constants.PROP_FILERESOURCE_REFERENCE_URI].value;        
        __block JSOperationResult *syncResult = nil;
        __block BOOL requestFinished = NO;
        
        [resourceClient resource:propUri usingBlock:^(JSRequest *request) {
            request.finishedBlock = ^(JSOperationResult *result) {
                syncResult = result;
                requestFinished = YES;
//                dispatch_semaphore_signal(semaphore);
            };
        }];
        
//        while (requestFinished != YES);
        
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//        dispatch_release(semaphore);
		
		if (syncResult != nil && syncResult.objects.count > 0) {
			dataTypeDescriptor = [syncResult.objects objectAtIndex:0];
		}
	}
	
	return dataTypeDescriptor;
}


- (BOOL)mandatory {
    NSString *mandatory = [descriptor propertyByName:[JSConstants sharedInstance].PROP_INPUTCONTROL_IS_MANDATORY].value ?: @"";
    return [mandatory isEqualToString:@"true"];
}

- (BOOL)readonly {
    NSString *readonly = [descriptor propertyByName:[JSConstants sharedInstance].PROP_INPUTCONTROL_IS_READONLY].value ?: @"";
    return [readonly isEqualToString:@"true"];
}

- (BOOL)selectable {
	return !self.readonly;
}

- (void)setSelectedValue:(id)vals {
	if (selectedValue ==  vals) return;
	selectedValue = vals;
	
	for (int i = 0; i < [targetActionsOnChange count]; ++i) {
		TargetAction *ta = (TargetAction *)[targetActionsOnChange objectAtIndex:i];
        if ([[ta target] respondsToSelector:[ta action]]) {
            [[ta target] performSelector:[ta action] withObject:self];
        }
	}
}

- (CGFloat)height {
	return height;
}

- (NSArray *)findParameters:(NSString *)query prefix:(NSString *)prefix postfix:(NSString *)postfix func:(BOOL)isFunction {
	NSMutableArray *paramNames = [NSMutableArray array];
	
	if (query != nil) {
		query = [query copy];
		// 1. check for $P parameters...
		
		NSString *tmpQuery = [NSString stringWithString:query]; // copy of the string...
        
		while ([tmpQuery length] > 2) {
			NSRange textRange;
			textRange =[tmpQuery rangeOfString: prefix];
            
			if(textRange.location != NSNotFound) {
				tmpQuery = [tmpQuery substringFromIndex:textRange.location + textRange.length];
				// find the next bracket;
				textRange =[tmpQuery rangeOfString: postfix];
                
				if (textRange.location != NSNotFound) {
					NSString *param = [tmpQuery substringToIndex: textRange.location];
					
					if (isFunction) {
                        // in this case param contains something like: FUNC, field, param name
                        NSArray *chunks = [param componentsSeparatedByString: @","];
                        if (chunks != nil && [chunks count] == 3) {
                            param = [chunks objectAtIndex:2];
                        } else {
                            param = nil;
                        }
                    }
					
					if (param != nil) {
						[paramNames addObject:[param stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
					}
					tmpQuery = [tmpQuery substringFromIndex:textRange.location + textRange.length];
				}
			} else {
				break;
			}
		}
	}
	
	return paramNames;
}

- (NSArray *)dependsBy {
	NSMutableArray *paramNames = [NSMutableArray array];
	// 1. Look for a query object
	for (int i = 0; i < self.descriptor.childResourceDescriptors.count; ++i) {
		JSResourceDescriptor *rd = (JSResourceDescriptor *)[self.descriptor.childResourceDescriptors objectAtIndex:i];
		if ([[rd wsType] isEqualToString: [JSConstants sharedInstance].WS_TYPE_QUERY]) {
			// Find the query string
			NSString *query = [rd propertyByName:[JSConstants sharedInstance].PROP_QUERY].value;
			
			// 1. check for $P parameters
			[paramNames addObjectsFromArray: [self findParameters:query prefix:@"$P{" postfix: @"}" func: NO]];
			[paramNames addObjectsFromArray: [self findParameters:query prefix:@"$P!{" postfix: @"}" func: NO]];
			[paramNames addObjectsFromArray: [self findParameters:query prefix:@"$X{" postfix: @"}" func: YES]];
		}
	}
    
	if ([paramNames count] > 0) return paramNames;
	return nil;
}

- (void)reloadInputControlQueryData:(NSDictionary *)parameters {
	return;
}

- (void)addTarget:(id)aTarget withAction:(SEL)anAction {
	if (aTarget == nil) return;
	if (aTarget == self) return;
	if (anAction == nil) return;
	TargetAction *ta = [[TargetAction alloc] init];	
	ta.target = aTarget;
	ta.action = anAction;	
	[targetActionsOnChange addObject:ta];
}

- (void)addDependency:(JSInputControlCell *)inputControlCell {
	if (inputControlCell == nil) return; // Do nothing.

	if (![dependetByInputControls containsObject:inputControlCell]) {
		[dependetByInputControls addObject:inputControlCell];
	}
	
	[inputControlCell addTarget:self withAction: @selector(updateInputControl:)];
}

- (void)updateInputControl:(id)sender {
	// Force inputcontrols to reload the data
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	
	for (int i = 0; i < [dependetByInputControls count]; ++i) {
		JSInputControlCell *ic = (JSInputControlCell *)[dependetByInputControls objectAtIndex:i];
		if ([ic selectedValue] != nil) {
			id value = [ic selectedValue];
			NSString *name = [[ic descriptor] name];			
			[parameters setValue:value forKey:name];
		}
	} 	
	[self reloadInputControlQueryData:parameters];	
}

@end