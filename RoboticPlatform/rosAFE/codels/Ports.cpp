#include "Ports.hpp"


	genom_event
	PORT::iniTDS_port ( sequence_double *left, sequence_double *right, uint32_t fop, bool initToZero, genom_context self ) {

		left->_length = fop;
		right->_length = fop;
			
		if ( genom_sequence_reserve( left, fop ) || genom_sequence_reserve( right, fop ) )
		return rosAFE_e_noMemory( self );	

		if ( initToZero ) {
			for ( size_t ii = 0; ii < fop; ++ii ) {
					left->_buffer[ii] = 0;
					right->_buffer[ii] = 0;
			}
		}
		
		return genom_ok;	
	}

	void
	PORT::TDS_exec ( sequence_double *signal, twoCTypeBlockPtr chunk, uint32_t fop, uint32_t bytesPerFrame ) {
		
		uint32_t dim1 = chunk->array1.second;
		uint32_t dim2 = chunk->array2.second;

		uint32_t fpc = dim1 + dim2; 		// amount of Frames On this Chunk
		
		if ( bytesPerFrame > 0 )
			memmove(signal->_buffer, signal->_buffer + fpc, (fop - fpc) * bytesPerFrame);		
		
		uint32_t pos, ii;
			if (dim2 == 0) {	
				for (ii = 0, pos = fop - fpc; pos < fop ; ++ii, ++pos ) {
					signal->_buffer[pos] = *(chunk->array1.first + ii);
				}
			} else if (dim1 == 0) {
					for (ii = 0, pos = fop - fpc; pos < fop ; ++ii, ++pos ) {
						signal->_buffer[pos] = *(chunk->array2.first + ii);
					}
			} else {
					for (ii = 0, pos = fop - fpc; pos < fop - dim2 ; ++ii, ++pos ) {
						signal->_buffer[pos] = *(chunk->array1.first + ii);
					}
					
					for (ii = 0, pos = fop - dim2; pos < fop ; ++ii, ++pos ) {
						signal->_buffer[pos] = *(chunk->array2.first + ii);
					}			
				}	
	}

	genom_event
	PORT::publishTDS_port ( sequence_double *signalLeft, twoCTypeBlockPtr chunkLeft, sequence_double *signalRight, twoCTypeBlockPtr chunkRight, uint32_t fop, uint32_t bytesPerFrame, genom_context self ) {

		std::thread left( PORT::TDS_exec, signalLeft, chunkLeft, fop, bytesPerFrame);
		std::thread right( PORT::TDS_exec, signalRight, chunkRight, fop, bytesPerFrame);
			
		left.join();
		right.join();
			
		return genom_ok;
	}

	genom_event
	PORT::TFS_init( sequence_rosAFE_signalOneD *signal, uint32_t nChannels, uint32_t fop, bool initToZero, genom_context self ) {
		
	  if ( genom_sequence_reserve( signal, nChannels) )
		return rosAFE_e_noMemory( self );

	  signal->_length = nChannels;
	  
	  for ( size_t ii = 0 ; ii < nChannels ; ++ii ) {
		if ( genom_sequence_reserve(&(signal->_buffer[ii].data), fop) )
		return rosAFE_e_noMemory( self );
	  
	  	signal->_buffer[ii].data._length = fop;

		if ( initToZero ) {	  
			for ( size_t iii = 0; iii < fop; ++iii)
				signal->_buffer[ii].data._buffer[iii] = 0;
		}
	  }
	
	return genom_ok;	  		
	}
	
	genom_event
	PORT::iniTFS_port ( sequence_rosAFE_signalOneD *signalLeft, sequence_rosAFE_signalOneD *signalRight, uint32_t nChannels, uint32_t fop, bool isBinaural, bool initToZero, genom_context self ) {

		std::thread left( PORT::TFS_init, signalLeft, nChannels, fop, initToZero, self );
		
		if ( isBinaural ) {
			std::thread right( PORT::TFS_init, signalRight, nChannels, fop, initToZero, self );
			left.join();
			right.join();
		} else left.join();

		return genom_ok;		
	}

	void
	PORT::TFS_exec ( sequence_rosAFE_signalOneD *signal, std::vector<twoCTypeBlockPtr >& chunk, uint32_t nChannels, uint32_t fop, uint32_t bytesPerFrame ) {

		for ( size_t ii = 0 ; ii < nChannels ; ++ii ) {
			
			uint32_t dim1 = chunk[ii]->array1.second;
			uint32_t dim2 = chunk[ii]->array2.second;
			
			uint32_t fpc = dim1 + dim2; 			// amount of Frames On this Chunk

			if ( bytesPerFrame > 0 )		
				memmove(signal->_buffer[ii].data._buffer, signal->_buffer[ii].data._buffer + fpc, (fop - fpc) * bytesPerFrame);

			uint32_t pos, iii;
			if (dim2 == 0) {	
				for (iii = 0, pos = fop - fpc; pos < fop ; ++iii, ++pos)
					signal->_buffer[ii].data._buffer[pos] = *(chunk[ii]->array1.first + iii);
			} else if (dim1 == 0) {
					for (iii = 0, pos = fop - fpc; pos < fop ; ++iii, ++pos)
						signal->_buffer[ii].data._buffer[pos] = *(chunk[ii]->array2.first + iii);
			} else {
					for (iii = 0, pos = fop - fpc; pos < fop - dim2 ; ++iii, ++pos)
						signal->_buffer[ii].data._buffer[pos] = *(chunk[ii]->array1.first + iii);
					for (iii = 0, pos = fop - dim2; pos < fop ; ++iii, ++pos)
						signal->_buffer[ii].data._buffer[pos] = *(chunk[ii]->array2.first + iii);	
				}
		}		
	}
		
	genom_event
	PORT::publishTFS_port ( sequence_rosAFE_signalOneD *signalLeft, std::vector<twoCTypeBlockPtr >& chunkLeft,
							sequence_rosAFE_signalOneD *signalRight, std::vector<twoCTypeBlockPtr >& chunkRight,
							uint32_t nChannels, uint32_t fop, uint32_t bytesPerFrame, bool isBinaural, genom_context self ) {

		std::thread left( PORT::TFS_exec, signalLeft, std::ref(chunkLeft), nChannels, fop, bytesPerFrame );
		
		if ( isBinaural ) {
			std::thread right( PORT::TFS_exec, signalRight, std::ref(chunkRight), nChannels, fop, bytesPerFrame );
			left.join();
			right.join();
		} else left.join();

		return genom_ok;	

	  return genom_ok;	
	}

	genom_event
	PORT::iniCC_port ( sequence_rosAFE_signalND *signal, uint32_t nLag, uint32_t nChannels, uint32_t fop, bool initToZero, genom_context self ) {

	  if ( genom_sequence_reserve( signal, nLag) )
		return rosAFE_e_noMemory( self );

	  signal->_length = nLag;
	  
	  for ( size_t ii = 0 ; ii < nLag ; ++ii ) { 
	  	  if ( genom_sequence_reserve( &(signal->_buffer[ii].dataN), nChannels) ) 
			return rosAFE_e_noMemory( self );
		  signal->_buffer[ii].dataN._length = nChannels; 

		 for ( size_t jj = 0 ; jj < nChannels ; ++jj ) { 
			if ( genom_sequence_reserve(&(signal->_buffer[ii].dataN._buffer[jj].data), fop) )
				return rosAFE_e_noMemory( self );
			signal->_buffer[ii].dataN._buffer[jj].data._length = fop;

		  if ( initToZero ) {	  
			for ( size_t iii = 0; iii < fop; ++iii)
				signal->_buffer[ii].dataN._buffer[jj].data._buffer[iii] = 0;
		  }
	  }
	}

	return genom_ok;		
	}

	genom_event
	PORT::publishCC_port ( sequence_rosAFE_signalND *signal, std::vector<std::vector<twoCTypeBlockPtr > >& chunk,
							uint32_t nLag, uint32_t nChannels, uint32_t fop, uint32_t bytesPerFrame, genom_context self ) {
		
		for ( size_t ii = 0 ; ii < nChannels ; ++ii ) {
			for ( size_t jj = 0 ; jj < nLag ; ++jj ) {
				uint32_t dim1 = chunk[ii][jj]->array1.second;
				uint32_t dim2 = chunk[ii][jj]->array2.second;
			
				uint32_t fpc = dim1 + dim2; 			// amount of Frames On this Chunk

				if ( bytesPerFrame > 0 )		
					memmove(signal->_buffer[jj].dataN._buffer[ii].data._buffer, signal->_buffer[jj].dataN._buffer[ii].data._buffer + fpc, (fop - fpc) * bytesPerFrame);

			uint32_t pos, iii;
			if (dim2 == 0) {	
				for (iii = 0, pos = fop - fpc; pos < fop ; ++iii, ++pos)
					signal->_buffer[jj].dataN._buffer[ii].data._buffer[pos] = *(chunk[ii][jj]->array1.first + iii);
			} else if (dim1 == 0) {
					for (iii = 0, pos = fop - fpc; pos < fop ; ++iii, ++pos)
						signal->_buffer[jj].dataN._buffer[ii].data._buffer[pos] = *(chunk[ii][jj]->array2.first + iii);
			} else {
					for (iii = 0, pos = fop - fpc; pos < fop - dim2 ; ++iii, ++pos)
						signal->_buffer[jj].dataN._buffer[ii].data._buffer[pos] = *(chunk[ii][jj]->array1.first + iii);
					for (iii = 0, pos = fop - dim2; pos < fop ; ++iii, ++pos)
						signal->_buffer[jj].dataN._buffer[ii].data._buffer[pos] = *(chunk[ii][jj]->array2.first + iii);	
				}
			}	
		}
	  return genom_ok;	
	}
				
