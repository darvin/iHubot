#import "Message.h"
#import "AppDelegate.h"
#import "AFHTTPClient.h"    
#import "AFJSONRequestOperation.h"
#import "UIDevice+IdentifierAddition.h"


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
            [[NSUserDefaults standardUserDefaults] synchronize];
            NSString* serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"server_link"];
            serverUrl = serverUrl?serverUrl:@"http://ihubot.herokuapp.com";
            
            
            client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:serverUrl]];
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


@end
