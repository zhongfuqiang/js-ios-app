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
//  JSUIResourceViewController.m
//  Jaspersoft Corporation
//

#import "JSUILoadingView.h"
#import "JasperMobileAppDelegate.h"
#import "JSUIResourceViewController.h"
#import "JSUIRepositoryViewController.h"
#import "JSUIResourceModifyViewController.h"

@interface JSUIResourceViewController()

@property (nonatomic) UIButton *favoriteButton;

@end

@implementation JSUIResourceViewController

@synthesize descriptor;
@synthesize resourceClient;
@synthesize nameCell;
@synthesize labelCell;
@synthesize descriptionCell;
@synthesize typeCell;
@synthesize previewCell;
@synthesize toolsCell;
@synthesize favoriteButton;

#pragma mark -
#pragma mark View lifecycle

#define CONST_Cell_height 44.0f
#define CONST_Cell_Content_width 200.0f
#define CONST_Cell_Label_width 200.0f
#define CONST_Cell_width 280.0f
#define CONST_labelFontSize    12
#define CONST_detailFontSize   15
#define COMMON_SECTION      0
#define TOOLS_SECTION       1
#define PROPERTIES_SECTION  2
#define RESOURCES_SECTION   3

static UIFont *_labelFont;
static UIFont *_detailFont;

- (void)viewDidLoad {	
	if (self.descriptor != nil) {
		self.title = [self.descriptor label];
	}	
	[super viewDidLoad];	
}

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {;
        self.descriptor = nil;
        self.resourceClient = nil;
        resourceLoaded = NO;
        deleting = false;
        
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle: @"Edit" 
                                                                       style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(editClicked:)];
        self.navigationItem.rightBarButtonItem = editButton;
    }

	return self;	
}

- (void)editClicked:(id)sender {
    JSUIResourceModifyViewController *rmvc = [[JSUIResourceModifyViewController alloc] 
                                              initWithNibName:@"JSUIResourceModifyViewController" bundle:nil];
    rmvc.resourceClient = self.resourceClient;
    rmvc.descriptor = self.descriptor;
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"Back" style: UIBarButtonItemStyleBordered target:nil action:nil];    
    [self.navigationItem setBackBarButtonItem:newBackButton];
	[self.navigationController pushViewController:rmvc animated: YES];
}


- (void)requestFinished:(JSOperationResult *)result {
    if (deleting) {
        [JSUILoadingView hideLoadingView];
        
        if (result == nil) {
            UIAlertView *uiView =[[UIAlertView alloc] initWithTitle:@"" 
                                                             message:@"Error deleting the resource"
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok" 
                                                   otherButtonTitles:nil];
            [uiView show];
            return;
        } else {  
            [self resourceDeleted];
            return;
        }                
    } 
    
    if (result == nil) {
		UIAlertView *uiView =[[UIAlertView alloc] initWithTitle:@"" 
                                                         message:@"Error reading the response"
                                                        delegate:nil 
                                               cancelButtonTitle:@"Ok" 
                                               otherButtonTitles:nil];
		[uiView show];
    } else if (result.statusCode >= 400) {
        UIAlertView *uiView = [[UIAlertView alloc] initWithTitle:@""
                                                          message:@"Error reading the response" 
                                                         delegate:nil cancelButtonTitle:@"Ok" 
                                                otherButtonTitles:nil];
		[uiView show];
    } else {		
        if (result.objects.count) {
            self.descriptor = [result.objects objectAtIndex:0];
		}
        resourceLoaded = true;
	}
	
	[[self tableView] reloadData];	
    [JSUILoadingView hideLoadingView];
}


