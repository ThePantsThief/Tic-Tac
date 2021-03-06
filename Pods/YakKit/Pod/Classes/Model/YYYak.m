//
//  YYYak.m
//  Pods
//
//  Created by Tanner on 11/10/15.
//
//

#import "YYYak.h"


@implementation YYYak

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [@{@"title": @"message",
              @"canUpvote": @"canUpvote",
              @"canDownvote": @"canDownvote",
              @"canReply": @"canReply",
              @"replyCount": @"comments",
              @"handle": @"handle",
              @"hideLocationPin": @"hidePin",
              @"mediaWidth": @"imageWidth",
              @"mediaHeight": @"imageHeight",
              @"latitude": @"latitude",
              @"longitude": @"longitude",
              @"location": @"location",
              @"locationDisplayStyle": @"locationDisplayStyle",
              @"locationName": @"locationName",
              @"authorIdentifier": @"posterID",
              @"isReadOnly": @"readOnly",
              @"isReyaked": @"reyaked",
              @"thumbnailURL": @"thumbnailUrl",
              @"mediaURL": @"url",
              @"type": @"type",
              @"identifier": @"messageID"} mtl_dictionaryByAddingEntriesFromDictionary:[super JSONKeyPathsByPropertyKey]];
}

MTLStringToNumberJSONTransformer(hideLocationPin)
MTLStringToNumberJSONTransformer(type)
MTLStringToNumberJSONTransformer(replyCount)

+ (NSValueTransformer *)thumbnailURLJSONTransformer { return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName]; }
+ (NSValueTransformer *)mediaURLJSONTransformer { return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName]; }

- (BOOL)hasMedia {
    return self.type == 6;
//    if (self.type == 6 && (!self.mediaURL || !self.thumbnailURL))
//        [NSException raise:NSInternalInconsistencyException format:@"Yak media type is 6 but is missing media info"];
//    return self.type == 6 && self.mediaURL && self.thumbnailURL;
}


@end
