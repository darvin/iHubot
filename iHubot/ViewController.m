//
//  ViewController.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

// 
// Images used in this example by Petr Kratochvil released into public domain
// http://www.publicdomainpictures.net/view-image.php?image=9806
// http://www.publicdomainpictures.net/view-image.php?image=1358
//

#import "ViewController.h"
#import "UIBubbleTableView.h"
#import "UIBubbleTableViewDataSource.h"
#import "NSBubbleData.h"
#import "Message.h"
#import "UIImageView+WebCache.h"
#import "OLImageView.h"
#import "LBYouTubePlayerController.h"


@interface NSString (JRStringAdditions)

- (BOOL)containsString:(NSString *)string;
- (BOOL)containsString:(NSString *)string
               options:(NSStringCompareOptions) options;

@end

@implementation NSString (JRStringAdditions)

- (BOOL)containsString:(NSString *)string
               options:(NSStringCompareOptions)options {
    NSRange rng = [self rangeOfString:string options:options];
    return rng.location != NSNotFound;
}

- (BOOL)containsString:(NSString *)string {
    return [self containsString:string options:0];
}

@end

@interface ViewController ()
{
    IBOutlet UIBubbleTableView *bubbleTable;
    IBOutlet UIView *textInputView;
    IBOutlet UITextField *textField;

}

@end

@implementation ViewController
@synthesize managedObjectContext=_managedObjectContext, fetchedResultsController=_fetchedResultsController;
- (void)viewDidLoad
{
    [super viewDidLoad];
    textField.delegate = self;
    
    bubbleTable.bubbleDataSource = self;
    
    // The line below sets the snap interval in seconds. This defines how the bubbles will be grouped in time.
    // Interval of 120 means that if the next messages comes in 2 minutes since the last message, it will be added into the same group.
    // Groups are delimited with header which contains date and time for the first message in the group.
    
    bubbleTable.snapInterval = 120;
    
    // The line below enables avatar support. Avatar can be specified for each bubble with .avatar property of NSBubbleData.
    // Avatars are enabled for the whole table at once. If particular NSBubbleData misses the avatar, a default placeholder will be set (missingAvatar.png)
    
    bubbleTable.showAvatars = NO;
    
    // Uncomment the line below to add "Now typing" bubble
    // Possible values are
    //    - NSBubbleTypingTypeSomebody - shows "now typing" bubble on the left
    //    - NSBubbleTypingTypeMe - shows "now typing" bubble on the right
    //    - NSBubbleTypingTypeNone - no "now typing" bubble
    
    bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
    
    [bubbleTable reloadData];
    
    // Keyboard events
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Message sendMessage:@"hubot help"];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UIBubbleTableViewDataSource implementation

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [[self.fetchedResultsController sections][0] numberOfObjects];
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    Message* message = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    return [self bubbleDataForMessage:message];
}

#pragma mark - Keyboard events

- (void)keyboardDidShow:(NSNotification*)aNotification
{
    [self scrollToBottomAnimated:YES];
}

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    bubbleTable.typingBubble = NSBubbleTypingTypeMe;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    [UIView animateWithDuration:0.2f animations:^{
        
        CGRect frame = textInputView.frame;
        frame.origin.y -= kbSize.height;
        textInputView.frame = frame;
        
        frame = bubbleTable.frame;
        frame.size.height -= kbSize.height;
        bubbleTable.frame = frame;
    }];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{

    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.2f animations:^{
        
        CGRect frame = textInputView.frame;
        frame.origin.y += kbSize.height;
        textInputView.frame = frame;
        
        frame = bubbleTable.frame;
        frame.size.height += kbSize.height;
        bubbleTable.frame = frame;
    }];
}

#pragma mark - Actions

- (IBAction)sayPressed:(id)sender
{
    bubbleTable.typingBubble = NSBubbleTypingTypeSomebody;

    
    [Message sendMessage:textField.text];
    
    textField.text = @"";
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)_textField {
    [self sayPressed:_textField];
    return NO;
}



