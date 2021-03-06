//
//  MainStreamViewController.m
//  graffiti
//
//  Created by David Fontenot on 5/23/13.
//  Copyright (c) 2013 David Fontenot. All rights reserved.
//

#import "MainStreamViewController.h"

@interface MainStreamViewController ()

@end

@implementation MainStreamViewController
//@synthesize tableView;
//@synthesize tableViewController;
//Need to instantiate an instance of MainStreamTableViewController here
//MainStreamTableViewController *tableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //[self.tableViewController setTableViewController:[self tableView]]
    //[self.view addSubview:tableViewController.tableView];
    self.posts = [NSMutableArray array];
    
    
    //Just another example of nsmutablearray being implemented
    //NSMutableArray *blah1 = [[NSMutableArray alloc] init];
    //[blah1 addObject:@"blahblahblah"];
    
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary<FBGraphUser> *user,
           NSError *error) {
             if (!error) {
                 NSLog(@"Workin");
                 NSUserDefaults *userInfo = [NSUserDefaults standardUserDefaults];
                 NSMutableDictionary *userProfile = [NSMutableDictionary dictionaryWithCapacity:5];
                 
                 userProfile[@"facebookId"] = user.id;
                 userProfile[@"name"] = user.name;
                 //myMutableString = user.name;
                 userProfile[@"location"] = user.location;
                 //userProfile[@"gender"] = user.gender;
                 userProfile[@"birthday"] = user.birthday;
                 //userProfile[@"relationship"] = userData[@"relationship_status"];
                 NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", user.id]];
                 userProfile[@"pictureURL"] = [pictureURL absoluteString];
                 
                 NSMutableArray *myData = [NSMutableArray arrayWithObjects:user.id, user.name, nil];
                 
                 [userInfo setObject:myData forKey:@"myData"];
                 [userInfo synchronize];
                 
                 [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
                 [[PFUser currentUser] saveInBackground];
             }
         }];
    }
    
    if (FBSession.activeSession.isOpen) {
        // Issue a Facebook Graph API request to get your user's friend list
        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // result will contain an array with your user's friends in the "data" key
                NSArray *friendObjects = [result objectForKey:@"data"];
                //[userInfo setObject:friendObjects forKey:@"friendData"];
                //NSLog(@"%@", [[[userInfo objectForKey:@"friendData"] objectAtIndex:1] objectForKey:@"id"]);
                NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
                NSMutableArray *facebookFriends = [[NSMutableArray alloc] initWithCapacity:friendObjects.count];
                // Create a list of friends' Facebook IDs + 
                for (NSDictionary *friendObject in friendObjects) {
                    [friendIds addObject:[friendObject objectForKey:@"id"]];
                    [facebookFriends addObject:[NSMutableArray arrayWithObjects:[friendObject objectForKey:@"id"],[friendObject objectForKey:@"name"],nil]];
                    //[userInfo setObject:friendObject forKey:@"friend"];
                }
                NSUserDefaults *userInfo = [NSUserDefaults standardUserDefaults];
                [userInfo setObject:facebookFriends forKey:@"friendData"];
                //Saving the userInfo to persistent storage
                [userInfo synchronize];
                
                [[PFUser currentUser] setObject:friendIds forKey:@"friends"];
                [[PFUser currentUser] saveInBackground];
                
                // Construct a PFUser query that will find friends whose facebook ids
                // are contained in the current user's friend list.
                PFQuery *friendQuery = [PFQuery queryWithClassName:@"Post"];
                [friendQuery whereKey:@"postedAboutID" containedIn:friendIds];
                
                // findObjects will return a list of posts about friends
                // of the current user
                
                //LOOP THROUGH ENTIRE friendPosts NSArray HERE and add posts to self.posts
                NSArray *friendPosts = [friendQuery findObjects];
                for (NSDictionary *onePost in friendPosts) {
                    NSLog(@"%@", [onePost objectForKey:@"text"]);
                    [self.posts addObject:[NSMutableArray arrayWithObjects:[onePost objectForKey:@"text"], [onePost objectForKey:@"postedAboutID"], nil]];
                }
                
                //Reload table so it all shows up
                [self->_tableView reloadData];
            }
        }];
        
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //Saving the userInfo to persistent storage
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.posts count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSMutableArray *blah = [[self.posts objectAtIndex:indexPath.row] mutableCopy];
    
    NSString *MyURL = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", [blah objectAtIndex:1]];
    //UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:MyURL]]];
    
    // Set up the cell...
    //cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
    [cell.imageView setImageWithURL:[NSURL URLWithString:MyURL] placeholderImage:[UIImage imageNamed:@"loading.png"]];
    cell.textLabel.text = [blah objectAtIndex:0];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// open a alert with an OK and cancel button
	NSString *alertString = [NSString stringWithFormat:@"Clicked on row #%d", [indexPath row]];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertString message:@"" delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil];
	[alert show];
}

@end
