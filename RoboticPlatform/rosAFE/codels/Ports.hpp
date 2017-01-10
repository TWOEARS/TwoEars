#ifndef PORTS_HPP
#define PORTS_HPP

#include "acrosAFE.h"

#include "rosAFE_c_types.h"

#include "genom3_dataFiles.hpp"

#include <string>
#include <thread>         // std::thread

namespace PORT {

/*  Type Related Functions  */

	genom_event
	iniTDS_port ( sequence_double *left, sequence_double *right, uint32_t fop, bool initToZero, genom_context self );

	void
	TDS_exec ( sequence_double *signal, twoCTypeBlockPtr chunk, uint32_t fop, uint32_t bytesPerFrame );
	
	genom_event
	publishTDS_port ( sequence_double *signalLeft, twoCTypeBlockPtr chunkLeft, sequence_double *signalRight, twoCTypeBlockPtr chunkRight, uint32_t fop, uint32_t bytesPerFrame, genom_context self );
	
	genom_event
	TFS_init( sequence_rosAFE_signalOneD *signal, uint32_t nChannels, uint32_t fop, bool initToZero, genom_context self );
	
	genom_event
	iniTFS_port ( sequence_rosAFE_signalOneD *signalLeft, sequence_rosAFE_signalOneD *signalRight, uint32_t nChannels, uint32_t fop, bool isBinaural, bool initToZero, genom_context self );

	void
	TFS_exec ( sequence_rosAFE_signalOneD *signal, std::vector<twoCTypeBlockPtr >& chunk, uint32_t nChannels, uint32_t fop, uint32_t bytesPerFrame );
	
	genom_event
	publishTFS_port ( sequence_rosAFE_signalOneD *signalLeft, std::vector<twoCTypeBlockPtr >& chunkLeft,
							sequence_rosAFE_signalOneD *signalRight, std::vector<twoCTypeBlockPtr >& chunkRight,
							uint32_t nChannels, uint32_t fop, uint32_t bytesPerFrame, bool isBinaural, genom_context self );
	
	genom_event
	iniCC_port ( sequence_rosAFE_signalND *signalLeft, uint32_t nLag, uint32_t nChannels, uint32_t fop, bool initToZero, genom_context self );

	genom_event
	publishCC_port ( sequence_rosAFE_signalND *signalLeft, std::vector<std::vector<twoCTypeBlockPtr > >& chunkLeft,
							uint32_t nLag, uint32_t nChannels, uint32_t fop, uint32_t bytesPerFrame, genom_context self );

/*  Processor Related Functions  */
											
	genom_event
	initInputPort ( const rosAFE_inputProcPort *inputProcPort, uint32_t sampleRate,
						uint32_t bufferSize_s, genom_context self );

	genom_event
	publishInputPort ( const rosAFE_inputProcPort *inputProcPort, twoCTypeBlockPtr left, twoCTypeBlockPtr right, uint32_t bytesPerFrame, int64_t nfr, genom_context self );

	genom_event
	initPreProcPort ( const char *name, const rosAFE_preProcPort *preProcPort, uint32_t sampleRate,
						uint32_t bufferSize_s, genom_context self );

	genom_event
	publishPreProcPort ( const char *name, const rosAFE_preProcPort *preProcPort, twoCTypeBlockPtr left, twoCTypeBlockPtr right, uint32_t bytesPerFrame, int64_t nfr, genom_context self );

	genom_event
	deletePreProcPort   ( const char *name, const rosAFE_preProcPort *preProcPort, genom_context self );

	genom_event
	initGammatonePort ( const char *name, const rosAFE_gammatonePort *gammatonePort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nChannels, genom_context self );
						
	genom_event
	publishGammatonePort ( const char *name, const rosAFE_gammatonePort *gammatonePort, std::vector<twoCTypeBlockPtr > left,
						std::vector<twoCTypeBlockPtr > right, uint32_t bytesPerFrame, int64_t nfr, genom_context self );

	genom_event
	deleteGammatonePort   ( const char *name, const rosAFE_gammatonePort *gammatonePort, genom_context self );
	
	genom_event
	initIHCPort ( const char *name, const rosAFE_ihcPort *ihcPort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nChannels, genom_context self );
						
	genom_event
	publishIHCPort ( const char *name, const rosAFE_ihcPort *ihcPort, std::vector<twoCTypeBlockPtr > left,
						std::vector<twoCTypeBlockPtr > right, uint32_t bytesPerFrame, int64_t nfr, genom_context self );

	genom_event
	deleteIHCPort   ( const char *name, const rosAFE_ihcPort *ihcPort, genom_context self );

	genom_event
	initILDPort ( const char *name, const rosAFE_ildPort *ildPort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nChannels, genom_context self );

	genom_event
	publishILDPort ( const char *name, const rosAFE_ildPort *ildPort, std::vector<twoCTypeBlockPtr > left,
						uint32_t bytesPerFrame, int64_t nfr, genom_context self );

	genom_event
	deleteILDPort   ( const char *name, const rosAFE_ildPort *ildPort, genom_context self );
	
	genom_event
	initRatemapPort ( const char *name, const rosAFE_ratemapPort *ratemapPort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nChannels, genom_context self );
						
	genom_event
	publishRatemapPort ( const char *name, const rosAFE_ratemapPort *ratemapPort, std::vector<twoCTypeBlockPtr > left,
						std::vector<twoCTypeBlockPtr > right, uint32_t bytesPerFrame, int64_t nfr, genom_context self );
																		
	genom_event
	deleteRatemapPort   ( const char *name, const rosAFE_ratemapPort *ratemapPort, genom_context self );
	
	genom_event
	initCrossCorrelationPort ( const char *name, const rosAFE_crossCorrelationPort *crossCorrelationPort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nLag, uint32_t nChannels, genom_context self );
						
	genom_event
	publishCrossCorrelationPort ( const char *name, const rosAFE_crossCorrelationPort *crossCorrelationPort, std::vector<std::vector<twoCTypeBlockPtr > > left,
						uint32_t bytesPerFrame, int64_t nfr, genom_context self );
																		
	genom_event
	deleteCrossCorrelationPort ( const char *name, const rosAFE_crossCorrelationPort *crossCorrelationPort, genom_context self );	
}
#endif /* PORTS_HPP */