/* Input Port ----------------------------------------------------------------- */

	genom_event
	PORT::initInputPort ( const rosAFE_inputProcPort *inputProcPort, uint32_t sampleRate,
					uint32_t bufferSize_s, genom_context self ) {
						
		  uint32_t fop =  sampleRate * bufferSize_s; // total amount of Frames On the Port 
	
		  iniTDS_port(&(inputProcPort->data( self )->left.data), &(inputProcPort->data( self )->right.data), fop, true, self );

		  inputProcPort->data( self )->sampleRate = sampleRate;
		  inputProcPort->data( self )->framesOnPort = fop;
		  inputProcPort->data( self )->lastFrameIndex = 0;
		  
		  inputProcPort->write( self );
		  
		  return genom_ok;
	}

	genom_event
	PORT::publishInputPort ( const rosAFE_inputProcPort *inputProcPort, twoCTypeBlockPtr left, twoCTypeBlockPtr right, uint32_t bytesPerFrame, int64_t nfr, genom_context self ) {	

			uint32_t fop = inputProcPort->data( self )->framesOnPort; 	// total amount of Frames On the Port

			publishTDS_port ( &(inputProcPort->data( self )->left.data), left, &(inputProcPort->data( self )->right.data), right, fop, bytesPerFrame, self );
			
			inputProcPort->data( self )->lastFrameIndex = nfr;
			inputProcPort->write( self );
			
			return genom_ok;
	}

