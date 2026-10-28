//
//  ViewController.m
//  AudioSample
//
//  Created by Fernando Ruiz on 02/09/14.
//  Copyright (c) 2014 NEODUCTION. All rights reserved.
//

#import "ViewController.h"


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    
        ////// INICIAR ELEMENTOS DE COMUNICACION CON EL S.O. PARA AUDIO
    
        NSError *outError=nil; // se utilizara como valor resultado en varias llamadas
    
        // La Sesion de Audio es una instancia unica (compartida en cualquier parte de la App)
        AVAudioSession *sesion = [AVAudioSession sharedInstance];
    //*
        // Indicar como queremos usar la AudioSession (tipo de sesion (solo playback)(micro+altavoz), etc...)
        [sesion setCategory: AVAudioSessionCategoryPlayback error:&outError];
        if (outError) {
            NSLog(@"error en setCategory");
        }
    //*/
        /*
            // Ejemplo de micro+altavoz
            [sesion setCategory: AVAudioSessionCategoryPlayAndRecord error:&outError];
            if (outError) {
                NSLog(@"error en setCategory");
            }
        //*/
    
        // activar la sesion
        AudioSessionSetActive(true);
    
        // Ahora la sesion se configura a base de llamadas tipo: AudioSessionSetProperty
        //      constante de propiedad a modificar,
        //      tamaño de la variable que se le pasa (sizeof),
        //      puntero a la variable con el valor
        //          (la variable puede ser modificada con el valor que se acepte,
        //           si el que tenia no es valido)
    
        /*
            // OPCIONAL (para micro)
            // admitir entrada por Bluetooth
            UInt32 allowBluetoohInput=1;
            AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                        sizeof(allowBluetoohInput),
                                        &allowBluetoohInput);
        //*/
    
        // configuro tamaño de Buffer (en segundos)
        // a Buffers mas cortos, menos delay y memoria, pero las llamadas al callback serán mas frecuentes
        // a Buffers mas largos, llamadas al callback mas espaciadas, pero necesita que se le alimente con mas datos/tiempo
        Float32 preferredBufferDuration = 0.0025;
        AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,
                                sizeof(preferredBufferDuration), &preferredBufferDuration);
        // comprobar a la salida de que el valor pasado ha sido aceptado (o modificado en la llamada)
        NSLog(@"preferredBufferDuration %f\n",preferredBufferDuration);
    
        // configuro SampleRate
        Float64 sampleRate=22050;
        AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate,
                                sizeof(sampleRate), &sampleRate);
    
    
        // pata confirmar todo, consulto y muestro valores (ajustados o que ya estaban por defecto)
        // numero de canales (por defecto 1-mono)
        NSLog(@"numero de canales: %d\n",sesion.currentHardwareOutputNumberOfChannels);
        // que el sample rate es el que he pedido
        sampleRate = [sesion currentHardwareSampleRate];
        NSLog(@"currentHardwareSampleRate %f",sampleRate);
        //*
            // OPCIONAL (para micro)
            // comprobar que tengo disponible entrada (micro)
            BOOL inputAvailable;
            inputAvailable = [sesion inputIsAvailable];
            NSLog(@"inputIsAvailable %d",inputAvailable);
        //*/
        
        // ruta de salida (identifica si es por altavoz/auriculares-jack/bluetooth/etc...
        UInt32 size = sizeof(CFStringRef);
        CFStringRef route;
        AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &route);
        NSLog(@"route = %@", route);
    
        
        // HASTA AQUI TENEMOS ACCESO/PERMISO A LA UNIDAD DE AUDIO
    
        // Ahora vamos a configurar un modulo de proceso (AudioUnit)
        // que recibirá buffers de entrada, y entregará buffers de salida
        
        // crear nuestro propio AudioUnit (por ahora, AudioUnit generico... luego será RemoteInputOutput)
        rioUnit = new AudioUnit();
    
        // estructura con la informacion para configurar el AudioUnit
        //  inputProc es la funcion a la que será llamada para procesar los buffers (callbak)
        //  inputProcRefCon es un puntero a varible/objeto de contexto
        //      (como es un callback a una funcion estática no tiene acceso a esta instancia de ViewController,
        //          podemos por aqui pasarle la referencia a this/self)
        inputProc.inputProc = performThru;
        inputProc.inputProcRefCon = (__bridge void *)self;
    
        // configurar el RemoteIO AudioUnit
        setupRemoteIO(*rioUnit, inputProc, outFormat);

    
    // Y FINALMENTE...
    // ponemos en marcha nuestro AudioUnit
    //      (para que empiece a generar audio al altavoz)
    //      [y recibir/procesar del microfono]
    AudioOutputUnitStart(*rioUnit);
    
    // inicializo varibles propias de los ejemplos de proceso (ver mas abajo)
    phase=0;
    open=false;
    
    // para detenerlo seria...
    //AudioOutputUnitStop(*rioUnit);

}

