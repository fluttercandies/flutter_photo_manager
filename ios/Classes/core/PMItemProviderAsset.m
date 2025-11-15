#import "PMItemProviderAsset.h"

@implementation PMItemProviderAsset

- (instancetype)initWithId:(NSString *)id
                  createDt:(long)createDt
                     width:(NSUInteger)width
                    height:(NSUInteger)height
                  duration:(long)duration
                      type:(int)type
                   subtype:(int)subtype
                      path:(NSString *)path {
    self = [super init];
    if (self) {
        self.id = id;
        self.createDt = createDt;
        self.width = width;
        self.height = height;
        self.duration = duration;
        self.type = type;
        self.subtype = subtype;
        self.path = path;
    }
    return self;
}

+ (instancetype)assetWithId:(NSString *)id
                   createDt:(long)createDt
                      width:(NSUInteger)width
                     height:(NSUInteger)height
                   duration:(long)duration
                       type:(int)type
                    subtype:(int)subtype
                       path:(NSString *)path {
    return [[self alloc] initWithId:id
                           createDt:createDt
                              width:width
                             height:height
                           duration:duration
                               type:type
                            subtype:subtype
                               path:path];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.id forKey:@"id"];
    [coder encodeInt64:self.createDt forKey:@"createDt"];
    [coder encodeInteger:self.width forKey:@"width"];
    [coder encodeInteger:self.height forKey:@"height"];
    [coder encodeInt64:self.duration forKey:@"duration"];
    [coder encodeInt:self.type forKey:@"type"];
    [coder encodeInt:self.subtype forKey:@"subtype"];
    [coder encodeObject:self.path forKey:@"path"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.id = [coder decodeObjectOfClass:[NSString class] forKey:@"id"];
        self.createDt = [coder decodeInt64ForKey:@"createDt"];
        self.width = [coder decodeIntegerForKey:@"width"];
        self.height = [coder decodeIntegerForKey:@"height"];
        self.duration = [coder decodeInt64ForKey:@"duration"];
        self.type = [coder decodeIntForKey:@"type"];
        self.subtype = [coder decodeIntForKey:@"subtype"];
        self.path = [coder decodeObjectOfClass:[NSString class] forKey:@"path"];
    }
    return self;
}


@end