/* Pre Proc Port ----------------------------------------------------------------- */

	genom_event
	PORT::initPreProcPort ( const char *name, const rosAFE_preProcPort *preProcPort, uint32_t sampleRate,
							uint32_t bufferSize_s, genom_context self ) {
								
	  uint32_t fop =  sampleRate * bufferSize_s; /* total amount of Frames On the Port */
	  
	  preProcPort->open( name, self );
		
	  iniTDS_port(&(preProcPort->data( name, self )->left.data), &(preProcPort->data( name, self )->right.data), fop, true, self );
		  
	  preProcPort->data( name, self )->sampleRate = sampleRate;
	  preProcPort->data( name, self )->framesOnPort = fop;
	  preProcPort->data( name, self )->lastFrameIndex = 0;
	  
	  preProcPort->write( name, self );
	  
	  return genom_ok;
	}

	genom_event
	PORT::publishPreProcPort ( const char *name, const rosAFE_preProcPort *preProcPort, twoCTypeBlockPtr left, twoCTypeBlockPtr right, uint32_t bytesPerFrame, int64_t nfr, genom_context self ) {		
	   	
		uint32_t fop = preProcPort->data( name, self )->framesOnPort; // total amount of Frames On the Port

		publishTDS_port ( &(preProcPort->data( name, self )->left.data), left, &(preProcPort->data( name, self )->right.data), right, fop, bytesPerFrame, self );
							
		preProcPort->data( name, self )->lastFrameIndex = nfr;
		preProcPort->write( name, self );	

		return genom_ok;
	}

	genom_event
	PORT::deletePreProcPort   ( const char *name, const rosAFE_preProcPort *preProcPort, genom_context self ) {
		preProcPort->close( name, self );
		return genom_ok;
	}
	
