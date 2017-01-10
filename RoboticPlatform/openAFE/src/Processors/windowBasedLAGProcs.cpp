#include "windowBasedLAGProcs.hpp"

using namespace openAFE;

			uint32_t WindowBasedLAGProcs::calcFsOut( double ild_hSizeSec ) {
				return 1 / ild_hSizeSec;
			}

			void WindowBasedLAGProcs::prepareForProcessing() {

				// Compute internal parameters
				this->wSize = 2 * round( this->wSizeSec * this->getFsIn() / 2 );
				this->hSize = round( this->hSizeSec * this->getFsIn() );		
		
				switch ( this->wname ) {
					case _hamming: 
						this->win = hamming( this->wSize );
						break;
					case _hanning: 
						this->win = hanning( this->wSize );
						break;
					case _hann: 
						this->win = hann( this->wSize );
						break;
					case _blackman: 
						this->win = blackman( this->wSize );
						break;
					case _triang: 
						this->win = triang( this->wSize );
						break;
					case _sqrt_win: 
						this->win = sqrt_win( this->wSize );
						break;
					default:
						this->win.resize( this->wSize, 0 );
						break;
				}
				
				this->zerosAccecor.reset( new twoCTypeBlock<double>() );
			}
			
			WindowBasedLAGProcs::WindowBasedLAGProcs (const std::string nameArg, std::shared_ptr<IHCProc > upperProcPtr, procType typeOfThisProc, std::size_t nLags, double wSizeSec, double hSizeSec, windowType wname )
			: LAGProcessor<double > (nameArg, upperProcPtr->getFsOut(), this->calcFsOut( hSizeSec ), upperProcPtr->getBufferSize_s(), upperProcPtr->get_nChannel(), nLags, typeOfThisProc) {
									
				this->upperProcPtr = upperProcPtr;
				this->wSizeSec = wSizeSec;
				this->hSizeSec = hSizeSec;
				this->wname = wname;
		
				this->buffer_l.reset( new TimeFrequencySignal<double>( this->getFsIn(), this->getBufferSize_s(), this->get_nChannel(), "inner buffer", _magnitude, _left) );
				this->buffer_r.reset( new TimeFrequencySignal<double>( this->getFsIn(), this->getBufferSize_s(), this->get_nChannel(), "inner buffer", _magnitude, _right) );
												
				this->prepareForProcessing();
			}

			WindowBasedLAGProcs::~WindowBasedLAGProcs () {
				
				this->win.clear();
				this->buffer_l.reset();
				this->buffer_r.reset();
			}
			
			/* Comapres informations and the current parameters of two processors */
			bool WindowBasedLAGProcs::operator==( WindowBasedLAGProcs& toCompare ) {
				if ( this->compareBase( toCompare ) )
					if ( ( this->get_wSizeSec() == toCompare.get_wSizeSec() ) and 
						 ( this->get_hSizeSec() == toCompare.get_hSizeSec() ) and 					
						 ( this->get_wname() == toCompare.get_wname() ) )				     		     			     
						return true;
				return false;
			}

			// getters
			const double WindowBasedLAGProcs::get_wSizeSec() {return this->wSizeSec;}
			const double WindowBasedLAGProcs::get_hSizeSec() {return this->hSizeSec;}
			const windowType WindowBasedLAGProcs::get_wname() {return this->wname;}
			
			const uint32_t WindowBasedLAGProcs::get_nChannels() {return this->get_nChannel();}

			// setters			
			void WindowBasedLAGProcs::set_wSizeSec(const double arg) {this->wSizeSec=arg; this->prepareForProcessing ();}
			void WindowBasedLAGProcs::set_hSizeSec(const double arg) {this->hSizeSec=arg; this->prepareForProcessing ();}
			void WindowBasedLAGProcs::set_wname(const windowType arg) {this->wname=arg; this->prepareForProcessing ();}

			std::string WindowBasedLAGProcs::get_upperProcName() {return this->upperProcPtr->getName();}
