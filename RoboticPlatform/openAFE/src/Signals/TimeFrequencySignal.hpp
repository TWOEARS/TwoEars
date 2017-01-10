#ifndef TIMEFREQUENCYSIGNAL_HPP
#define TIMEFREQUENCYSIGNAL_HPP

/*
 * TIMEFREQUENCYSIGNAL Signal class for two-dimensional, time-frequency representations.
 * This children signal class regroups all signal that are some sort of time frequency 
 * representation, including representation that were decimated in time.
 * 
 */ 

#include <string>
#include <stdint.h>

#include "dataType.hpp"
#include "circularContainer.hpp"
#include "Signal.hpp"

namespace openAFE {
	
	template<typename T = double>	
	class TimeFrequencySignal : public Signal {
	
	private:

		/* cfHz : Center frequencies of the frequency channels */
		std::size_t nChannel;	
		
		std::vector<std::shared_ptr<CircularContainer<T> > > buffer;
		std::vector<std::shared_ptr<twoCTypeBlock<T> > > lastChunkInfo, wholeBufferInfo, oldDataInfo;
		
		scalingType scaling;

	public:

		/*       fs : Sampling frequency (Hz)
         *     name : Name tag of the signal, should be compatible with
         *            variable name syntax.
         *     cfHz : Center frequencies of the channels in Hertz.
         *    label : Label for the signal, to be used in e.g. figures
         *                 (default: label = name)
         *  channel : Flag indicating 'left', 'right', or 'mono'
         *               (default: channel = 'mono')
        */    

		TimeFrequencySignal( const uint32_t fs, const double bufferSize_s, std::size_t nChannel,
							 const std::string argName = "tfRepresentation",
							 scalingType argScaling = _magnitude, channel cha = _mono) : Signal(fs, argName, bufferSize_s, cha) {
													
			this->nChannel = nChannel;
			this->scaling = argScaling;
			
			buffer.resize( this->nChannel );
			lastChunkInfo.resize( this->nChannel );
			wholeBufferInfo.resize( this->nChannel );
			oldDataInfo.resize( this->nChannel );
			
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				buffer[ii].reset( new CircularContainer<T>( this->bufferSizeSamples ) );
				lastChunkInfo[ii].reset( new twoCTypeBlock<T> );
				wholeBufferInfo[ii].reset( new twoCTypeBlock<T> );
				oldDataInfo[ii].reset( new twoCTypeBlock<T> );
			}
		}

		/* Calls automatically Signal's destructor */
		~TimeFrequencySignal() {
			this->buffer.clear();
			this->lastChunkInfo.clear();
			this->wholeBufferInfo.clear();
			this->oldDataInfo.clear();
		}
		
		void appendNChunk( std::shared_ptr<twoCTypeBlock<T> > inChunk ) {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				buffer[ii]->push_chunk( inChunk );
		}

		inline
		void appendFrameToChannel( const size_t ii, const T* inFrame ) {
				buffer[ii]->push_frame( inFrame );
		}

		void setLastChunkSize( const size_t ii, size_t lastChunkSize ) {
				buffer[ii]->setLastChunkSize( lastChunkSize );
		}
		
		void appendChunk( const std::vector<std::shared_ptr<twoCTypeBlock<T> > >& inChunk ) {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				buffer[ii]->push_chunk( inChunk[ii] );
		}
		
		inline
		std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getLastChunkAccesor() {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				this->lastChunkInfo[ii]->setData( this->buffer[ii]->getLastChunkAccesor() );
			}
			return this->lastChunkInfo;
		}
		
		std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getWholeBufferAccesor() {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				this->wholeBufferInfo[ii]->setData( this->buffer[ii]->getWholeBufferAccesor() );
			}
			return this->wholeBufferInfo;
		}

		std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getOldDataAccesor() {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii ) {
				this->oldDataInfo[ii]->setData( this->buffer[ii]->getOldDataAccesor() );
			}
			return this->oldDataInfo;
		}
				
		/* Puts zero to all over the buffer */
		void reset () {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				this->buffer[ii]->reset();
		}		

		void pop_chunk ( std::size_t numberOfFrames ) {
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				this->buffer[ii]->pop_chunk( numberOfFrames );
		}
		
		/* Linearize the internal buffer into a continuous array.
		 * Get the data with getWholeBufferAccesor() just after calling this function
		 */
		void linearizeBuffer(){
			for ( std::size_t ii = 0 ; ii < this->nChannel ; ++ii )
				this->buffer[ii]->linearizeBuffer();			
		}

		void linearizeOneBuffer( std::size_t ii ) {
			if ( ii < this->nChannel )
				this->buffer[ii]->linearizeBuffer();			
		}
		
		std::size_t getSize() {
			return this->buffer[0]->getSize();
		}
		
	}; /* class TimeFrequencySignal */
};	/* namespace openAFE */

#endif /* TIMEFREQUENCYSIGNAL_HPP */