// ------------------------------------------------------------------------------------------------------------------

int setupRemoteIO(AudioUnit &rioUnit, AURenderCallbackStruct inputProc, AudioStreamBasicDescription outFormat) {
    try {
        // solo se pueden crear AudioUnits que se tengan instalados en el S.O.
        //      (ver documentacion para otros tipos)
        
        // nosotros usaremos el "RemoteIO"
        //      (basicamente es un nodo cuyo proceso es remoto -no nativo s.o.- haciendonos llamadas al callback)
        
        // para crearlo, se busca entre los instalados (por tipo, subtipo y fabricante)
		
		AudioComponentDescription desc;
		desc.componentType = kAudioUnitType_Output;                     // tipo:        Output
		desc.componentSubType = kAudioUnitSubType_RemoteIO;             // subtipo:     RemoteIO
		desc.componentManufacturer = kAudioUnitManufacturer_Apple;      // fabricante:  Apple
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		
		AudioComponent comp = AudioComponentFindNext(NULL, &desc);      // busca componenten instalado con esta descripcion
        // deberiamos comprobar si se ha encontrado el componente...
        // pero dado que es nativo de iOS y OSX... es seguro que se encuenta.
        
        // convierte nuestra instancia -interfaz- de AudioUnit generico, al tipo de componente encontrado (RemoteIO)
		AudioComponentInstanceNew(comp, &rioUnit);
        
		// Configurar nuestro Nodo de Audio (dentro del grafo de audio del sistema)
        
        // preparo variables para opciones booleanas (siempre hay que pasar variables, no constantes)
		UInt32 one = 1;
        //UInt32 zero = 0;
        
        // element  cada nodo tiene dos conexiones:
        //          0=output datos que genera o salen del AudioNode,
        //          1=input  datos que requiere o entran al AudioNode
        // scope    cada element tiene dos puntos de vista (scope)
        //          Input:  cuando se va a escribir en este element/stream
        //          Output: cuando se va a leer de este element/stream
        
		
        
        // indicamos la configuracion de callback para escribir nuestro stream de salida (element/bus 0=output)
		AudioUnitSetProperty(rioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &inputProc, sizeof(inputProc));
        
        // indicamos activa la entrada de nuestro stream [podemos leer del microfono, o silencio] (element/bus 1=input)
        AudioUnitSetProperty(rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
        
    
        // indicamos que sea el S.O. quien reserve la memoria de los buffers
        // (tanto de entrada como de salida)
        // así... los punteros que nos vienen, ya apuntan a una zona de memoria valida (no tenemos nosotros que gestinarlos)
		AudioUnitSetProperty(rioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, 1, &one, sizeof(one));
		AudioUnitSetProperty(rioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Input, 0, &one, sizeof(one));
		
        // preparamos el Formato para esos buffers (streams) de entrada/salida
        memset(&outFormat, 0, sizeof(outFormat)); // ponemos toda la estructura a 0s, para asegurarnos
        // ponemos los valores "normales" / "Canonical AU format": LPCM non-interleave 16 bit integer [for iPhone] (LPCM non-interleaved 8.24 fixed point)
        setCanonical(outFormat, 1, false);  // 1 channel = mono, false = non-interleaved
        // aplicamos este formato tanto como salida (altavoz) [ como para entrada (micro) si se quiere usar ]
		AudioUnitSetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat));
		AudioUnitSetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat));
        
        // inicializamos el AudioUnit
		AudioUnitInitialize(rioUnit);
	}
	catch (...) {
		printf("An unknown error occurred\n");
		return 1;
	}
	return 0;
}

// ------------------------------------------------------------------------------------------------------------------