- (void)viewWillAppear:(BOOL)animated {
    [self changeFavoriteButtonUI:self.favoriteButton isResourceInFavorites:[[JasperMobileAppDelegate sharedInstance].favorites 
                                                                            isResourceInFavorites:self.descriptor]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	if (self.descriptor != nil) {
		[self performSelector:@selector(updateTableContent) withObject:nil afterDelay:0.0];
	}
}

- (void)updateTableContent {    
	if ([JSRESTBase isNetworkReachable] && self.resourceClient && self.descriptor != nil) {
		self.navigationItem.title = [NSString stringWithFormat:@"%@", self.descriptor.label];
		
		// Load this view
        [JSUILoadingView showCancelableLoadingInView:self.view restClient:self.resourceClient delegate:self cancelBlock:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
		[JSUILoadingView showLoadingInView:self.view];
        [resourceClient resource:self.descriptor.uriString delegate:self];
	}
}


- (UIFont *)labelFont {
	if (!_labelFont) { 
        _labelFont = [UIFont boldSystemFontOfSize:CONST_labelFontSize];
    }
	return _labelFont;
}

- (UIFont *)detailFont {
	if (!_detailFont) { 
        _detailFont = [UIFont systemFontOfSize:CONST_detailFontSize];
    }
	return _detailFont;
}

- (UITableViewCell *)createCell:(NSString *)cellIdentifier {
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 
                                                    reuseIdentifier:cellIdentifier];
	
	cell.textLabel.numberOfLines = 0;
	cell.textLabel.font = [self labelFont];	
	cell.detailTextLabel.numberOfLines = 0;
	cell.detailTextLabel.font = [self detailFont];	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	return cell;
}


- (int)heightOfCellWithText:(NSString *)text {
	CGSize size = {0,0};
	
	if (text) { 
        size = [text sizeWithFont:[self detailFont]  
                constrainedToSize:CGSizeMake(CONST_Cell_Label_width, 4000) 
							  lineBreakMode:UILineBreakModeWordWrap];
    }
    
	size.height += 10;
	return (size.height < CONST_Cell_height ? CONST_Cell_height : size.height);
}

- (int)heightOfPropertyCellWithLabel:(NSString *)label andText:(NSString *)text {
	CGSize size = {0, 0};
	CGSize sizeLabel = {0, 0};

	if (label && ![label isEqualToString:@""]) 
		sizeLabel = [text sizeWithFont:[self labelFont] 
				constrainedToSize:CGSizeMake(CONST_Cell_width, 4000) 
					lineBreakMode:UILineBreakModeCharacterWrap];

	
	if (text && ![text isEqualToString:@""]) 
		size = [text sizeWithFont:[self detailFont] 
				constrainedToSize:CGSizeMake(CONST_Cell_width, 4000) 
					lineBreakMode:UILineBreakModeCharacterWrap];

	
	
	size.height += 10 + sizeLabel.height;
	return (size.height < CONST_Cell_height ? CONST_Cell_height : size.height);
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section == PROPERTIES_SECTION || (section == RESOURCES_SECTION && resourceLoaded && [descriptor.childResourceDescriptors count] > 0))
	{
		return (CGFloat)22.f; //[tableView sectionHeaderHeight];
	}
	return (CGFloat)0.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	if ([indexPath section] == COMMON_SECTION && indexPath.row == 1) { return [self heightOfCellWithText: [descriptor label]]; }
	if ([indexPath section] == COMMON_SECTION && indexPath.row == 2) { return [self heightOfCellWithText: [descriptor resourceDescription]]; }
	
	if ([indexPath section] == PROPERTIES_SECTION && descriptor.resourceProperties.count) { 
		
		JSResourceProperty *rp = (JSResourceProperty *)[[descriptor resourceProperties] objectAtIndex: indexPath.row];
								  
		return [self heightOfPropertyCellWithLabel: [rp name] andText: [rp value]];
	}
	
	if ([indexPath section] == TOOLS_SECTION) { return 44; }
	
	return [tableView rowHeight];
}


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	NSUInteger baseSections = 2;
	
	baseSections++; // Tools
	baseSections++; // Resource descriptors
    
	return baseSections;
}


