#import "AccountsController.h"
#import "AccountController.h"
#import "AccountFormController.h"
#import "GHAccount.h"
#import "GHUser.h"
#import "UserCell.h"
#import "NSString+Extensions.h"
#import "NSMutableArray+Extensions.h"
#import "iOctocat.h"


@interface AccountsController ()
@property(nonatomic,retain)NSMutableArray *accounts;
@property(nonatomic,readonly)AuthenticationController *authController;

- (void)editAccountAtIndex:(NSUInteger)theIndex;
- (void)openAccount:(GHAccount *)theAccount;
- (void)openOrAuthenticateAccountAtIndex:(NSUInteger)theIndex;
@end


@implementation AccountsController

@synthesize accounts;

+ (void)saveAccounts:(NSMutableArray *)theAccounts {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setValue:theAccounts forKey:kAccountsDefaultsKey];
	[defaults synchronize];
}

- (void)dealloc {
	[accounts release], accounts = nil;
	[authController release], authController = nil;
    [userCell release], userCell = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *currentAccounts = [defaults objectForKey:kAccountsDefaultsKey];
	self.accounts = currentAccounts != nil ?
		[NSMutableArray arrayWithArray:currentAccounts] :
		[NSMutableArray array];

	// Open account if there is only one
	if (accounts.count == 1) {
		[self openOrAuthenticateAccountAtIndex:0];
	}
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[self.tableView reloadData];
}

#pragma mark Accounts

- (BOOL (^)(id obj, NSUInteger idx, BOOL *stop))blockTestingForLogin:(NSString*)theLogin {
    return [[^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj objectForKey:kLoginDefaultsKey] isEqualToString:theLogin]) {
			*stop = YES;
			return YES;
        }
        return NO;
    } copy] autorelease];
}

#pragma mark Actions

- (void)editAccountAtIndex:(NSUInteger)theIndex {
	AccountFormController *viewController = [[AccountFormController alloc] initWithAccounts:accounts andIndex:theIndex];
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

- (IBAction)addAccount:(id)sender {
	[self editAccountAtIndex:NSNotFound];
}

- (void)openOrAuthenticateAccountAtIndex:(NSUInteger)theIndex {
	NSDictionary *accountDict = [accounts objectAtIndex:theIndex];
	GHAccount *account = [GHAccount accountWithDict:accountDict];
	[iOctocat sharedInstance].currentAccount = account;
	if (account.user.isAuthenticated) {
		[self openAccount:account];
	} else {
		[self.authController authenticateAccount:account];
	}
}

- (void)openAccount:(GHAccount *)theAccount {
	AccountController *viewController = [[AccountController alloc] initWithAccount:theAccount];
	[iOctocat sharedInstance].currentAccount = theAccount;
	[iOctocat sharedInstance].accountController = viewController;
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return accounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UserCell *cell = (UserCell *)[tableView dequeueReusableCellWithIdentifier:kUserCellIdentifier];
	if (cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"UserCell" owner:self options:nil];
		cell = userCell;
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	NSDictionary *accountDict = [accounts objectAtIndex:indexPath.row];
	NSString *login = [accountDict objectForKey:kLoginDefaultsKey];
    cell.user = [[iOctocat sharedInstance] userWithLogin:login];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self openOrAuthenticateAccountAtIndex:indexPath.row];
}

#pragma mark Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		[accounts removeObjectAtIndex:indexPath.row];
		[self.class saveAccounts:accounts];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }  
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromPath toIndexPath:(NSIndexPath *)toPath {
	[accounts moveObjectFromIndex:fromPath.row toIndex:toPath.row];
	[self.class saveAccounts:accounts];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self editAccountAtIndex:indexPath.row];
}

#pragma mark Authentication

- (AuthenticationController *)authController {
    if (!authController) authController = [[AuthenticationController alloc] initWithDelegate:self];
    return authController;
}

- (void)authenticatedAccount:(GHAccount *)theAccount {
	if (theAccount.user.isAuthenticated) {
		[self openAccount:theAccount];
	} else {
		[iOctocat reportError:@"Authentication failed" with:@"Please ensure that you are connected to the internet and that your credentials are correct"];
		NSUInteger index = [accounts indexOfObjectPassingTest:[self blockTestingForLogin:theAccount.login]];
		[self editAccountAtIndex:index];
	}
}

#pragma mark Autorotation

- (BOOL)shouldAutorotate {
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return [self shouldAutorotate];
}

@end
