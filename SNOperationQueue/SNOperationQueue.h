//
//  SNOperationQueue.h
//  SNOperationQueue
//
//  Created by Siddhesh Naik on 7/21/12.
//  Copyright (c) 2012 Siddhesh Naik. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SNOperationQueueLIFO,
    SNOperationQueueFIFO
}SNOperationQueueType;

@interface SNOperationQueue : NSObject
{
    NSInteger maxConcurrentOperations;
    SNOperationQueueType queueType;
    BOOL suspended;
    NSString* name;
}
@property(assign)NSInteger maxConcurrentOperations;
@property(assign)BOOL suspended;
@property(strong) NSString* name;
@property(nonatomic, assign)SNOperationQueueType queueType;

+(SNOperationQueue*)queueWithMaxConcurrentOperations:(NSInteger)maxOps;
+(SNOperationQueue*)queueWithType:(SNOperationQueueType)type;

-(void)addOperation:(NSOperation*)op;
-(void)addOperations:(NSArray *)ops waitUntilFinished:(BOOL)wait;
-(void)addOperationWithBlock:(void (^)(void))block;
-(NSArray *)operations;
-(NSUInteger)operationCount;
-(void)waitUntilAllOperationsAreFinished;

-(void)cancelAllOperations;
@end
