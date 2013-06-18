//
//  TweetViewController.m
//  TwitterTutorial
//
//  Created by Matthew Liu on 6/18/13.
//  Copyright (c) 2013 Matthew Liu. All rights reserved.
//

#import "TweetViewController.h"

@interface TweetViewController ()
- (IBAction)postToTwitter:(id)sender;

@property (nonatomic) ACAccountStore *accountStore;

@end

@implementation TweetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self fetchTimelineForUser:@"@matthewliu"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Twitter methods

- (BOOL)userHasAccessToTwitter
{

    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
    
}

- (void)fetchTimelineForUser:(NSString *)username
{
    //Step 0: Check that the user has local Twitter accounts
    
    NSLog(@"User has access to Twitter: %c", [self userHasAccessToTwitter]);
    
    if ([self userHasAccessToTwitter]) {
        //Step 1: Obtains access to Twitter accounts
        ACAccountType *twitterAccountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        [_accountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {
            if (granted) {
                
                NSLog(@"Granted: %c", granted);
                
                //Step 2: Create a request
                NSArray *twitterAccounts = [_accountStore accountsWithAccountType:twitterAccountType];
                NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/user_timeline.json"];
                
                NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        @"screen_name", username,
                                        @"include_rts", @"0",
                                        @"trim_user", @"1",
                                        @"count", @"1",
                                        nil];
               
                /*
                NSURL *url2 = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
                NSDictionary *params2 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        @"q", username,
                                        @"count", @"20",
                                        nil];
                */
                
                
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:params];
                NSLog(@"The request is: %@", request);
                
                //attach an account to the request - this is mandatory - normally this is not a clean way to request the right account but this is fine for the example
                [request setAccount:[twitterAccounts lastObject]];
                
                //Step 3: Execute the request
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    if (responseData) {

                        if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300) {
                            NSError *jsonError;
                            NSDictionary *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error: &jsonError];
                            
                            if (timelineData) {
                                NSLog(@"Twitter Server Response: %@\n", timelineData);
                            } else {
                                //Our JSON deserialization went awry
                                NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                            }
                        } else {
                           //The server did not respond successfully... were we rate-limited?
                            NSLog(@"The response status code is %d", [urlResponse statusCode]);
                        }
                    }
                }];
            } else {
                //Access was not granted, or an error occurred
                NSLog(@"%@", [error localizedDescription]);
            }
        }];
    }
}


- (IBAction)postToTwitter:(id)sender
{

    //Create an instance of the Tweet sheet
    SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    //Set the completion handler
    tweetSheet.completionHandler = ^(SLComposeViewControllerResult result) {
        switch (result) {
                //This means the user cancelled without sending th eTweet
            case SLComposeViewControllerResultCancelled:
                break;
            case SLComposeViewControllerResultDone:
                break;
                
            default:
                break;
        }
        
        //dismiss the Tweet Sheet
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:^{
                NSLog(@"Tweet Sheet has been dismissed");
            }];
        });
    };
    
    //Set the initial body of the Tweet
    [tweetSheet setInitialText:@"just setting up my twttr"];
    
    //Adds an image to the Tweet. For demo purposes, asume we have an image named 'larry.png' that we wish to attach
    if (![tweetSheet addImage:[UIImage imageNamed:@"larry.png"]]) {
        NSLog(@"Unable to add the image");
    }
    
    //Adds an image to the Tweet. For demo purposes, asume we have an image named 'larry.png' that we wish to attach
    if (![tweetSheet addURL:[NSURL URLWithString:@"http://twitter.com/"]]) {
        NSLog(@"Unable to add the URL");
    }
    
    //Presents the Tweet Sheet to the user
    [self presentViewController:tweetSheet animated:NO completion:^{
        NSLog(@"Tweet sheet has been presented");
    }];
    
}
@end
