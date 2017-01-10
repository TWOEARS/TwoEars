#ifndef TFSPROCESSOR_HPP
#define TFSPROCESSOR_HPP

#include <thread>

#include "Processor.hpp"
#include "../Signals/TimeFrequencySignal.hpp"

namespace openAFE {

   template<typename T = double>
   class TFSProcessor  : public Processor {
	   
	   protected:
	               			
			std::shared_ptr <TimeFrequencySignal<T> > leftOutput, rightOutput;
			std::shared_ptr <TimeFrequencySignal<T> > leftPMZ, rightPMZ;
						
		public:
		
			TFSProcessor (const std::string nameArg, const uint32_t fsIn, const uint32_t fsOut, const double bufferSize_s, size_t nChannel, scalingType argScaling, procType typeArg) : Processor (bufferSize_s, fsIn, fsOut, nChannel, nameArg, typeArg) {

				/* Creating the output signals */
				if ( this->hasTwoOutputs == true ) {
					leftOutput.reset( new TimeFrequencySignal<T>(fsOut, bufferSize_s, nChannel, nameArg, argScaling, _left) );
					rightOutput.reset( new TimeFrequencySignal<T>(fsOut, bufferSize_s, nChannel, nameArg, argScaling, _right) );
							
					/* Creating the PMZ signals */
					leftPMZ.reset( new TimeFrequencySignal<T>(fsOut, bufferSize_s, nChannel, "Left_PMZ", argScaling, _left) );
					rightPMZ.reset( new TimeFrequencySignal<T>(fsOut, bufferSize_s, nChannel, "Right_PMZ", argScaling, _right) );
				} else {
					leftOutput.reset( new TimeFrequencySignal<T>(fsOut, bufferSize_s, nChannel, nameArg, argScaling, _mono ) );
							
					/* Creating the PMZ signals */
					leftPMZ.reset( new TimeFrequencySignal<T>(fsOut, bufferSize_s, nChannel, "Mono_PMZ", argScaling, _mono ) );					
				}
				
			}
			
			~TFSProcessor() {
				
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

			inline
			std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getLeftLastChunkAccessor() { 
				return this->leftOutput->getLastChunkAccesor();
			}

		    inline
			std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getRightLastChunkAccessor() {
				return this->rightOutput->getLastChunkAccesor();
			}

			std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getLeftWholeBufferAccessor() {
				return this->leftOutput->getWholeBufferAccesor();
			}

			std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getRightWholeBufferAccessor() {
				return this->rightOutput->getWholeBufferAccesor();
			}

			std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getLeftOldDataAccessor() {
				return this->leftOutput->getOldDataAccesor();
			}

			std::vector<std::shared_ptr<twoCTypeBlock<T> > >& getRightOldDataAccessor() {
				return this->rightOutput->getOldDataAccesor();
			}
			
			void releaseChunk () {
				if ( this->hasTwoOutputs ) {						
					std::thread leftAppendThread( &TimeFrequencySignal<T>::appendChunk, this->leftOutput, std::ref(this->leftPMZ->getLastChunkAccesor()) );
					std::thread rightAppendThread( &TimeFrequencySignal<T>::appendChunk, this->rightOutput, std::ref(this->rightPMZ->getLastChunkAccesor()) );
						
					leftAppendThread.join();                // pauses until left finishes
					rightAppendThread.join();               // pauses until right finishes
				} else this->leftOutput->appendChunk( leftPMZ->getLastChunkAccesor() );	
			}
			
	};  /* TFSProcessor */

}; /* namespace openAFE */			
#endif /* TDSPROCESSOR_HPP */			
