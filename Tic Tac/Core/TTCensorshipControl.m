//
//  TTCensorshipControl.m
//  Tic Tac
//
//  Created by CBORD Waco on 6/14/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "TTCensorshipControl.h"


@interface TTCensorshipControl ()
@property (nonatomic, readonly) id<TTCensorshipDelegate> censorshipDelegate;
@end

@implementation TTCensorshipControl

+ (instancetype)withDelegate:(id<TTCensorshipDelegate>)delegate {
    return [[self alloc] initWithDelegate:delegate];
}

- (id)initWithDelegate:(id<TTCensorshipDelegate>)delegate {
    self = [super initWithItems:@[@"Visible", @"All"]];
    if (self) {
        _censorshipDelegate = delegate;
        delegate.showsAll = YES;
        
        self.selectedSegmentIndex = 0;
        [self addTarget:self action:@selector(segmentChanged) forControlEvents:UIControlEventValueChanged];
    }
    
    return self;
}

- (void)segmentChanged {
    self.censorshipDelegate.showsAll = self.selectedSegmentIndex;
}

@end