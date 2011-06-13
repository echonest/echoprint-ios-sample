//
//  echoprintViewController.h
//  echoprint
//
//  Created by Brian Whitman on 6/13/11.
//  Copyright 2011 The Echo Nest. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import "TSLibraryImport.h"

// developer.echonest.com
#define API_KEY @"GO_GET_ONE"

@interface echoprintViewController : UIViewController <MPMediaPickerControllerDelegate> {

}

- (IBAction)pickSong:(id)sender;
- (IBAction)startMicrophone:(id)sender;
- (void) getSong: (const char*) fpCode;

@end

