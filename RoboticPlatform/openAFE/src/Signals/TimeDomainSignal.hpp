#ifndef TIMEDOMAINSIGNAL_H
#define TIMEDOMAINSIGNAL_H

#include <stdint.h>
#include <string>
#include <memory>

#include "dataType.hpp"
#include "circularContainer.hpp"
#include "Signal.hpp"

namespace openAFE {
	
	template<typename T>
	class TimeDomainSignal : public Signal {
	
	private:
	
	    std::shared_ptr<CircularContainer<T> > buffer;
	    std::shared_ptr<twoCTypeBlock<T> > lastChunkInfo, wholeBufferInfo, oldDataInfo;
			    
	public:
			
		/* Create a TimeDomainSignal without initialising a first chunk */
		TimeDomainSignal( const uint32_t fs, const double bufferSize_s, const std::string argName = "Time", channel cha = _mono) : Signal(fs, argName, bufferSize_s, cha) {
	
			this->buffer.reset( new CircularContainer<T>( this->bufferSizeSamples ) );
			this->lastChunkInfo.reset( new twoCTypeBlock<T> );
			this->wholeBufferInfo.reset( new twoCTypeBlock<T> );
			this->oldDataInfo.reset( new twoCTypeBlock<T> );			
		}
		
		/* Calls automatically Signal's destructor */
		~TimeDomainSignal() {
			this->buffer.reset();
			this->lastChunkInfo.reset();
			this->wholeBufferInfo.reset();
			this->oldDataInfo.reset();
		}

		void appendFrame( T* inFrame ) {
			this->buffer->push_frame( inFrame );
		}

		void setLastChunkSize( std::size_t lastChunkSize ) {
			this->buffer->setLastChunkSize( lastChunkSize );
		}
						
		void appendChunk( std::shared_ptr<twoCTypeBlock<T> > inChunk ) {
			this->buffer->push_chunk( inChunk );
		}
		
		std::shared_ptr<twoCTypeBlock<T> > getLastChunkAccesor() {
			this->lastChunkInfo->setData( this->buffer->getLastChunkAccesor() );
			return this->lastChunkInfo;
		}

		std::shared_ptr<twoCTypeBlock<T> > getWholeBufferAccesor() {
			this->wholeBufferInfo->setData( this->buffer->getWholeBufferAccesor() );
			return this->wholeBufferInfo;
		}

		std::shared_ptr<twoCTypeBlock<T> > getOldDataAccesor() {
			this->oldDataInfo->setData( this->buffer->getOldDataAccesor() );
			return this->oldDataInfo;
		}
				
		/* Puts zero to all over the buffer */
		void reset () {
			this->buffer->reset();
		}
		
	};
};

#endif /* TIMEDOMAINSIGNAL_H */
