#include "Signal.hpp"

using namespace openAFE;
				      
		Signal::Signal( const uint32_t fs, const std::string& nameArg, const double bufferSize_s, channel cha ) {
		
			this->FsHz = fs;
			this->Name = nameArg;
			this->Channel = cha;

			/* Calculation of the buffer size in samples */
			this->bufferSizeSamples = floor( bufferSize_s * this->FsHz );
		}
		
		Signal::~Signal() { }
											
		const std::string Signal::getName() {
			return this->Name;
		}
		
		/* getChannel : returns the channel of this signal */
		const channel Signal::getChannel() {  
			return this->Channel;
		}
