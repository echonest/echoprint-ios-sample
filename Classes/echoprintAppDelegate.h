//
//  echoprintAppDelegate.h
//  echoprint
//
//  Created by Brian Whitman on 6/13/11.
//  Copyright 2011 The Echo Nest. All rights reserved.
//

#import <UIKit/UIKit.h>

@class echoprintViewController;

@interface echoprintAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    echoprintViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet echoprintViewController *viewController;

@end

