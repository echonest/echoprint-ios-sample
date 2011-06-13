//
//The MIT License
//
//Copyright (c) 2010 tapsquare, llc., (http://www.tapsquare.com, art@tapsquare.com)
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.
//

#import "TSLibraryImport.h"
#import <AVFoundation/AVFoundation.h>

@interface TSLibraryImport()

+ (BOOL)validIpodLibraryURL:(NSURL*)url;
- (void)extractQuicktimeMovie:(NSURL*)movieURL toFile:(NSURL*)destURL;

@end


@implementation TSLibraryImport

+ (BOOL)validIpodLibraryURL:(NSURL*)url {
	NSString* IPOD_SCHEME = @"ipod-library";
	if (nil == url) return NO;
	if (nil == url.scheme) return NO;
	if ([url.scheme compare:IPOD_SCHEME] != NSOrderedSame) return NO;
	if ([url.pathExtension compare:@"mp3"] != NSOrderedSame &&
		[url.pathExtension compare:@"aif"] != NSOrderedSame &&
		[url.pathExtension compare:@"m4a"] != NSOrderedSame &&
		[url.pathExtension compare:@"wav"] != NSOrderedSame) {
		return NO;
	}
	return YES;
}

+ (NSString*)extensionForAssetURL:(NSURL*)assetURL {
	if (nil == assetURL)
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"nil assetURL" userInfo:nil];
	if (![TSLibraryImport validIpodLibraryURL:assetURL])
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Invalid iPod Library URL: %@", assetURL] userInfo:nil];
	return assetURL.pathExtension;
}

- (void)doMp3ImportToFile:(NSURL*)destURL completionBlock:(void (^)(TSLibraryImport* import))completionBlock {
	//TODO: instead of putting this in the same directory as the dest file, we should probably stuff
	//this in tmp
	NSURL* tmpURL = [[destURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"mov"];
	[[NSFileManager defaultManager] removeItemAtURL:tmpURL error:nil];
	exportSession.outputURL = tmpURL;
	
	exportSession.outputFileType = AVFileTypeQuickTimeMovie;
	[exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
		if (exportSession.status == AVAssetExportSessionStatusFailed) {
			completionBlock(self);
		} else if (exportSession.status == AVAssetExportSessionStatusCancelled) {
			completionBlock(self);
		} else {
			@try {
				[self extractQuicktimeMovie:tmpURL toFile:destURL];
			}
			@catch (NSException * e) {
				OSStatus code = noErr;
				if ([e.name compare:TSUnknownError]) code = kTSUnknownError;
				else if ([e.name compare:TSFileExistsError]) code = kTSFileExistsError;
				NSDictionary* errorDict = [NSDictionary dictionaryWithObject:e.reason forKey:NSLocalizedDescriptionKey];
				
				movieFileErr = [[NSError alloc] initWithDomain:TSLibraryImportErrorDomain code:code userInfo:errorDict];
			}
			//clean up the tmp .mov file
			[[NSFileManager defaultManager] removeItemAtURL:tmpURL error:nil];
			completionBlock(self);
		}
		[exportSession release];
		exportSession = nil;
	}];	
}

