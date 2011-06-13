/*
 *  Codegen_wrapper.cpp
 *
 *  Created by Brian Whitman on 7/10/10.
 *  Copyright 2010 The Echo Nest. All rights reserved.
 *
 */

#include "Codegen.h"
#include <string>

const char* codegen_wrapper(const float*pcm, int numSamples) {
	//Codegen*c = new Codegen(pcm, (uint)numSamples, 0, false);
	Codegen*c = new Codegen(pcm, (unsigned int)numSamples, 0);
	string s = c->getCodeString();
	return s.c_str();
}

