//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ArchiveView.h"
#import "ArchiveCell.h"
#import "ChatView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ArchiveView()
{
	SWTableViewCell *lastCell;

	RLMResults *dbrecents;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ArchiveView

@synthesize searchBar;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"Archived Chats";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"ArchiveCell" bundle:nil] forCellReuseIdentifier:@"ArchiveCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableFooterView = [[UIView alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadRecents];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillAppear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView reloadData];
}

#pragma mark - Realm methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadRecents
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *text = searchBar.text;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isArchived == YES AND isDeleted == NO AND description CONTAINS[c] %@", text];
	dbrecents = [[DBRecent objectsWithPredicate:predicate] sortedResultsUsingProperty:FRECENT_LASTMESSAGEDATE ascending:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView reloadData];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)unarchiveRealm:(DBRecent *)dbrecent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	dbrecent.isArchived = NO;
	[realm commitWriteTransaction];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)deleteRealm:(DBRecent *)dbrecent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	dbrecent.isDeleted = YES;
	[realm commitWriteTransaction];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChat:(NSDictionary *)dictionary
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ChatView *chatView = [[ChatView alloc] initWith:dictionary];
	[self.navigationController pushViewController:chatView animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionUnarchive:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBRecent *dbrecent = dbrecents[index];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self unarchiveRealm:dbrecent];
	[Recent unarchiveItem:dbrecent.objectId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self performSelector:@selector(delayedReload) withObject:nil afterDelay:0.25];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDelete:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBRecent *dbrecent = dbrecents[index];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self deleteRealm:dbrecent];
	[Recent deleteItem:dbrecent.objectId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self performSelector:@selector(delayedReload) withObject:nil afterDelay:0.25];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)delayedReload
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.tableView reloadData];
}

#pragma mark - UIScrollViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.view endEditing:YES];
}

#pragma mark - Table view data source

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return 1;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [dbrecents count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ArchiveCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArchiveCell" forIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	cell.leftUtilityButtons = nil;
	cell.rightUtilityButtons = [self rightButtons];
	cell.delegate = self;
	cell.tag = indexPath.row;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	DBRecent *dbrecent = dbrecents[indexPath.row];
	[cell bindData:dbrecent];
	[cell loadImage:dbrecent TableView:tableView IndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return cell;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSArray *)rightButtons
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSMutableArray *rightUtilityButtons = [NSMutableArray new];
	[rightUtilityButtons sw_addUtilityButtonWithColor:HEXCOLOR(0x3E70A7FF) title:@"Unarchive"];
	[rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor redColor] title:@"Delete"];
	return rightUtilityButtons;
}

#pragma mark - SWTableViewCellDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[cell hideUtilityButtonsAnimated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (index == 0) [self actionUnarchive:cell.tag];
	if (index == 1) [self actionDelete:cell.tag];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (state == kCellStateRight) lastCell = cell;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return YES;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return YES;
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ((lastCell == nil) || [lastCell isUtilityButtonsHidden])
	{
		DBRecent *dbrecent = dbrecents[indexPath.row];
		NSDictionary *dictionary = [Chat restartRecent:dbrecent];
		[self actionChat:dictionary];
	}
	else [lastCell hideUtilityButtonsAnimated:YES];
}

#pragma mark - UISearchBarDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self loadRecents];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar setShowsCancelButton:YES animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar setShowsCancelButton:NO animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	[self loadRecents];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar resignFirstResponder];
}

@end