void setCanonical(AudioStreamBasicDescription &pFormat, UInt32 nChannels, bool interleaved)
// note: leaves sample rate untouched
{
	pFormat.mFormatID = kAudioFormatLinearPCM;
    //#if CA_ENV_MACOSX
    //	int sampleSize = sizeof(Float32);
    //	pFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
    //#else
	int sampleSize = sizeof(AudioSampleType);
	pFormat.mFormatFlags = kAudioFormatFlagsCanonical;
	//pFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    //#endif
	pFormat.mBitsPerChannel = 8 * sampleSize;
	pFormat.mChannelsPerFrame = nChannels;
	pFormat.mFramesPerPacket = 1;
	AVAudioSession *sesion = [AVAudioSession sharedInstance];
	pFormat.mSampleRate=[sesion currentHardwareSampleRate];
	if (interleaved)
		pFormat.mBytesPerPacket = pFormat.mBytesPerFrame = nChannels * sampleSize;
	else {
		pFormat.mBytesPerPacket = pFormat.mBytesPerFrame = sampleSize;
		pFormat.mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
	}
    NSLog(@"setCanonical");
    NSLog(@"  sampleSize: %d",sampleSize);
    NSLog(@"  bitsPerCha: %d",(unsigned int)pFormat.mBitsPerChannel);
    NSLog(@"  chaPerFram: %d",(unsigned int)pFormat.mChannelsPerFrame);
    NSLog(@"  sampleRate: %f",pFormat.mSampleRate);
}

// ------------------------------------------------------------------------------------------------------------------

// AudioUnit Callback (process input and generate output)
OSStatus performThru (
                      void							*inRefCon,
                      AudioUnitRenderActionFlags 	*ioActionFlags,
                      const AudioTimeStamp			*inTimeStamp,
                      UInt32 						inBusNumber,
                      UInt32 						inNumberFrames,
                      AudioBufferList				*ioData)
{
    // convierto el puntero (C) [cast] a referencia de esta clase (Objective-C) [__bridge porque es entre C->Obj-C]
	ViewController *THIS = (__bridge ViewController *)inRefCon;
	
    // variable para devolver estado
    OSStatus err;
    
    // ActionFlags indicaria que nos está pidiendo el hardware de audio
    // es una politica pull-down... es decir:
    //   cuando el altavoz vacia algun buffer, nos pide que le entregemos nuevos buffers
    //   (a su vez, nosotros podemos pedir al input -microfono- que no entregue nuevos buffers
    // resumen: la salida es quien pide a la entrada nuevos datos (pull-tirar)
    
    // AudioTimeStamp: señal de tiempo (por si tenemos varios AudioUnits que llamaran a esta misma callback
    // inBusNumber: indica si la llamada es producida por el bus 0=output, o el bus 1=input
    //              (si nos pide entregar algo como salida del nodo)
    //              (o si nos está entregando algo como entrada del nodo)
    // inNumberFrames: cuantos samples estamos recibiendo/entregando
    //              (frames, para contemplar 2 samples simultaneos en caso de stereo, etc)
    // ioData:  input/output de los datos. (organizado como array de buffers, con los samples)
    
    // por tanto:
    // nos solicitan rellenar ioData (AudioBufferList) con nuevo audio.
    
    // llamamos a nuestro AudioUnit (bus 1=input) para que nos entregue los buffers (reserva de memoria)
        // si estamos leyendo de microfono... vendrán con lo que tenga almacenado del microfono.
    err = AudioUnitRender(*(THIS->rioUnit), ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);

    
    // para cada buffer a rellenar (puede pedirnos varios a la vez, en vez de ser 1 solo gigante)
    //      (esto lo hace para poder ir consumiendo tramos -buffer- mientras se escriben en otros)
	for (UInt32 i=0; i<ioData->mNumberBuffers; i++) {
        // VUESTRA LIBRERIA PUEDE IR AQUI
        procesarBuffer(THIS,(_Sample*)ioData->mBuffers[i].mData, inNumberFrames);
    }
    
	return err;
}

// ------------------------------------------------------------------------------------------------------------------

