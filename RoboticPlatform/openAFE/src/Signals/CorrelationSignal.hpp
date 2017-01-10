#ifndef CORRELATIONSIGNAL_HPP
#define CORRELATIONSIGNAL_HPP

/*
 * CORRELATIONSIGNAL Signal class for three-dimensional correlation signals.
 *    This class collects all signals resulting from a correlation computation on a
 *    time-frequency representation in short time windows (e.g., auto-correlation, 
 *    cross-correlation). Its data is therefore three dimensional, with first to third
 *    dimension respectively related to time, frequency, and lag.
 */ 

#include <string>
#include <stdint.h>
#include <memory>

#include "dataType.hpp"
#include "circularContainer.hpp"
#include "Signal.hpp"

namespace openAFE {
	
	template<typename T = double>	
	class CorrelationSignal : public Signal {
	
	private:

		std::size_t nChannel;	
		std::size_t nLags;		
		
		std::vector<std::vector<std::shared_ptr<CircularContainer<T> > > > buffer;
		std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > > lastChunkInfo, wholeBufferInfo, oldDataInfo;

	public:


		CorrelationSignal( const uint32_t fs, const double bufferSize_s, std::size_t nChannel, std::size_t nLags,
							 const std::string argName = "crosscorrelation",
							 channel cha = _mono) : Signal(fs, argName, bufferSize_s, cha) {
													
			this->nChannel = nChannel;
			this->nLags = nLags;
						
			buffer.resize( this->nChannel );
			lastChunkInfo.resize( this->nChannel );
			wholeBufferInfo.resize( this->nChannel );
			oldDataInfo.resize( this->nChannel );

			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				buffer[ii].resize( this->nLags );
				lastChunkInfo[ii].resize( this->nLags );
				wholeBufferInfo[ii].resize( this->nLags );
				oldDataInfo[ii].resize( this->nLags );
			}

			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj ) {
					buffer[ii][jj].reset( new CircularContainer<T>( this->bufferSizeSamples ) );
					lastChunkInfo[ii][jj].reset( new twoCTypeBlock<T> );
					wholeBufferInfo[ii][jj].reset( new twoCTypeBlock<T> );
					oldDataInfo[ii][jj].reset( new twoCTypeBlock<T> );
				}
			}			

		}

		/* Calls automatically Signal's destructor */
		~CorrelationSignal() {
			this->buffer.clear();
			this->lastChunkInfo.clear();
			this->wholeBufferInfo.clear();
			this->oldDataInfo.clear();
		}

		void appendChunk( std::shared_ptr<twoCTypeBlock<T> > inChunk ) {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj )
					buffer[ii][jj]->push_chunk( inChunk );
		}
		
		void appendChunk( std::vector<std::shared_ptr<twoCTypeBlock<T> > > inChunk ) {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj )
					buffer[ii][jj]->push_chunk( inChunk[ii] );
		}

		void appendChunk( std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > > inChunk ) {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj )
					buffer[ii][jj]->push_chunk( inChunk[ii][jj] );
		}
				
		std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > >& getLastChunkAccesor() {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj ) {
					this->lastChunkInfo[ii][jj]->setData( this->buffer[ii][jj]->getLastChunkAccesor() );
				}
			}
			return this->lastChunkInfo;
		}
		
		std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > >& getWholeBufferAccesor() {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj ) {				
					this->wholeBufferInfo[ii][jj]->setData( this->buffer[ii][jj]->getWholeBufferAccesor() );
				}
			}
			return this->wholeBufferInfo;
		}

		std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > >& getOldDataAccesor() {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj ) {				
					this->oldDataInfo[ii][jj]->setData( this->buffer[ii][jj]->getOldDataAccesor() );
				}
			}
			return this->oldDataInfo;
		}
			
		// Puts zero to all over the buffer
		void reset () {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj )
					this->buffer[ii][jj]->reset();
		}		

		void pop_chunk ( std::size_t numberOfFrames ) {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj )
					this->buffer[ii][jj]->pop_chunk( numberOfFrames );
		}
		
		/* Linearize the internal buffer into a continuous array.
		 * Get the data with getWholeBufferAccesor() just after calling this function
		 */
		void linearizeBuffer() {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				for ( std::size_t jj = 0 ; jj < this->nLags ; ++jj )
					this->buffer[ii][jj]->linearizeBuffer();
		}
		
		std::size_t getSize() {
			return this->buffer[0][0]->getSize();
		}

		inline
		void appendFrameToChannel( const std::size_t n_channel,  const std::size_t n_lag, const T inFrame ) {		
				buffer[n_channel][n_lag]->push_frame( &inFrame );
		}
		
		void setLastChunkSize( const std::size_t n_channel,  const std::size_t n_lag, const size_t lastChunkSize ) {
				buffer[n_channel][n_lag]->setLastChunkSize( lastChunkSize );
		}		
				
	}; /* class CorrelationSignal */
};	/* namespace openAFE */

#endif /* CORRELATIONSIGNAL_HPP */