/* Gammatone Port ----------------------------------------------------------------- */

	genom_event
	PORT::initGammatonePort ( const char *name, const rosAFE_gammatonePort *gammatonePort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nChannels, genom_context self ) {
							
	  gammatonePort->open( name, self );
							
	  uint32_t fop =  sampleRate * bufferSize_s; /* total amount of Frames On the Port */
	  
	  iniTFS_port ( &(gammatonePort->data( name, self )->left.dataN), &(gammatonePort->data( name, self )->right.dataN), nChannels,  fop, true, true, self );
		
	  gammatonePort->data( name, self )->sampleRate = sampleRate;
	  gammatonePort->data( name, self )->framesOnPort = fop;	  
	  gammatonePort->data( name, self )->numberOfChannels = nChannels;
	  gammatonePort->data( name, self )->lastFrameIndex = 0;
	  
	  gammatonePort->write( name, self );
	  
	  return genom_ok;
	}							
				
	genom_event
	PORT::publishGammatonePort ( const char *name, const rosAFE_gammatonePort *gammatonePort, std::vector<twoCTypeBlockPtr > left,
						std::vector<twoCTypeBlockPtr > right, uint32_t bytesPerFrame, int64_t nfr, genom_context self ) {
											
		rosAFE_TimeFrequencySignalPortStruct *thisPort;
					
		thisPort = gammatonePort->data( name, self );

		publishTFS_port ( &(thisPort->left.dataN), left,
						  &(thisPort->right.dataN), right, thisPort->numberOfChannels, 
						  thisPort->framesOnPort, bytesPerFrame, true, self );
		
		thisPort->lastFrameIndex = nfr;
		gammatonePort->write( name, self );			
							
		return genom_ok;							
	}

	genom_event
	PORT::deleteGammatonePort   ( const char *name, const rosAFE_gammatonePort *gammatonePort, genom_context self ) {
		gammatonePort->close( name, self );
		return genom_ok;		
	}
	
/* IHC Port ----------------------------------------------------------------- */

	genom_event
	PORT::initIHCPort ( const char *name, const rosAFE_ihcPort *ihcPort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nChannels, genom_context self ) {
	
	  uint32_t fop =  sampleRate * bufferSize_s; /* total amount of Frames On the Port */
	  
	  ihcPort->open( name, self );

	  iniTFS_port ( &(ihcPort->data( name, self )->left.dataN), &(ihcPort->data( name, self )->right.dataN), nChannels,  fop, true, true, self );

	  ihcPort->data( name, self )->sampleRate = sampleRate;
	  ihcPort->data( name, self )->framesOnPort = fop;	  
	  ihcPort->data( name, self )->numberOfChannels = nChannels;
	  ihcPort->data( name, self )->lastFrameIndex = 0;
	  
	  ihcPort->write( name, self );
	  
	  return genom_ok;
	}
	
	genom_event
	PORT::publishIHCPort ( const char *name, const rosAFE_ihcPort *ihcPort, std::vector<twoCTypeBlockPtr > left,
						std::vector<twoCTypeBlockPtr > right, uint32_t bytesPerFrame, int64_t nfr, genom_context self ) {	

		rosAFE_TimeFrequencySignalPortStruct *thisPort;
										
		thisPort = ihcPort->data( name, self );

		publishTFS_port ( &(thisPort->left.dataN), left,
						  &(thisPort->right.dataN), right, thisPort->numberOfChannels, 
						  thisPort->framesOnPort, bytesPerFrame, true, self );
		
		thisPort->lastFrameIndex = nfr;
		ihcPort->write( name, self );			
							
		return genom_ok;							
	}

	genom_event
	PORT::deleteIHCPort   ( const char *name, const rosAFE_ihcPort *ihcPort, genom_context self ) {
		ihcPort->close( name, self );
		return genom_ok;		
	}

/* ILD Port ----------------------------------------------------------------- */

	genom_event
	PORT::initILDPort ( const char *name, const rosAFE_ildPort *ildPort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nChannels, genom_context self ) {

	  uint32_t fop =  sampleRate * bufferSize_s; /* total amount of Frames On the Port */
	  
	  ildPort->open( name, self );

	  iniTFS_port ( &(ildPort->data( name, self )->left.dataN), nullptr, nChannels, fop, false, true, self );

	  ildPort->data( name, self )->sampleRate = sampleRate;
	  ildPort->data( name, self )->framesOnPort = fop;	  
	  ildPort->data( name, self )->numberOfChannels = nChannels;
	  ildPort->data( name, self )->lastFrameIndex = 0;
	  
	  ildPort->write( name, self );
	  
	  return genom_ok;					
	}

	genom_event
	PORT::publishILDPort ( const char *name, const rosAFE_ildPort *ildPort, std::vector<twoCTypeBlockPtr > left,
						uint32_t bytesPerFrame, int64_t nfr, genom_context self ) {

		rosAFE_TimeFrequencySignalPortStruct *thisPort;
										
		thisPort = ildPort->data( name, self );

		publishTFS_port ( &(thisPort->left.dataN), left, nullptr, left, thisPort->numberOfChannels, thisPort->framesOnPort, bytesPerFrame, false, self );
		
		thisPort->lastFrameIndex = nfr;
		ildPort->write( name, self );

	  return genom_ok;							
	}

	genom_event
	PORT::deleteILDPort   ( const char *name, const rosAFE_ildPort *ildPort, genom_context self ) {
		ildPort->close( name, self );
		return genom_ok;		
	}
	
