#import "Message.h"
#import "AppDelegate.h"
#import "AFHTTPClient.h"    
#import "AFJSONRequestOperation.h"
#import "UIDevice+IdentifierAddition.h"
#import "UIImageView+WebCache.h"


//#define SERVER_LINK @"http://ihubot.herokuapp.com"
#define SERVER_LINK @"http://127.0.0.1:8080"

@implementation Message

@dynamic sentDate;
@dynamic text;
@dynamic user;


typedef enum {
    MessageContentTypeText,
    MessageContentTypeGif,
    MessageContentTypeImage,
    MessageContentTypeYouTube
} MessageContentType;


+(AFHTTPClient*) client {

    
    static AFHTTPClient* client = nil;
    @synchronized(self) {
        if (!client){
            
            client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:SERVER_LINK]];
//            [client setDefaultHeader:@"Accept" value:@"application/json"];
            [client setParameterEncoding:AFJSONParameterEncoding];
            [client registerHTTPOperationClass:[AFJSONRequestOperation class]];

            [client setAuthorizationHeaderWithUsername:[[UIDevice currentDevice] uniqueDeviceIdentifier] password:@"no-password"];
            
        }
        return client;
    }
}

+(id)sendMessage:(NSString *)messageText {
    Message * message = [self messageWithText:[self preprocessRequestText:messageText]];
    [message send];
    return message;
}

+(NSString*) preprocessRequestText:(NSString*)text {
    if (![[[[text componentsSeparatedByString:@" "] objectAtIndex:0] lowercaseString] isEqualToString:@"hubot"])
        return [@"hubot " stringByAppendingString:text];
    return text;
}

+(id)messageWithText:(NSString*)text {
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:((AppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    message.text = text;
    message.sentDate = [NSDate date];

    return message;
}

-(void) send {
    self.user = @"me";
    [[[self class] client] postPath:@"/hubot/tell" parameters:@{@"message":self.text} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:&error];
        if (!error) {
            Message * message = [[self class] messageWithText:json[@"message"]];
            message.user = @"hubot";
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        
    }];
}


+(UIView*)viewForURL:(NSURL*) url {
    UIView* view;
    if ([@[@"jpg", @"jpeg", @"png"] containsObject:[url pathExtension]]) {
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImageWithURL:url];
        view = imageView;
    }

    
    return view;
}


-(NSBubbleData*) bubbleData {
    NSBubbleData * bubble;
    
    
    NSBubbleType bubbleType = [self.user isEqualToString:@"me"]?BubbleTypeMine:BubbleTypeSomeoneElse;
    
    
    NSError *error = NULL;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                                               error:&error];
    NSArray* matches = [detector matchesInString:self.text
                                                           options:0
                                                             range:NSMakeRange(0, [self.text length])];
    if (![matches count]) {
        
        bubble = [NSBubbleData dataWithText:self.text date:self.sentDate type:bubbleType];
    } else {
        NSTextCheckingResult *match = matches[0];
//        NSRange matchRange = [match range];
//        if ([match resultType] == NSTextCheckingTypeLink) {
        NSURL *url = [match URL];
        bubble = [NSBubbleData dataWithView:[[self class] viewForURL:url] date:self.sentDate type:bubbleType insets:UIEdgeInsetsMake(10, 10, 10, 10)];

        
    }

    
    return bubble;

}
@end
