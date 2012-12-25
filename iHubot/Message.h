#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACConversation;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * user;
+(id)sendMessage:(NSString*) messageText;
@end