#pragma mark - NSFetchedResultsControllerDelegate

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) return _fetchedResultsController;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    NSError __autoreleasing *error = nil;
    NSUInteger messagesCount = [_managedObjectContext countForFetchRequest:fetchRequest error:&error];
    NSAssert(messagesCount != NSNotFound, @"-[NSManagedObjectContext countForFetchRequest:error:] error:\n\n%@", error);

    [fetchRequest setFetchBatchSize:10];
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES]]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:@"Message"];
    _fetchedResultsController.delegate = self;
    NSAssert([_fetchedResultsController performFetch:&error], @"-[NSFetchedResultsController performFetch:] error:\n\n%@", error);
    return _fetchedResultsController;
}


- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = [bubbleTable numberOfRowsInSection:0];
    if (numberOfRows) {
        [bubbleTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
//    [bubbleTable beginUpdates];
}
/*
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [bubbleTable insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}*/
 
 

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [bubbleTable endUpdates];
//    [self scrollToBottomAnimated:YES];

    [bubbleTable reloadData];
    [self scrollToBottomAnimated:YES];
}


#pragma mark UITextViewDelegate
/*
- (void)textViewDidChange:(UITextView *)textView {
    // Change height of _tableView & messageInputBar to match textView's content height.
    CGFloat textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - _previousTextViewContentHeight;
    //    NSLog(@"textViewContentHeight: %f", textViewContentHeight);
    
    if (textViewContentHeight+changeInHeight > kChatBarHeight4+2) {
        changeInHeight = kChatBarHeight4+2-_previousTextViewContentHeight;
    }
    
    if (changeInHeight) {
        [UIView animateWithDuration:0.2 animations:^{
            _tableView.contentInset = _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, _tableView.contentInset.bottom+changeInHeight, 0);
            [self scrollToBottomAnimated:NO];
            UIView *messageInputBar = _textView.superview;
            messageInputBar.frame = CGRectMake(0, messageInputBar.frame.origin.y-changeInHeight, messageInputBar.frame.size.width, messageInputBar.frame.size.height+changeInHeight);
        } completion:^(BOOL finished) {
            [_textView updateShouldDrawPlaceholder];
        }];
        _previousTextViewContentHeight = MIN(textViewContentHeight, kChatBarHeight4+2);
    }
    
    // Enable/disable sendButton if textView.text has/lacks length.
    if ([textView.text length]) {
        _sendButton.enabled = YES;
        _sendButton.titleLabel.alpha = 1;
    } else {
        _sendButton.enabled = NO;
        _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
    }
}
*/



-(UIView*)viewForURL:(NSURL*) url {
    UIView* view=nil;
    if ([@[@"jpg", @"jpeg", @"png"] containsObject:[url pathExtension]]) {
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImageWithURL:url];
        view = imageView;
    } else if ([@[@"gif"] containsObject:[url pathExtension]]) {
        OLImageView* imageView = [[OLImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImageWithURL:url];
        view = imageView;
        NSLog(@"%@",url);
    } else if ([[url absoluteString] containsString:@"youtube"]) {
        LBYouTubePlayerController* controller = [[LBYouTubePlayerController alloc] initWithYouTubeURL:[NSURL URLWithString:@"http://www.youtube.com/watch?v=1fTIhC1WSew&list=FLEYfH4kbq85W_CiOTuSjf8w&feature=mh_lolz"] quality:LBYouTubeVideoQualityLarge];
        
        controller.view.frame = CGRectMake(0.0f, 0.0f, 200.0f, 200.0f);
//        [self addChildViewController:controller];
        view = controller.view;
    }
    
    
    
    
    
    return view;
}


-(NSBubbleData*) bubbleDataForMessage:(Message*)message {
    NSBubbleData * bubble;
    
    
    NSBubbleType bubbleType = [message.user isEqualToString:@"me"]?BubbleTypeMine:BubbleTypeSomeoneElse;
    
    
    NSError *error = NULL;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                                               error:&error];
    NSArray* matches = [detector matchesInString:message.text
                                         options:0
                                           range:NSMakeRange(0, [message.text length])];
    if (![matches count]) {
        
        bubble = [NSBubbleData dataWithText:message.text date:message.sentDate type:bubbleType];
    } else {
        NSTextCheckingResult *match = matches[0];
        //        NSRange matchRange = [match range];
        //        if ([match resultType] == NSTextCheckingTypeLink) {
        NSURL *url = [match URL];
        bubble = [NSBubbleData dataWithView:[self viewForURL:url] date:message.sentDate type:bubbleType insets:UIEdgeInsetsMake(10, 10, 10, 10)];
        
        
    }
    
    
    return bubble;
    
}

@end