void procesarBuffer(ViewController *THIS, _Sample* inData,UInt32 inNumberFrames) {
    // si solo es Playback:
    //      los buffers estan vacios (o con basura/audio antiguo)
    //      hay que sobreescribir el data
    // si es Rec&Playback:
    //      los buffers tienen el audio original (microfono)
    //      hay que leer+calcular+sobreescribir el data
    
    NSLog(@"procesarBuffer: len:%d",(unsigned int)inNumberFrames);
    // NOTA: se puede enviar Log 1 vez por buffer, pero no enviar Log a cada frame/sample
    //          (tarda "tanto" en escribir en Log, que pasa el tiempo de espera permitido para enviar buffer relleno)
    //          (se genera nueva petición... pero nunca llega a sonar lo generado anterior)
    
    float volume=1.0f;
    
    //*
    // ejemplo 0: no procesar nada (input->output);
    // sonará directamente el microfono
    // ¡¡¡ ALERTA DE ACOPLAMIENTO !!!
    //*/
    
    /*
    // ejemplo 1:
    //      rellenar con una onda
    float rtone=(2*M_PI*440)/22050; // (2*PI*tono/samplerate)
    for (unsigned long i=0;i<inNumberFrames;i++) {
        inData[i]=(_Sample)(sinf(rtone*(THIS->phase)++)*_MAXVALUE*volume);
    }
    THIS->phase=((short)THIS->phase)%22050; // mantener phase dentro de un ciclo (samplerate)
    //*/
    
    /*
    // ejemplo 2:
    //      rellenar con un audio pre-cargado (wav)
    //*/
    if (THIS->open) { // procesar
        _Sample *data_ptr = inData;
		_Sample *sample=(THIS->wavbuffer+THIS->curPos);
		for (unsigned long j=0;j<inNumberFrames;j++) {
			if (THIS->curPos!=-1) {
				(*data_ptr)=((float)(*sample)*volume);
				sample++;
				THIS->curPos++;
				if (THIS->curPos>(THIS->length/_SampleSize)) {
					if (true) {     // LOOP
						THIS->curPos=0;
						sample=THIS->wavbuffer;
					} else THIS->curPos=-1;         // DETENER AL FINAL
				}
			} else {
				(*data_ptr)=0;
			}
			data_ptr++;
		}
    } else { // cargar WAV
        NSString *path = [[NSBundle mainBundle] pathForResource: @"ejemplo" ofType: @"wav"];
        if (path!=nil && initWav(THIS,[path cStringUsingEncoding:1])) {
            NSLog(@"Archivo Wav leido!");
        } else {
            NSLog(@"--- error leyendo wav ---");
        }
    }
    
}

// -------------------------------------------------------- Funciones para WAVs
int initWav(ViewController *THIS, const char* filename) {
	
	FILE *wavfile = fopen(filename, "r");
	if (!wavfile) {
		printf("couldn't open wav file [%s]\n",filename);
		return -1;
	}
	struct wav_header w = get_wav_header(wavfile);
	THIS->length=w.subChunkSize2;// /(w.bitsPerSample*8):
	
	printheader(&w);	// mostrar formato de WAV por la consola
    
	THIS->wavbuffer=(_Sample*)malloc(THIS->length);
	if (THIS->wavbuffer==NULL) {
		printf("ERROR: no se ha podido reservar memoria suficiente (%d)\n",THIS->length);
		return -1;
	}
	
	_Sample sample;
	_Sample* data_ptr=THIS->wavbuffer;
	unsigned int quedan=THIS->length;
	while (!feof(wavfile) && quedan>_SampleSize) {
		fread(&sample, _SampleSize, 1, wavfile);
		(*data_ptr)=((_Sample)sample);
		data_ptr++;
		quedan-=_SampleSize;
	}
	
	if (quedan>=_SampleSize) {
		printf("WARNING: se alcanzo el final de archivo EOF (quedan=%d, buffer=%d)\n",quedan,THIS->length);
		THIS->length-=quedan;
	}
	fclose(wavfile);
    THIS->curPos=0;
	THIS->open=true;
	
	return 0;
}

struct wav_header get_wav_header(FILE *in)	{
	struct wav_header head;
    
	fread(head.chunkId, 1, 4, in);
	fread(&head.chunkSize, 4, 1, in);
	fread(head.format, 1, 4, in);
	fread(head.subChunkId, 1, 4, in);
	fread(&head.subChunkSize, 4, 1, in);
	fread(&head.audioFormat, 2, 1, in);
	fread(&head.numChannels, 2, 1, in);
	fread(&head.sampleRate, 4, 1, in);
	fread(&head.byteRate, 4, 1, in);
	fread(&head.blockAlign, 2, 1, in);
	fread(&head.bitsPerSample, 2, 1, in);
	fread(head.subChunkId2, 1, 4, in);
	fread(&head.subChunkSize2, 4, 1, in);

	return head;
}

void printheader(struct wav_header *w)	{
	int file_length; // in seconds
    printf("------------------ wav header -------");
    
	if (w->audioFormat == 1)
		printf("PCM format\n");
	else
		printf("Unknown format\n");
    
	if (w->numChannels == 1)
		printf("Mono\n");
	else if (w->numChannels == 2)
		printf("Stereo\n");
    
	printf("Sample Rate = %d\n", w->sampleRate);
	printf("%d bytes per sample\n", w->bitsPerSample / 8);
	// how long the file is in seconds
	file_length = w->subChunkSize2 / w->byteRate;
	printf("file length is %d:%d\n", file_length/60, file_length%60);
    printf("-------------------------------------");
}

// ------------------------------------------------------------------------------------------------------------------

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
