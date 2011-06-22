//
//  echoprintViewController.m
//  echoprint
//
//  Created by Brian Whitman on 6/13/11.
//  Copyright 2011 The Echo Nest. All rights reserved.
//

#import "echoprintViewController.h"
extern const char * GetPCMFromFile(char * filename);



@implementation echoprintViewController

- (IBAction)pickSong:(id)sender {
	NSLog(@"Pick song");
	MPMediaPickerController* mediaPicker = [[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic] autorelease];
	mediaPicker.delegate = self;
	[self presentModalViewController:mediaPicker animated:YES];
	
}
- (IBAction) startMicrophone:(id)sender {
	if(recording) {
		recording = NO;
		[recorder stopRecording];
		[recordButton setTitle:@"Record" forState:UIControlStateNormal];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *filePath =[documentsDirectory stringByAppendingPathComponent:@"output.caf"];
		[statusLine setText:@"analysing..."];
		[statusLine setNeedsDisplay];
		[self.view setNeedsDisplay];
		const char * fpCode = GetPCMFromFile((char*) [filePath cStringUsingEncoding:NSASCIIStringEncoding]);
        [self getSong:fpCode];
	} else {
		[statusLine setText:@"recording..."];
		recording = YES;
		[recordButton setTitle:@"Stop" forState:UIControlStateNormal];
		[recorder startRecording];
		[statusLine setNeedsDisplay];
		[self.view setNeedsDisplay];
	}
	NSLog(@"what");

}


- (void)mediaPicker:(MPMediaPickerController *)mediaPicker 
  didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
	[self dismissModalViewControllerAnimated:YES];
	for (MPMediaItem* item in mediaItemCollection.items) {
		NSString* title = [item valueForProperty:MPMediaItemPropertyTitle];
		NSURL* assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
		NSLog(@"title: %@, url: %@", title, assetURL);
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];

		NSURL* destinationURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"temp_data"]];
		[[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
		TSLibraryImport* import = [[TSLibraryImport alloc] init];
		[import importAsset:assetURL toURL:destinationURL completionBlock:^(TSLibraryImport* import) {
			//check the status and error properties of
			//TSLibraryImport
			NSString *outPath = [documentsDirectory stringByAppendingPathComponent:@"temp_data"];
			NSLog(@"done now. %@", outPath);
			[statusLine setText:@"analysing..."];
			const char * fpCode = GetPCMFromFile((char*) [outPath  cStringUsingEncoding:NSASCIIStringEncoding]);
			[statusLine setNeedsDisplay];
			[self.view setNeedsDisplay];
			[self getSong:fpCode];
		}];
		
	}
}


- (void) getSong: (const char*) fpCode {
	NSLog(@"Done %s", fpCode);
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/v4/song/identify?api_key=%@&version=4.11&code=%s", API_HOST, API_KEY, fpCode]];
	ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:url];
	[request setAllowCompressedResponse:NO];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		NSString *response = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];		
		NSDictionary *dictionary = [response JSONValue];
		NSLog(@"%@", dictionary);
		NSArray *songList = [[dictionary objectForKey:@"response"] objectForKey:@"songs"];
		if([songList count]>0) {
			NSString * song_title = [[songList objectAtIndex:0] objectForKey:@"title"];
			NSString * artist_name = [[songList objectAtIndex:0] objectForKey:@"artist_name"];
			[statusLine setText:[NSString stringWithFormat:@"%@ - %@", artist_name, song_title]];
		} else {
			[statusLine setText:@"no match"];
		}
	} else {
		[statusLine setText:@"some error"];
		NSLog(@"error: %@", error);
	}
	[statusLine setNeedsDisplay];
	[self.view setNeedsDisplay];
}



- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
	[self dismissModalViewControllerAnimated:YES];
}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	recorder = [[MicrophoneInput alloc] init];
	recording = NO;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
