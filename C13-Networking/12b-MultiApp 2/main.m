/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "TwitterOperation.h"
#import "KeychainItemWrapper.h"

#define COOKBOOK_PURPLE_COLOR	[UIColor colorWithRed:0.20392f green:0.19607f blue:0.61176f alpha:1.0f]
#define BARBUTTON(TITLE, SELECTOR) 	[[[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR] autorelease]
#define showAlert(format, ...) myShowAlert(__LINE__, (char *)__FUNCTION__, format, ##__VA_ARGS__)

// Simple Alert Utility
void myShowAlert(int line, char *functname, id formatstring,...)
{
	va_list arglist;
	if (!formatstring) return;
	va_start(arglist, formatstring);
	id outstring = [[[NSString alloc] initWithFormat:formatstring arguments:arglist] autorelease];
	va_end(arglist);
	
    UIAlertView *av = [[[UIAlertView alloc] initWithTitle:outstring message:nil delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil] autorelease];
	[av show];
}

@interface TestBedViewController : UIViewController <UITextFieldDelegate, TwitterOperationDelegate>
{
	IBOutlet UITextField *textField;
	IBOutlet UIActivityIndicatorView *activity;
	KeychainItemWrapper *wrapper;
}
@property (retain) UITextField *textField;
@property (retain) KeychainItemWrapper *wrapper;
@property (retain) UIActivityIndicatorView *activity;
@end

@implementation TestBedViewController
@synthesize textField;
@synthesize wrapper;
@synthesize activity;

- (void) hideButtons
{
	self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.leftBarButtonItem = nil;
}

- (void) showButtons
{
	self.navigationItem.rightBarButtonItem = BARBUTTON(@"Tweet", @selector(tweet:));
	self.navigationItem.leftBarButtonItem = BARBUTTON(@"Settings", @selector(settings:));
}

- (void) doneTweeting : (NSString *) outstring
{
	[self.activity stopAnimating];
	
	if (outstring.length < 60) // probable error
		showAlert(outstring);
	else if ([outstring rangeOfString:@"uthentica"].location != NSNotFound)
		showAlert(@"Failed to authenticate. Please check your user name and password.");
	else
	{
		// probable success
		showAlert(@"Success! Your message was tweeted.");
		self.textField.text = @"";
	}
	
	[self.textField setEnabled:YES];
	[self showButtons];
}

- (void) tweet: (UIBarButtonItem *) bbi
{
	NSString *text = self.textField.text;
	if (!text || (text.length == 0))
	{
		showAlert(@"Please enter text before you tweet.");
		return;
	}
	
	[self.textField resignFirstResponder];
	[self.textField setEnabled:NO];
	[self hideButtons];
	[self.activity startAnimating];
	
	TwitterOperation *operation = [[[TwitterOperation alloc] init] autorelease];
	operation.delegate = self;
	operation.theText = text;
	
	NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
	[queue addOperation:operation];
}

- (void) settings: (UIBarButtonItem *) bbi
{
	SettingsViewController *svc = [[[SettingsViewController alloc] init] autorelease];
	svc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:svc] autorelease];
	[self.navigationController presentModalViewController:nav animated:YES];
}

- (void) viewDidAppear: (BOOL) animated
{
	NSString *uname = [wrapper objectForKey:(id)kSecAttrAccount];
	NSString *pword = [wrapper objectForKey:(id)kSecValueData];
	if (uname && pword)
		self.navigationItem.rightBarButtonItem = BARBUTTON(@"Tweet", @selector(tweet:));
}

- (void) viewDidLoad
{
	self.title = @"iTweet";
	self.wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"SharedTwitter" accessGroup:@"Y93A4XLA79.com.sadun.GenericKeychainSuite"];
	[self.wrapper release];
	self.navigationController.navigationBar.tintColor = COOKBOOK_PURPLE_COLOR;
	self.navigationItem.leftBarButtonItem = BARBUTTON(@"Settings", @selector(settings:));
}
@end

@interface TestBedAppDelegate : NSObject <UIApplicationDelegate>
@end

@implementation TestBedAppDelegate
- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[TestBedViewController alloc] init]];
	[window addSubview:nav.view];
	[window makeKeyAndVisible];
}
@end

int main(int argc, char *argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"TestBedAppDelegate");
	[pool release];
	return retVal;
}
