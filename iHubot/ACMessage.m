#import "ACMessage.h"
#import "AppDelegate.h"
#import "AFHTTPClient.h"    
#import "AFJSONRequestOperation.h"
#import "UIDevice+IdentifierAddition.h"
@implementation ACMessage

@dynamic sentDate;
@dynamic text;
@dynamic user;

+(AFHTTPClient*) client {
    static AFHTTPClient* client = nil;
    @synchronized(self) {
        if (!client){
            
            client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://ihubot.herokuapp.com"]];
//            [client setDefaultHeader:@"Accept" value:@"application/json"];
            [client setParameterEncoding:AFJSONParameterEncoding];
            [client registerHTTPOperationClass:[AFJSONRequestOperation class]];

            [client setAuthorizationHeaderWithUsername:[[UIDevice currentDevice] uniqueDeviceIdentifier] password:@"no-password"];
            
        }
        return client;
    }
}

+(id)sendMessage:(NSString *)messageText {
    ACMessage * message = [self messageWithText:[self preprocessRequestText:messageText]];
    [message send];
    return message;
}

+(NSString*) preprocessRequestText:(NSString*)text {
    if (![[[[text componentsSeparatedByString:@" "] objectAtIndex:0] lowercaseString] isEqualToString:@"hubot"])
        return [@"hubot " stringByAppendingString:text];
    return text;
}

+(id)messageWithText:(NSString*)text {
    ACMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"ACMessage" inManagedObjectContext:((AppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext];
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
            ACMessage * message = [[self class] messageWithText:json[@"message"]];
            message.user = @"hubot";
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        
    }];
}
@end
