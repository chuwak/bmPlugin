

#import <Foundation/Foundation.h>

//===========================================
enum : NSUInteger {
    ExitRegion = 2,
    EnterRegion = 1
    
};
typedef NSInteger ActionType;

NSString * const ActionType_toString[] = {
    [ExitRegion] = @"Exit",
    [EnterRegion] = @"Enter",
};


//===========================================
@interface MsgForType : NSObject
    @property NSString *msg;
    @property bool show;
    @property ActionType *type;

    - (id) init: (NSString*)msg : (Boolean*)show : (ActionType*)type;

@end



@interface ExtBeacon : NSObject{
        NSString *uuid;
        NSString *data;
        CLBeaconRegion *region;
    }

    @property NSInteger id ;
    @property NSString *uuid;
    @property NSString *major;
    @property NSString *minor;

    @property MsgForType *msgForEnter;
    @property MsgForType *msgForExit;

    @property NSString *data;
    @property CLBeaconRegion *region;

@end






//===========================================

@implementation MsgForType
    @synthesize msg;
    @synthesize show;
    @synthesize type;
    - (id)init: (NSString*)_msg : (Boolean*)_show : (ActionType*)_type{
        self = [super init];
        self.msg = _msg;
        self.show = _show;
        self.type = _type;
        return self;
    }

    -(void)encodeWithCoder:(NSCoder *)encoder
    {
        [encoder encodeObject:  self.msg forKey:@"msg"];
        [encoder encodeBool:    self.show forKey:@"show"];
        [encoder encodeInteger: (int)self.type forKey:@"type"];
    }

    -(id)initWithCoder:(NSCoder *)decoder
    {
        self.msg = [decoder decodeObjectForKey:@"msg"];
        self.show = [decoder decodeBoolForKey:@"show"];
        
        self.type = (ActionType*)[decoder decodeIntegerForKey:@"type"];
        return self;
    }

@end





@implementation ExtBeacon

    @synthesize id;
    @synthesize uuid;
    @synthesize major;
    @synthesize minor;
    @synthesize msgForEnter;
    @synthesize msgForExit;

    @synthesize data;
    @synthesize region;


    -(void)encodeWithCoder:(NSCoder *)encoder
    {
        [encoder encodeObject: [NSNumber numberWithInt: self.id] forKey:@"id"];
        [encoder encodeObject:  self.uuid forKey:@"uuid"];
        [encoder encodeObject:  self.major forKey:@"major"];
        [encoder encodeObject:  self.minor forKey:@"minor"];
        
        [encoder encodeObject: self.msgForEnter forKey:@"msgForEnter"];
        [encoder encodeObject: self.msgForExit forKey:@"msgForExit"];
        [encoder encodeObject:  self.data forKey:@"data"];
        
        [encoder encodeObject:  self.region forKey:@"region"];
    }

    -(id)initWithCoder:(NSCoder *)decoder
    {
        self.id = [[decoder decodeObjectForKey:@"id"] intValue];
        self.uuid = [decoder decodeObjectForKey:@"uuid"];
        self.major = [decoder decodeObjectForKey:@"major"];
        self.minor = [decoder decodeObjectForKey:@"minor"];
        
        self.msgForEnter = [decoder decodeObjectForKey:@"msgForEnter"];
        self.msgForExit = [decoder decodeObjectForKey:@"msgForExit"];
        
        self.data = [decoder decodeObjectForKey:@"data"];
        self.region = [decoder decodeObjectForKey:@"region"];
        
        return self;
    }


    +(ExtBeacon*)fillBeaconFromDictionary : (NSDictionary *) dict{
        
        ExtBeacon *eBeacon = [[ExtBeacon alloc] init];
        
        eBeacon.id = [[dict valueForKey:@"id" ] integerValue];
        eBeacon.uuid = (NSString*)[dict objectForKey:@"uuid" ];
        eBeacon.major = (NSString*)[dict objectForKey:@"major" ];
        eBeacon.minor = (NSString*)[dict objectForKey:@"minor" ];
        eBeacon.msgForEnter = [self fillMsgFromDictionary:[dict objectForKey:@"msgForEnter"] : EnterRegion];
        eBeacon.msgForExit = [self fillMsgFromDictionary:[dict objectForKey:@"msgForExit"] : ExitRegion];
        eBeacon.data = (NSString*)[dict objectForKey:@"data" ];
        
        return eBeacon;
        
    }

    +(MsgForType*)fillMsgFromDictionary : (NSDictionary *)dict : (ActionType)type{
        MsgForType *mft = [[MsgForType alloc] init];
        mft.msg = (NSString*)[dict objectForKey:@"msg"];
        mft.show = [[dict valueForKey:@"show"] boolValue];
        mft.type = (ActionType*)type;
        return mft;
    }


    -(MsgForType*) getMsgForType: (ActionType)type {
        if(type == ExitRegion){
            return msgForExit;
        }
        if(type == EnterRegion){
            return msgForEnter;
        }
        return nil;
    }


@end