// Customize the number of rows in the table view.
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    if (section == PROPERTIES_SECTION)
	{
		return @"Resource properties";
	}
	
	if (section == RESOURCES_SECTION && resourceLoaded && [descriptor.childResourceDescriptors count] > 0)
	{
		return @"Nested resources";
    }
	return @"";
		
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	// Name, Label, Description, type, Preview
	if (descriptor == nil) return 0;
	
	if (section == COMMON_SECTION)
	{
		return 5;
	}
	
	if (section == TOOLS_SECTION)
	{
		return 1;
	}
	
	if (section == PROPERTIES_SECTION)
	{
		return (resourceLoaded ? [[descriptor resourceProperties] count] : 1);
	}
	
	if (section == RESOURCES_SECTION)
	{
		return (resourceLoaded ? [[descriptor childResourceDescriptors] count] : 0);
    }
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([indexPath section] == COMMON_SECTION) {   // User details...
		
		if (indexPath.row == 0) {
			self.nameCell = [tableView dequeueReusableCellWithIdentifier:@"NameCell"];
			if (self.nameCell == nil) {				
				self.nameCell = [self createCell: @"NameCell"];
				self.nameCell.textLabel.text = NSLocalizedString(@"Name", @"");
			}
            if (resourceLoaded) {
                self.nameCell.detailTextLabel.text = [descriptor name];
            }
			
			return self.nameCell;
		}
		else if (indexPath.row == 1) {
			
			self.labelCell = [tableView dequeueReusableCellWithIdentifier:@"LabelCell"];
			if (self.labelCell == nil) {
				self.labelCell = [self createCell: @"LabelCell"];
				self.labelCell.textLabel.text = NSLocalizedString(@"Label", @"");
			}
            if (resourceLoaded) {
                self.labelCell.detailTextLabel.text = [descriptor label];
            }
			
			return self.labelCell;
		}
		else if (indexPath.row == 2) {
			
			self.descriptionCell = [tableView dequeueReusableCellWithIdentifier:@"DescriptionCell"];
			if (self.descriptionCell == nil) {
				self.descriptionCell = [self createCell: @"DescriptionCell"];
				self.descriptionCell.textLabel.text = NSLocalizedString(@"Description", @"");
			}
            if (resourceLoaded) {
                self.descriptionCell.detailTextLabel.text = [descriptor resourceDescription];
            }
			
			return self.descriptionCell;
		}
		else if (indexPath.row == 3) {
			
			self.typeCell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell"];
			if (self.typeCell == nil) {
				self.typeCell = [self createCell: @"TypeCell"];
				self.typeCell.textLabel.text = NSLocalizedString(@"Type", @"");
			}
            if (resourceLoaded) {
                self.typeCell.detailTextLabel.text = [descriptor wsType];
            }
			
			return self.typeCell;
		}
		else if (indexPath.row == 4) {
			
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Type2Cell"];
			if (cell == nil) {
				cell = [self createCell: @"Type2Cell"];
				cell.textLabel.text = NSLocalizedString(@"Resources", @"");
			}

			if (resourceLoaded)
			{
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%d",[descriptor.childResourceDescriptors count]];
			}
            
			return cell;
		}
	}
	else if ([indexPath section] == 1 && !resourceLoaded)
	{
	
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WaitCell"];
		
		
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"WaitCell"];
		
			cell.textLabel.text = @"Loading....";
		}
		
		return cell;
	}
	else if ([indexPath section] == PROPERTIES_SECTION && resourceLoaded)
	{   // User details...
		
		if (indexPath.row < [[descriptor resourceProperties] count])
		{
			JSResourceProperty *rp = [[descriptor resourceProperties] objectAtIndex:indexPath.row];
			
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PropCell"];
			
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"PropCell"];
				
				cell.textLabel.font = [self labelFont];
				cell.detailTextLabel.font = [self detailFont];
				cell.textLabel.lineBreakMode =  UILineBreakModeCharacterWrap;
				cell.textLabel.numberOfLines=0;
				cell.detailTextLabel.lineBreakMode =  UILineBreakModeCharacterWrap;
				cell.detailTextLabel.numberOfLines=0;
				//cell.backgroundColor = [UIColor colorWithRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			cell.textLabel.text = [rp name];
			cell.detailTextLabel.text = [rp value];
			
			return cell;
		}
	}
	else if ([indexPath section] == TOOLS_SECTION) {   // User details...
		
		self.toolsCell = [tableView dequeueReusableCellWithIdentifier:@"ToolsCell"];
		if (self.toolsCell == nil) {
			
            self.toolsCell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"ToolsCell"];

			UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
			backView.backgroundColor = [UIColor clearColor];
			self.toolsCell.backgroundView = backView;
			   
			int buttons = 2; //3;
			int padding = 6;
			int buttonWidth = (self.tableView.frame.size.width -20 -((padding)*(buttons-1))) / buttons;
			
			UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
			CGRect frame = CGRectMake(0, 0, buttonWidth, 40);
			button.frame = frame;
			button.tag = 1;
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self changeFavoriteButtonUI:button isResourceInFavorites:[[JasperMobileAppDelegate sharedInstance].favorites isResourceInFavorites:self.descriptor]];
            
			[button addTarget:self action:@selector(favoriteButtonClicked:forEvent:) forControlEvents:UIControlEventTouchUpInside];
			[button setTag:indexPath.row];
			[self.toolsCell.contentView addSubview:button];
            self.favoriteButton = button;
			
            UIImage *redButtonImage = [UIImage imageNamed:@"red.png"];
			UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
            deleteButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
            [deleteButton setBackgroundImage:redButtonImage forState:UIControlStateNormal];
            [deleteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
			deleteButton.frame = CGRectMake(1*(buttonWidth+padding), 0, buttonWidth, 40);
			deleteButton.tag = 3;
			deleteButton.enabled = YES;
            
			
            [deleteButton addTarget:self action:@selector(deleteButtonPressed:forEvent:) forControlEvents:UIControlEventTouchUpInside];
			[deleteButton setTag:indexPath.row];
			[self.toolsCell.contentView addSubview:deleteButton];            
		}
		return self.toolsCell;
	}
	else if ([indexPath section] == RESOURCES_SECTION) {   // User details...

		static NSString *CellIdentifier = @"ResourceCell";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		}
		
		// Configure the cell.
		JSResourceDescriptor *rd = (JSResourceDescriptor *)[descriptor.childResourceDescriptors objectAtIndex: indexPath.row];
		cell.textLabel.text =  [rd label];
		cell.detailTextLabel.text =  [rd uriString];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;		
		
		return cell;
	}
	// We shouldn't reach this point, but return an empty cell just in case
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];

}

