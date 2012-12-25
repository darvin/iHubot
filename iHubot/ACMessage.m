#import "ACMessage.h"
#import "AppDelegate.h"
@implementation ACMessage

@dynamic sentDate;
@dynamic text;
+(id)sendMessage:(NSString *)messageText {
    ACMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"ACMessage" inManagedObjectContext:((AppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    message.text = messageText;
    message.sentDate = [NSDate date];
    return message;
}
@end