- (void)importAsset:(NSURL*)assetURL toURL:(NSURL*)destURL completionBlock:(void (^)(TSLibraryImport* import))completionBlock {
	if (nil == assetURL || nil == destURL)
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"nil url" userInfo:nil];
	if (![TSLibraryImport validIpodLibraryURL:assetURL])
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Invalid iPod Library URL: %@", assetURL] userInfo:nil];

	if ([[NSFileManager defaultManager] fileExistsAtPath:[destURL path]])
		 @throw [NSException exceptionWithName:TSFileExistsError reason:[NSString stringWithFormat:@"File already exists at url: %@", destURL] userInfo:nil];
	
	NSDictionary * options = [[NSDictionary alloc] init];
	AVURLAsset* asset = [AVURLAsset URLAssetWithURL:assetURL options:options];	
	if (nil == asset) 
		@throw [NSException exceptionWithName:TSUnknownError reason:[NSString stringWithFormat:@"Couldn't create AVURLAsset with url: %@", assetURL] userInfo:nil];
	
	exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
	if (nil == exportSession)
		@throw [NSException exceptionWithName:TSUnknownError reason:@"Couldn't create AVAssetExportSession" userInfo:nil];
	
	if ([[assetURL pathExtension] compare:@"mp3"] == NSOrderedSame) {
		[self doMp3ImportToFile:destURL completionBlock:completionBlock];
		return;
	}

	exportSession.outputURL = destURL;
	
	// set the output file type appropriately based on asset URL extension
	if ([[assetURL pathExtension] compare:@"m4a"] == NSOrderedSame) {
		exportSession.outputFileType = AVFileTypeAppleM4A;
	} else if ([[assetURL pathExtension] compare:@"wav"] == NSOrderedSame) {
		exportSession.outputFileType = AVFileTypeWAVE;
	} else if ([[assetURL pathExtension] compare:@"aif"] == NSOrderedSame) {
		exportSession.outputFileType = AVFileTypeAIFF;
	} else {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"unrecognized file extension" userInfo:nil];
	}

	[exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
		completionBlock(self);
		[exportSession release];
		exportSession = nil;
	}];
}

- (void)extractQuicktimeMovie:(NSURL*)movieURL toFile:(NSURL*)destURL {
	FILE* src = fopen([[movieURL path] cStringUsingEncoding:NSUTF8StringEncoding], "r");
	if (NULL == src) {
		@throw [NSException exceptionWithName:TSUnknownError reason:@"Couldn't open source file" userInfo:nil];
		return;
	}
	char atom_name[5];
	atom_name[4] = '\0';
	unsigned long atom_size = 0;
	while (true) {
		if (feof(src)) {
			break;
		}
		fread((void*)&atom_size, 4, 1, src);
		fread(atom_name, 4, 1, src);
		atom_size = ntohl(atom_size);
        const size_t bufferSize = 1024*100;
		if (strcmp("mdat", atom_name) == 0) {
			NSLog(@"movie url is %@, dest url is %@", movieURL, destURL);
			FILE* dst = fopen([[destURL path] cStringUsingEncoding:NSUTF8StringEncoding], "w");
			unsigned char buf[bufferSize];
			if (NULL == dst) {
				fclose(src);
				@throw [NSException exceptionWithName:TSUnknownError reason:@"Couldn't open destination file" userInfo:nil];
			}
            // Thanks to Rolf Nilsson/Roni Music for pointing out the bug here:
            // Quicktime atom size field includes the 8 bytes of the header itself.
            atom_size -= 8;
            while (atom_size != 0) {
                size_t read_size = (bufferSize < atom_size)?bufferSize:atom_size;
                if (fread(buf, read_size, 1, src) == 1) {
                    fwrite(buf, read_size, 1, dst);
                }
                atom_size -= read_size;
            }
			fclose(dst);
			fclose(src);
			return;
		}
		if (atom_size == 0)
			break; //0 atom size means to the end of file... if it's not the mdat chunk, we're done
		fseek(src, atom_size, SEEK_CUR);
	}
	fclose(src);
	@throw [NSException exceptionWithName:TSUnknownError reason:@"Didn't find mdat chunk"  userInfo:nil];
}

- (NSError*)error {
	if (movieFileErr) {
		return movieFileErr;
	}
	return exportSession.error;
}

- (AVAssetExportSessionStatus)status {
	if (movieFileErr) {
		return AVAssetExportSessionStatusFailed;
	}
	return exportSession.status;
}

- (float)progress {
	return exportSession.progress;
}

- (void)dealloc {
	[exportSession release];
	[movieFileErr release];
	[super dealloc];
}
@end