#pragma mark -
#pragma mark Favorite button flow

- (IBAction)favoriteButtonClicked:(id)sender forEvent:(UIEvent *)event {    
    JasperMobileAppDelegate *app = [JasperMobileAppDelegate sharedInstance];
    if (![app.favorites isResourceInFavorites:self.descriptor]) {
        [app.favorites addToFavorites:self.descriptor];
        [self changeFavoriteButtonUI:sender isResourceInFavorites:YES];
    } else {
        [app.favorites removeFromFavorites:self.descriptor];
        [self changeFavoriteButtonUI:sender isResourceInFavorites:NO];
    }
}

- (void)changeFavoriteButtonUI:(UIButton *)button isResourceInFavorites:(BOOL)isResourceInFavorites {
    if (!isResourceInFavorites) {
        [button setTitle:@"Add Favorite" forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"yellow.png"] forState:UIControlStateNormal];
    } else {
        [button setTitle:@"Remove Favorite" forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"gray.png"] forState:UIControlStateNormal];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == COMMON_SECTION) return nil;
	if ([indexPath section] == PROPERTIES_SECTION) return nil;
	if ([indexPath section] == TOOLS_SECTION) return nil;
		
	return indexPath;
	
}



#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.section == RESOURCES_SECTION)
		{
		// If the resource selected is a folder, navigate in the folder....
		JSResourceDescriptor *rd = [descriptor.childResourceDescriptors  objectAtIndex: indexPath.row];
		
		if (rd != nil)
		{		
			JSUIResourceViewController *rvc = [[JSUIResourceViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [rvc setResourceClient: self.resourceClient];
			[rvc setDescriptor: rd];
			[self.navigationController pushViewController: rvc animated: YES];
		}
	}
	
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}



- (IBAction)deleteButtonPressed:(id)sender forEvent:(UIEvent *)event
{
	
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Deleting resource" message:@"Are you sure you want to delete this resource?" delegate:self cancelButtonTitle: @"Cancel" otherButtonTitles: @"Yes, delete!", nil];
    
    [alert setTag: 101]; // A tag to know this is the DELETE alert in the clickedButtonAtIndex...
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( [alertView tag] != 101 ) return;
    
    if (buttonIndex == 1)
    {
        deleting = true;
        [JSUILoadingView showCancelableLoadingInView:self.view restClient:self.resourceClient delegate:self cancelBlock:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
        if ([[JasperMobileAppDelegate sharedInstance].favorites isResourceInFavorites:self.descriptor]) {
            [[JasperMobileAppDelegate sharedInstance].favorites removeFromFavorites:self.descriptor];
        }
        
        [self.resourceClient deleteResource:self.descriptor.uriString delegate:self];
    }    
}

- (void)resourceDeleted
{
    NSArray *viewControllers = [self.navigationController viewControllers];
    JSUIRepositoryViewController *repository = nil;
    for (id viewController in viewControllers){
        if ([viewController isKindOfClass:[JSUIRepositoryViewController class]]) {
            repository = viewController;
            break;
        }
    }
    
    if (repository) {
        NSInteger index = 0;
        for (JSResourceDescriptor *rd in repository.resources) {
            if ([rd.uriString isEqualToString:self.descriptor.uriString]) {
                [repository.resources removeObjectAtIndex:index];
                [repository.tableView reloadData];
                break;
            }
            index++;
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clear {
    [self.navigationController dismissModalViewControllerAnimated:NO];
}

@end