/* Ratemap Port ----------------------------------------------------------------- */

	genom_event
	PORT::initRatemapPort ( const char *name, const rosAFE_ratemapPort *ratemapPort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nChannels, genom_context self ) {

	  uint32_t fop =  sampleRate * bufferSize_s; /* total amount of Frames On the Port */
	  
	  ratemapPort->open( name, self );

	  iniTFS_port ( &(ratemapPort->data( name, self )->left.dataN), &(ratemapPort->data( name, self )->right.dataN), nChannels, fop, true, true, self );

	  ratemapPort->data( name, self )->sampleRate = sampleRate;
	  ratemapPort->data( name, self )->framesOnPort = fop;	  
	  ratemapPort->data( name, self )->numberOfChannels = nChannels;
	  ratemapPort->data( name, self )->lastFrameIndex = 0;
	  
	  ratemapPort->write( name, self );
	  
	  return genom_ok;					
	}

	genom_event
	PORT::publishRatemapPort ( const char *name, const rosAFE_ratemapPort *ratemapPort, std::vector<twoCTypeBlockPtr > left,
						std::vector<twoCTypeBlockPtr > right, uint32_t bytesPerFrame, int64_t nfr, genom_context self ) {

		rosAFE_TimeFrequencySignalPortStruct *thisPort;
										
		thisPort = ratemapPort->data( name, self );

		publishTFS_port ( &(thisPort->left.dataN), left,
						  &(thisPort->right.dataN), right, thisPort->numberOfChannels, 
						  thisPort->framesOnPort, bytesPerFrame, true, self );
						  		
		thisPort->lastFrameIndex = nfr;
		ratemapPort->write( name, self );

	  return genom_ok;							
	}

	genom_event
	PORT::deleteRatemapPort ( const char *name, const rosAFE_ratemapPort *ratemapPort, genom_context self ) {
		ratemapPort->close( name, self );
		return genom_ok;		
	}
		
/* Cross-Correlation Port */

	genom_event
	PORT::initCrossCorrelationPort ( const char *name, const rosAFE_crossCorrelationPort *crossCorrelationPort, uint32_t sampleRate,
						uint32_t bufferSize_s, uint32_t nLag, uint32_t nChannels, genom_context self ) {
					
		uint32_t fop =  sampleRate * bufferSize_s;  // total amount of Frames On the Port 
		  
		crossCorrelationPort->open( name, self );

		iniCC_port ( &(crossCorrelationPort->data( name, self )->left.dataNxN), nLag, nChannels, fop, true, self );

		crossCorrelationPort->data( name, self )->sampleRate = sampleRate;
		crossCorrelationPort->data( name, self )->framesOnPort = fop;	  
		crossCorrelationPort->data( name, self )->numberOfLags = nLag;	  
		crossCorrelationPort->data( name, self )->numberOfChannels = nChannels;
		crossCorrelationPort->data( name, self )->lastFrameIndex = 0;
		  
		crossCorrelationPort->write( name, self );

		return genom_ok;
	}
						
	genom_event
	PORT::publishCrossCorrelationPort ( const char *name, const rosAFE_crossCorrelationPort *crossCorrelationPort, std::vector<std::vector<twoCTypeBlockPtr > > left,
						uint32_t bytesPerFrame, int64_t nfr, genom_context self ) {
							
		rosAFE_CrossCorrelationSignalPortStruct *thisPort;		

		thisPort = crossCorrelationPort->data( name, self );

		publishCC_port ( &(thisPort->left.dataNxN), left,
						 thisPort->numberOfLags, thisPort->numberOfChannels, 
						 thisPort->framesOnPort, bytesPerFrame, self );
						  		
		thisPort->lastFrameIndex = nfr;
		crossCorrelationPort->write( name, self );
		
		return genom_ok;				
	}
	
	genom_event
	PORT::deleteCrossCorrelationPort ( const char *name, const rosAFE_crossCorrelationPort *crossCorrelationPort, genom_context self ) {
		crossCorrelationPort->close( name, self );
		return genom_ok;					
	}
