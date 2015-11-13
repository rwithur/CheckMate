//
//  CMGroupChatView.m
//  CheckMate
//
//  Created by Rwithu Menon on 12/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMGroupChatView.h"
#import "CMIncoming.h"
#import "CMOutgoing.h"

#import "Config.h"
#import "MBProgressHUD.h"

#import "JSQMessagesViewController/Model/JSQMessagesBubbleImage.h"
#import "JSQMessagesViewController/Model/JSQMessagesAvatarImage.h"
#import "JSQMessagesViewController/Factories/JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesViewController/Factories/JSQMessagesAvatarImageFactory.h"

#define		COLOR_OUTGOING						HEXCOLOR(0x007AFFFF)
#define		COLOR_INCOMING						HEXCOLOR(0xE6E5EAFF)

@interface CMGroupChatView (){
    NSMutableArray *messages;
    NSMutableArray *items;
    NSMutableArray *chatMates;

    JSQMessagesBubbleImage *bubbleImageOutgoing;
    JSQMessagesBubbleImage *bubbleImageIncoming;
    JSQMessagesAvatarImage *avatarImageBlank;
}
@end

@implementation CMGroupChatView

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self retrieveChatMatesFromParse];
}
- (void) viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = NO;

    self.senderId = [self.currentUser objectId];
    self.senderDisplayName = self.currentUser[@"name"];
    
    items = [[NSMutableArray alloc] init];
    messages = [[NSMutableArray alloc] init];
    chatMates = [[NSMutableArray alloc] init];
    
    JSQMessagesBubbleImageFactory *outgoingBubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    bubbleImageOutgoing = [outgoingBubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.416f green:0.800f blue:0.796f alpha:1.00f]];
    JSQMessagesBubbleImageFactory *incomingBubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularStrokedImage] capInsets:UIEdgeInsetsZero];
    bubbleImageIncoming = [incomingBubbleFactory incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:0.416f green:0.800f blue:0.796f alpha:1.00f]];
    
//    avatarImageBlank = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"chat_blank"] diameter:30.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageDelivered:) name:SINCH_MESSAGE_RECIEVED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageDelivered:) name:SINCH_MESSAGE_SENT object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
}

- (void)retrieveChatMatesFromParse {
    [chatMates removeAllObjects];
    
    PFQuery *query = [PFUser query];
    [query orderByAscending:@"username"];
    [query whereKey:@"secret" equalTo:self.currentUser[@"secret"]];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [query findObjectsInBackgroundWithBlock:^(NSArray *chatMateArray, NSError *error) {
        if (!error) {
            chatMates = [NSMutableArray arrayWithArray:chatMateArray];
            [self loadMessages];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        } else {
            NSLog(@"Error: %@", error.description);
        }
    }];
}

- (void) loadMessages {
    self.automaticallyScrollsToMostRecentMessage = NO;

    PFQuery *query = [PFQuery queryWithClassName:@"ChatMessage"];
    [query whereKey:@"secret" equalTo:self.currentUser[@"secret"]];
    [query orderByDescending:@"timestamp"];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [query findObjectsInBackgroundWithBlock:^(NSArray *chatMessageArray, NSError *error) {
        if (!error) {
            for (int i = 0; i < [chatMessageArray count]; i++) {
                NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
                //filter user for name
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"(name like %@)", chatMessageArray[i][@"name"]];
                NSArray * filteredarray  = [chatMates filteredArrayUsingPredicate:pred];
                [item setObject:[filteredarray[0] objectId] forKey:@"userId"];
                [item setObject:chatMessageArray[i][@"text"] forKey:@"text"];
                [item setObject:chatMessageArray[i][@"name"] forKey:@"name"];
                [item setObject:chatMessageArray[i][@"timestamp"] forKey:@"date"];
                [item setObject:@"text" forKey:@"type"];
                [self insertMessage: item];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            self.automaticallyScrollsToMostRecentMessage = YES;
            [self finishReceivingMessage];
        }
    }];
}

