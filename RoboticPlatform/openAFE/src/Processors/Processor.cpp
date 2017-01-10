#include "Processor.hpp"

using namespace openAFE;

			Processor::Processor (const double bufferSize_s, const uint32_t fsIn, const uint32_t fsOut, const std::size_t nChannel, const std::string& nameArg, procType typeArg) {
								
				this->fsIn = fsIn;
				this->fsOut = fsOut;
				this->type = typeArg;
				this->bufferSize_s = bufferSize_s;
				this->nChannel = nChannel;
												
				this->name = nameArg;
					
				switch ( typeArg ) {
					case _inputProc:
					  this->hasTwoOutputs = true;
					  break;
					case _preProc:
					  this->hasTwoOutputs = true;
					  break;
					case _gammatone:
					  this->hasTwoOutputs = true;
					  break;
					case _ihc:
					  this->hasTwoOutputs = true;
					  break;
					case _ild:
					  this->hasTwoOutputs = false;
					  break;
					case _ratemap:
					  this->hasTwoOutputs = true;
					  break;
					case _crosscorrelation:
					  this->hasTwoOutputs = false;
					  break;
					case _itd:
					  this->hasTwoOutputs = false;
					  break;					  	  
					default:
					  this->hasTwoOutputs = true;
					  break;
					}						
			}
			
			Processor::~Processor () {	}
			
			/* Returns a const reference of the type of this processor */		
			const procType Processor::getType() {
				return type;
			}
			
			/* Compare only the information of the two processors */
			const bool Processor::compareBase ( Processor& toCompare ) {
				if ( ( this->name == toCompare.getName() ) && ( this->type == toCompare.getType() ) )
					return true;
				return false;
			}

			const uint32_t Processor::getFsOut() {
				return this->fsOut;
			}

			const uint32_t Processor::getFsIn() {
				return this->fsIn;
			}
			
			const uint64_t Processor::getNFR() {
				return this->nfr;
			}
			
			void Processor::setNFR ( const uint64_t nfrArg ) {
				this->nfr = nfrArg;
			}
			
			const std::string Processor::getName() {
				return this->name;
			}							
			
			const double Processor::getBufferSize_s() {
				return this->bufferSize_s;
			}

			std::size_t Processor::get_nChannel() {return this->nChannel;}		
			
