//
//  ViewController.h
//  AudioSample
//
//  Created by Fernando Ruiz on 02/09/14.
//  Copyright (c) 2014 NEODUCTION. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define _Sample		short
#define _SampleSize	sizeof(_Sample)
#define _MAXVALUE	32767
#define _MINVALUE  -32767

@interface ViewController : UIViewController {
    // formato de onda de salida
    AudioStreamBasicDescription	outFormat;
    // proceso de alimentacion de buffers hardware (vease como un DMA)
    AudioUnit *rioUnit;
    // callback que será llamado cuando se necesite alimentar buffer de salida
    AURenderCallbackStruct inputProc;
    
    // variables para ejemplo1
    float phase;
    
    // variables para ejemplo2
    //------------------ lectura de WAVs
    struct wav_header {
		char chunkId[4];
		uint32_t chunkSize;
		char format[4];
		char subChunkId[4];
		uint32_t subChunkSize;
		uint16_t audioFormat;
		uint16_t numChannels;
		uint32_t sampleRate;
		uint32_t byteRate;
		uint16_t blockAlign;
		uint16_t bitsPerSample;
		char subChunkId2[4];
		uint32_t subChunkSize2;
	};
	uint32_t length;
	uint32_t curPos;
	bool open;
	_Sample* wavbuffer;
    
}


@end