-(void) insertMessage: (NSDictionary *) item {
    CMIncoming *incoming = [[CMIncoming alloc] init];
    JSQMessage *message = [incoming create:item];
    [messages insertObject:message atIndex:0];
    [items insertObject:item atIndex:0];
}

- (void)addMessage:(NSDictionary *)item
{
    CMIncoming *incoming = [[CMIncoming alloc] init];
    JSQMessage *message = [incoming create:item];
    [messages addObject:message];
    [items addObject:item];
}

- (void)messageSend:(NSString *)text
{
    CMOutgoing *outgoing = [[CMOutgoing alloc] init];
    [outgoing send:text withRecipients:chatMates];
    [self.inputToolbar.contentView.textView resignFirstResponder];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self finishSendingMessage];
}

- (void)messageDelivered:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
    PFObject *message = [[notification userInfo] objectForKey:@"message"];
    NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
    [item setObject:@"text" forKey:@"type"];
    [item setObject:message[@"name"] forKey:@"name"];
    [item setObject:message[@"userId"] forKey:@"userId"];
    [item setObject:message[@"text"] forKey:@"text"];
    [item setObject:message[@"timestamp"] forKey:@"date"];
    [self addMessage:item];
    self.automaticallyScrollsToMostRecentMessage = YES;
    [self finishReceivingMessage];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)name date:(NSDate *)date
{
    [self messageSend:text];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return messages[indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
             messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self outgoing:items[indexPath.item]])
    {
        return bubbleImageOutgoing;
    }
    else return bubbleImageIncoming;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
                    avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
        return avatarImageBlank;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
//    if (indexPath.item % 3 == 0)
//    {
        JSQMessage *message = messages[indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
//    }
//    else return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self incoming:items[indexPath.item]])
    {
        JSQMessage *message = messages[indexPath.item];
        if (indexPath.item > 0)
        {
            JSQMessage *previous = messages[indexPath.item-1];
            if ([previous.senderId isEqualToString:message.senderId])
            {
                return nil;
            }
        }
        return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
    }
    else return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = [self outgoing:items[indexPath.item]] ? [UIColor whiteColor] : [UIColor blackColor];
    
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    cell.textView.textColor = color;
    cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName:color};
    
    return cell;
}

#pragma mark - JSQMessages collection view flow layout delegate

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *recentMessage = messages[indexPath.item];
    if (indexPath.item-1>=0) {
        JSQMessage *prevMessage = messages[indexPath.item - 1];
        
        unsigned int flags = NSCalendarUnitHour | NSCalendarUnitMinute;
        NSCalendar* calendar = [NSCalendar currentCalendar];
        NSDateComponents* recentcomponents = [calendar components:flags fromDate:recentMessage.date];
        NSDate* recenttimeOnly = [calendar dateFromComponents:recentcomponents];
        
        NSDateComponents* prevcomponents = [calendar components:flags fromDate:prevMessage.date];
        NSDate* prevtimeOnly = [calendar dateFromComponents:prevcomponents];

        
        if ([recenttimeOnly isEqualToDate: prevtimeOnly]) {
            return 0;
        } else {
            return kJSQMessagesCollectionViewCellLabelHeightDefault;
        }
    } else {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
//    if (indexPath.item % 3 == 0)
//    {
//    }
//    else return 0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self incoming:items[indexPath.item]])
    {
        if (indexPath.item > 0)
        {
            JSQMessage *message = messages[indexPath.item];
            JSQMessage *previous = messages[indexPath.item-1];
            if ([previous.senderId isEqualToString:message.senderId])
            {
                return 0;
            }
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    else return 0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self outgoing:items[indexPath.item]])
    {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    else return 0;
}

#pragma mark - Helper methods

- (BOOL)incoming:(NSDictionary *)item
{
    return ([self.senderId isEqualToString:item[@"userId"]] == NO);
}

- (BOOL)outgoing:(NSDictionary *)item
{
    return ([self.senderId isEqualToString:item[@"userId"]] == YES);
}

@end

