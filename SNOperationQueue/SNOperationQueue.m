//
//  SNOperationQueue.m
//  SNOperationQueue
//
//  Created by Siddhesh Naik on 7/21/12.
//  Copyright (c) 2012 Siddhesh Naik. All rights reserved.
//

#import "SNOperationQueue.h"

const char s[] = "SNOperationQueue";

@interface SNOperationQueue()
{
    NSOperationQueue* queue;
    NSMutableArray* pendingOperations;
    NSMutableArray* executingOperations;
}
@property(nonatomic, strong)NSOperationQueue* queue;
@property(nonatomic, strong)NSMutableArray* pendingOperations;
@property(nonatomic, strong)NSMutableArray* executingOperations;
@end

@implementation SNOperationQueue
@synthesize maxConcurrentOperations, suspended, name, queueType;
@synthesize queue, pendingOperations, executingOperations;

-(NSOperation*)getNextOperation
{
    NSOperation* op = nil;
    @synchronized(self.pendingOperations)
    {
        op = [self.pendingOperations lastObject];
        [self.pendingOperations removeObject:op];
    }
    @synchronized(self.executingOperations)
    {
        if(op)[self.executingOperations addObject:op];
    }
    return op;
}


-(void)addLIFOOperation:(NSOperation*)op
{
    @synchronized(self.pendingOperations)
    {
        [self.pendingOperations addObject:op];
    }
}

-(void)addFIFOOperation:(NSOperation*)op
{
    @synchronized(self.queue)
    {
        [self.pendingOperations insertObject:op atIndex:0];
    }
}


-(id)init
{
    if (self = [super init]) {
        self.queue = [[NSOperationQueue alloc] init];
        self.pendingOperations = [NSMutableArray new];
        self.executingOperations = [NSMutableArray new];
        self.queueType = SNOperationQueueFIFO;
    }
    return self;
}

+(SNOperationQueue*)queueWithMaxConcurrentOperations:(NSInteger)maxOps
{
    SNOperationQueue* ret = [[SNOperationQueue alloc] init];
    ret.maxConcurrentOperations = maxOps;
    return ret;
}

+(SNOperationQueue*)queueWithType:(SNOperationQueueType)type
{
    SNOperationQueue* ret = [SNOperationQueue queueWithMaxConcurrentOperations:1];
    ret.queueType = type;
    return ret;
}

-(void)addOperation:(NSOperation*)op
{
    [op addObserver:self forKeyPath:@"isFinished" options:(NSKeyValueObservingOptionNew |
                                                       NSKeyValueObservingOptionOld) context:(void*)s];
    switch (self.queueType) {
        case SNOperationQueueLIFO:
            [self addLIFOOperation:op];
            break;
        default:
        case SNOperationQueueFIFO:
            [self addFIFOOperation:op];
            break;
    }
    if (self.pendingOperations.count == 1 && self.queue.operationCount == 0) {
        [self schecduleNextOperations];
    }
}

-(void)addOperations:(NSArray *)ops waitUntilFinished:(BOOL)wait
{
    for(NSOperation* op in ops)
    {
        [self addOperation:op];
    }
    @synchronized(self.pendingOperations)
    {
        [self.queue setSuspended:YES];
        NSOperation* op = [self getNextOperation];
        for (; op != nil; op = [self getNextOperation]) {
            [self.queue addOperation:op];
        }
        [self.executingOperations addObjectsFromArray:self.pendingOperations];
        [self.pendingOperations removeAllObjects];
        [self.queue setSuspended:NO];
        if(wait)[self.queue waitUntilAllOperationsAreFinished];
    }
}

-(void)addOperationWithBlock:(void (^)(void))block
{
    NSBlockOperation* blockOperation = [NSBlockOperation blockOperationWithBlock:block];
    [self addOperation:blockOperation];
}

-(NSArray *)operations
{
    NSMutableArray* operations = [NSMutableArray new];
    @synchronized(self.pendingOperations)
    {
        [operations addObjectsFromArray:self.pendingOperations];
    }
    @synchronized(self.executingOperations)
    {
        [operations addObjectsFromArray:self.executingOperations];
    }
    return operations;
}

-(NSUInteger)operationCount
{
    return [[self operations] count];
}

-(void)waitUntilAllOperationsAreFinished
{
    [self addOperations:self.pendingOperations waitUntilFinished:YES];
}

-(void)cancelAllOperations
{
    for(NSOperation* op in self.operations)
    {
        [op cancel];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(context == s && [keyPath isEqualToString:@"isFinished"])
    {
        [self schecduleNextOperations];
    }
}

- (void)schecduleNextOperations
{
    @synchronized(self.queue)
    {
        NSOperation* op;
        int currentOperationsInQueue = self.queue.operationCount;
        while (currentOperationsInQueue < self.maxConcurrentOperations) {
            op = [self getNextOperation];
            if(op != nil)
            {
                [self.queue addOperation:op];
                currentOperationsInQueue++;
            }
            else {
                break;
            }
        }
    }
}

@end
