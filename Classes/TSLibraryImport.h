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

#define TSLibraryImportErrorDomain @"TSLibraryImportErrorDomain"

#define TSUnknownError @"TSUnknownError"
#define TSFileExistsError @"TSFileExistsError"

#define kTSUnknownError -65536
#define kTSFileExistsError -48 //dupFNErr

typedef NSInteger AVAssetExportSessionStatus;

@class AVAssetExportSession;

@interface TSLibraryImport : NSObject {
	AVAssetExportSession* exportSession;
	NSError* movieFileErr;
}

/**
 * Pass in the NSURL* you get from an MPMediaItem's 
 * MPMediaItemPropertyAssetURL property to get the file's extension.
 *
 * Helpful in constructing the destination url for the
 * imported file.
 */
+ (NSString*)extensionForAssetURL:(NSURL*)assetURL;

/**
 * @param: assetURL The NSURL* returned by MPMediaItemPropertyAssetURL property of MPMediaItem.
 * @param: destURL The file URL to write the imported file to. You'll get an exception if a file
 * exists at this location.
 * @param completionBlock This block is called when the import completes. Note that 
 * completion doesn't imply success. Be sure to check the status and error properties
 * of the TSLibraryImport* instance from your completionBlock.
 */
- (void)importAsset:(NSURL*)assetURL toURL:(NSURL*)destURL completionBlock:(void (^)(TSLibraryImport* import))completionBlock;

@property (readonly) NSError* error;
@property (readonly) AVAssetExportSessionStatus status;
@property (readonly) float progress;

@end
