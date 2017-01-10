#include "ildProc.hpp"

using namespace openAFE;
using namespace std;

			void ILDProc::ild( double* frame_r, double* frame_l, double* value ) {	
				*value = 10 * log10 ( ( *frame_r + EPSILON ) / ( *frame_l + EPSILON ) );
			}

			void ILDProc::processChannel ( const size_t ii, const size_t totalFrames,
										   const shared_ptr<twoCTypeBlock<double> > leftChannel,
										   const shared_ptr<twoCTypeBlock<double> > rightChannel ) {
				
				double* firstValue_l = leftChannel->array1.first;
				double* firstValue_r = rightChannel->array1.first;
				
				uint32_t n_start;			
			    vector<double > tmpWindowLeft( this->wSize ), tmpWindowRight( this->wSize );
				double value, mSq_l, mSq_r;
							
				for ( size_t iii = 0 ; iii < totalFrames ; ++iii ) {
					n_start = iii * this->hSize;

					multiplication( this->win.data(), firstValue_l + n_start, this->wSize, tmpWindowLeft.data() );
					multiplication( this->win.data(), firstValue_r + n_start, this->wSize, tmpWindowRight.data() );
					
					mSq_l = meanSquare( tmpWindowLeft.data(), this->wSize );
					mSq_r = meanSquare( tmpWindowRight.data(), this->wSize );					

					this->ild( &mSq_r, &mSq_l, &value );	
						
					leftPMZ->appendFrameToChannel( ii, &value );	
				}
				leftPMZ->setLastChunkSize( ii, totalFrames );
			}
					
			ILDProc::ILDProc (const string nameArg, shared_ptr<IHCProc > upperProcPtr, double wSizeSec, double hSizeSec, windowType wname  )
			: WindowBasedProcs (nameArg, upperProcPtr, _ild, wSizeSec, hSizeSec, wname, _magnitude ) {

			}

			ILDProc::~ILDProc () {
				
			}
			
			void ILDProc::processChunk () {				
				this->setNFR ( this->upperProcPtr->getNFR() );						

				// Append provided input to the buffer
				this->buffer_l->appendChunk( this->upperProcPtr->getLeftLastChunkAccessor() );
				this->buffer_r->appendChunk( this->upperProcPtr->getRightLastChunkAccessor() );
				
				/* The buffer should be linearized for windowing. */
				this->buffer_l->linearizeBuffer();	// dim2 is now 0.
				this->buffer_r->linearizeBuffer();  // dim2 is now 0.

				size_t totalFrames = floor( ( this->buffer_l->getSize() - ( this->wSize - this->hSize ) ) / this->hSize );

				vector<shared_ptr<twoCTypeBlock<double> > > l_innerBuffer = buffer_l->getWholeBufferAccesor();
				vector<shared_ptr<twoCTypeBlock<double> > > r_innerBuffer = buffer_r->getWholeBufferAccesor();

				// Quick control of dimensionality
				assert( l_innerBuffer.size() == r_innerBuffer.size() );
												
				size_t ii;
				for ( ii = 0 ; ii < this->fb_nChannels ; ++ii )
					this->processChannel( ii, totalFrames, l_innerBuffer[ii], r_innerBuffer[ii] );
				
				this->buffer_l->pop_chunk( totalFrames * this->hSize );
				this->buffer_r->pop_chunk( totalFrames * this->hSize );			
			}
