#ifndef LAGPROCESSOR_HPP
#define LAGPROCESSOR_HPP

#include <thread>
#include <memory>


#include "Processor.hpp"
#include "../Signals/CorrelationSignal.hpp"

namespace openAFE {

   template<typename T = double>
   class LAGProcessor  : public Processor {
	   
	   protected:
	               			
			std::shared_ptr <CorrelationSignal<T> > leftOutput, rightOutput;
			std::shared_ptr <CorrelationSignal<T> > leftPMZ, rightPMZ;
			
		public:
		
			LAGProcessor (const std::string nameArg, const uint32_t fsIn, const uint32_t fsOut, const double bufferSize_s, size_t nChannel, size_t nLag, procType typeArg) : Processor (bufferSize_s, fsIn, fsOut, nChannel, nameArg, typeArg) {

				/* Creating the output signals */
				if ( this->hasTwoOutputs == true ) {
					leftOutput.reset( new CorrelationSignal<T>(fsOut, bufferSize_s, nChannel, nLag, nameArg, _left) );
					rightOutput.reset( new CorrelationSignal<T>(fsOut, bufferSize_s, nChannel, nLag, nameArg, _right) );
							
					/* Creating the PMZ signals */
					leftPMZ.reset( new CorrelationSignal<T>(fsOut, bufferSize_s, nChannel, nLag, "Left_PMZ", _left) );
					rightPMZ.reset( new CorrelationSignal<T>(fsOut, bufferSize_s, nChannel, nLag, "Right_PMZ", _right) );
				} else {
					leftOutput.reset( new CorrelationSignal<T>(fsOut, bufferSize_s, nChannel, nLag, nameArg, _mono ) );
							
					/* Creating the PMZ signals */
					leftPMZ.reset( new CorrelationSignal<T>(fsOut, bufferSize_s, nChannel, nLag, "Mono_PMZ", _mono ) );
				}
			}
			
			~LAGProcessor() {
				
				leftOutput.reset();
				rightOutput.reset();
				leftPMZ.reset();
				rightPMZ.reset();
			}
			
			void reset() {
				leftOutput->reset();
				rightOutput->reset();
				leftPMZ->reset();
				rightPMZ->reset();
			}

			std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > > getLeftLastChunkAccessor() { 
				return this->leftOutput->getLastChunkAccesor();
			}

			std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > > getRightLastChunkAccessor() {
				return this->rightOutput->getLastChunkAccesor();
			}

			std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > > getLeftWholeBufferAccessor() {
				return this->leftOutput->getWholeBufferAccesor();
			}

			std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > > getRightWholeBufferAccessor() {
				return this->rightOutput->getWholeBufferAccesor();
			}

			std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > > getLeftOldDataAccessor() {
				return this->leftOutput->getOldDataAccesor();
			}

			std::vector<std::vector<std::shared_ptr<twoCTypeBlock<T> > > > getRightOldDataAccessor() {
				return this->rightOutput->getOldDataAccesor();
			}
			
			void releaseChunk () {
				if ( this->hasTwoOutputs ) {						
					//std::thread leftAppendThread( &TimeFrequencySignal<T>::appendChunk, this->leftOutput, leftPMZ->getLastChunkAccesor() );
					//std::thread rightAppendThread( &TimeFrequencySignal<T>::appendChunk, this->rightOutput, rightPMZ->getLastChunkAccesor() );
						
					//leftAppendThread.join();                // pauses until left finishes
					//rightAppendThread.join();               // pauses until right finishes
					this->leftOutput->appendChunk( leftPMZ->getLastChunkAccesor() );
					this->rightOutput->appendChunk( rightPMZ->getLastChunkAccesor() );
				} else this->leftOutput->appendChunk( leftPMZ->getLastChunkAccesor() );	
			}

			
	};  /* LAGProcessor */

}; /* namespace openAFE */			
#endif /* LAGPROCESSOR_HPP */			
