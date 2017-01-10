#include "windowBasedProcs.hpp"

using namespace openAFE;
using namespace std;

			uint32_t WindowBasedProcs::calcFsOut( double hSizeSec ) {
				return 1 / hSizeSec;
			}

			void WindowBasedProcs::prepareForProcessing() {

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
					
			WindowBasedProcs::WindowBasedProcs (const string nameArg, shared_ptr<IHCProc > upperProcPtr, procType typeOfThisProc, double wSizeSec, double hSizeSec, windowType wname, scalingType scailingArg  )
			: TFSProcessor<double > (nameArg, upperProcPtr->getFsOut(), this->calcFsOut( hSizeSec ), upperProcPtr->getBufferSize_s(), upperProcPtr->get_nChannel(), _magnitude, typeOfThisProc) {
					
				this->fb_nChannels = upperProcPtr->get_nChannel();
				
				this->upperProcPtr = upperProcPtr;
				this->wSizeSec = wSizeSec;
				this->hSizeSec = hSizeSec;
				this->wname = wname;
				
				this->buffer_l.reset( new TimeFrequencySignal<double>( this->getFsIn(), this->getBufferSize_s(), this->fb_nChannels, "inner buffer", scailingArg, _left) );
				this->buffer_r.reset( new TimeFrequencySignal<double>( this->getFsIn(), this->getBufferSize_s(), this->fb_nChannels, "inner buffer", scailingArg, _right) );
												
				this->prepareForProcessing();
			}

			WindowBasedProcs::~WindowBasedProcs () {
				
				this->win.clear();
				this->buffer_l.reset();
				this->buffer_r.reset();
			}
			
			/* Comapres informations and the current parameters of two processors */
			bool WindowBasedProcs::operator==( WindowBasedProcs& toCompare ) {
				if ( this->compareBase( toCompare ) )
					if ( ( this->get_wSizeSec() == toCompare.get_wSizeSec() ) and 
						 ( this->get_hSizeSec() == toCompare.get_hSizeSec() ) and 					
						 ( this->get_wname() == toCompare.get_wname() ) )				     		     			     
						return true;
				return false;
			}

			// getters
			const double WindowBasedProcs::get_wSizeSec() {return this->wSizeSec;}
			const double WindowBasedProcs::get_hSizeSec() {return this->hSizeSec;}
			const windowType WindowBasedProcs::get_wname() {return this->wname;}
			
			const uint32_t WindowBasedProcs::get_nChannels() {return this->fb_nChannels;}

			// setters			
			void WindowBasedProcs::set_wSizeSec(const double arg) {this->wSizeSec=arg; this->prepareForProcessing ();}
			void WindowBasedProcs::set_hSizeSec(const double arg) {this->hSizeSec=arg; this->prepareForProcessing ();}
			void WindowBasedProcs::set_wname(const windowType arg) {this->wname=arg; this->prepareForProcessing ();}

			string WindowBasedProcs::get_upperProcName() {return this->upperProcPtr->getName();}
