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
#import "MicrophoneInput.h"

// developer.echonest.com
#define API_KEY @"GET_YOUR_OWN"
#define API_HOST @"developer.echonest.com"

@interface echoprintViewController : UIViewController <MPMediaPickerControllerDelegate> {
	BOOL recording;
	IBOutlet UIButton* recordButton;
	IBOutlet UILabel* statusLine;
	MicrophoneInput* recorder;

}

- (IBAction)pickSong:(id)sender;
- (IBAction)startMicrophone:(id)sender;
- (void) getSong: (const char*) fpCode;

@end

