/*
 *  GetPCMFromFile.cpp
 *
 *  Created by Brian Whitman on 7/10/10.
 *  Copyright 2010 The Echo Nest. All rights reserved.
 *
 */
#include <AudioToolbox/AudioToolbox.h>
#include "CAStreamBasicDescription.h"
#include "Codegen_wrapper.h"

extern "C" {

extern void NSLog(CFStringRef format, ...); 

const char * GetPCMFromFile(char * filename) {
	CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL,(const UInt8*)filename, strlen(filename), false);
	ExtAudioFileRef outExtAudioFile;
	int err = ExtAudioFileOpenURL(audioFileURL, &outExtAudioFile);
	if (err) {
		NSLog(CFSTR("open failed")); 
	}

	
	CAStreamBasicDescription clientFormat;
	clientFormat.mSampleRate = 11025;
	clientFormat.mFormatID = kAudioFormatLinearPCM;
	clientFormat.mChannelsPerFrame = 2;
	clientFormat.mBitsPerChannel = 32;
	clientFormat.mBytesPerPacket = clientFormat.mBytesPerFrame = 4 * clientFormat.mChannelsPerFrame;
	clientFormat.mFramesPerPacket = 1;
	clientFormat.mFormatFlags =  kAudioFormatFlagsNativeFloatPacked;// | kAudioFormatFlagIsNonInterleaved;
	
	int size = sizeof(clientFormat);
	err = ExtAudioFileSetProperty(outExtAudioFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
	if (err) 
		NSLog(CFSTR("err on set format %d"), err);
	
	int seconds_to_decode = 30;
	int bytes_for_bigbuf = sizeof(float)*11025*seconds_to_decode;
	float *bigBuf = (float*) malloc(bytes_for_bigbuf);
	if(bigBuf == NULL) {
		NSLog(CFSTR("Error mallocing bigbuf"));
	}
	int totalFrames = 0;
	while (1) {
		AudioBufferList fillBufList;
		fillBufList.mNumberBuffers = 1;
		UInt32 bufferByteSize = 11025 * 4 * 2; // 1s of audio
		char srcBuffer[bufferByteSize];
		UInt32 numFrames = clientFormat.BytesToFrames(bufferByteSize); // (bufferByteSize / clientFormat.mBytesPerFrame);

		fillBufList.mBuffers[0].mNumberChannels = clientFormat.NumberChannels();
		fillBufList.mBuffers[0].mDataByteSize = bufferByteSize;
		fillBufList.mBuffers[0].mData = srcBuffer;
		err = ExtAudioFileRead(outExtAudioFile, &numFrames, &fillBufList);	
		if (err) { 
			NSLog(CFSTR("err on read %d"), err);
			totalFrames = 0;
			break;
		}
		if (!numFrames)
			break;
		
		float mono_version[numFrames];
		float* float_buf = (float*) fillBufList.mBuffers[0].mData;
		for(int i=0;i<numFrames;i++)
			mono_version[i] = (float_buf[i*2] + float_buf[i*2 + 1]) / 2.0;
		
		int bytesLeftInBuffer = bytes_for_bigbuf - (totalFrames * sizeof(float));
		
		if (numFrames * sizeof(float) > bytesLeftInBuffer) {
			memcpy(bigBuf + totalFrames, mono_version, bytesLeftInBuffer);
			totalFrames = totalFrames + (bytesLeftInBuffer/4);
			break;
		} else {
			memcpy(bigBuf + totalFrames, mono_version, numFrames * sizeof(float));
			totalFrames = totalFrames + numFrames;
		}
	}

	const char * what = "";
	if(totalFrames > 11025) {
		NSLog(CFSTR("Doing codegen on %d samples..."), totalFrames);
		what = codegen_wrapper(bigBuf,	totalFrames);
		NSLog(CFSTR("Done with codegen"));

	}
	free(bigBuf);

	return what;
}


}