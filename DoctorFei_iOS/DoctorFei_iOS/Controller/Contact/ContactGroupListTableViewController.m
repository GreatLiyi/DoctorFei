//
//  ContactGroupListTableViewController.m
//  DoctorFei_iOS
//
//  Created by hxx on 1/14/15.
//
//

#import "ContactGroupListTableViewController.h"
#import "ContactViewController.h"
#import "Chat.h"
#import "ChatAPI.h"
#import "ContactDetailViewController.h"
#import <MBProgressHUD.h>
#import <JSONKit.h>
#import "Friends.h"
@interface ContactGroupListTableViewController ()

@end

@implementation ContactGroupListTableViewController
{
    NSArray *groupArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.tableFooterView = [UIView new];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - NetActions
- (void)reloadTableViewData{
    groupArray = [Chat MR_findByAttribute:@"type" withValue:@5];
    [self.tableView reloadData];
}

- (void)fetchChatGroup{
    NSNumber *userId = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"];
    NSDictionary *param = @{
                            @"userid": userId,
                            @"usertype": @2,
                            };
    [ChatAPI getChatGroupWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *dataArray = (NSArray *)responseObject;
        if ([[dataArray firstObject][@"state"]intValue] == 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = [dataArray firstObject][@"msg"];
            [hud hide:YES afterDelay:1.0f];
        }else{
            for (NSDictionary *dict in dataArray) {
                Chat *receiveChat = [Chat MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"type == %@ && chatId == %@", @5, @([dict[@"groupId"] intValue])]];
                if (receiveChat == nil) {
                    receiveChat = [Chat MR_createEntity];
                    receiveChat.chatId = @([dict[@"groupId"] intValue]);
                }
                receiveChat.title = dict[@"name"];
            }
            [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadTableViewData];
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = error.localizedDescription;
        [hud hide:YES afterDelay:1.5f];
    }];
}

- (void)createChatGroupWithUserArray:(NSArray *)userArray {
    NSMutableArray *joinArray = [NSMutableArray array];
    for (Friends *friend in userArray) {
        NSDictionary *friendDict = @{
                                     @"id":friend.userId,
                                     @"type":friend.userType
                                     };
        [joinArray addObject:friendDict];
    }
    NSNumber *userId = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"];
    NSDictionary *param = @{
                            @"userid": userId,
                            @"usertype": @2,
                            @"name": @"未命名",
                            @"joinuserids": [joinArray JSONString],
                            };
    NSLog(@"param: %@",param);
    [ChatAPI setChatGroupWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = error.localizedDescription;
        [hud hide:YES afterDelay:1.5f];
    }];
}

#pragma mark - Actions
- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return groupArray.count + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactGroupListCellIdentifier" forIndexPath:indexPath];
    if (indexPath.row == 0){
        cell.textLabel.text = NSLocalizedString(@"新建群", nil);
        cell.textLabel.textColor = [UIColor colorWithRed:127.0/255 green:203.0/255.0 blue:62.0/255.0 alpha:1.0];
    }else{
        cell.textLabel.text = [groupArray[indexPath.row - 1] title];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0){
        [self performSegueWithIdentifier:@"ContactCreateGroupSequeIdentifier" sender:[tableView cellForRowAtIndexPath:indexPath]];
    }else{
        [self performSegueWithIdentifier:@"ContactGroupDetailSegueIdentifier" sender:indexPath];
    }
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"ContactCreateGroupSequeIdentifier"]) {
        UINavigationController *nav = [segue destinationViewController];
        ContactViewController *contact = nav.viewControllers.firstObject;
        contact.contactMode = ContactViewControllerModeCreateGroup;
        contact.didSelectFriends = ^(NSArray *friends){
            NSLog(@"%@",friends);
            //TODO 创建群
            [self createChatGroupWithUserArray:friends];
        };

    }else if ([segue.identifier isEqualToString:@"ContactGroupDetailSegueIdentifier"]){
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        Chat *selectedChat = groupArray[indexPath.row - 1];
        ContactDetailViewController *vc = [segue destinationViewController];
        [vc setCurrentChat:selectedChat];
    }
}


@end
