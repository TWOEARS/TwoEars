#include "crossCorrelation.hpp"

#include <iostream>


using namespace openAFE;
using namespace std;

			size_t CrossCorrelation::getNLags( double maxDelaySec, double fs ) {
				this->maxLag = ceil( maxDelaySec * fs );
				size_t lagN = maxLag * 2 + 1;
				
				this->lags.resize( lagN );
				
				this->lags = linspace<double>(-this->maxLag, this->maxLag, lagN);
				for ( size_t i = 0 ; i < lagN ; ++i )
					this->lags[i] /= fs;
					
				return lagN;
			}

			void CrossCorrelation::prepareForProcessing() {
				this->getNLags( this->maxDelaySec, this->getFsIn() );

			}

			void CrossCorrelation::process( size_t totalFrames, size_t jj, double* firstValue_l, double* firstValue_r ) {
					size_t n_start = 0;
					vector<double > tmpWindowLeft( this->wSize ), tmpWindowRight( this->wSize );
					for ( size_t ii = 0 ; ii < totalFrames ; ++ii ) {

						n_start = ii * this->hSize;
							
						this->processChannel( firstValue_l + n_start, firstValue_r + n_start, jj, totalFrames, tmpWindowLeft.data(), tmpWindowRight.data()  );
					}				
			}

			void CrossCorrelation::processChannel( double* firstValue_l, double* firstValue_r, size_t jj, size_t totalFrames,  double* tmpWindowLeft, double* tmpWindowRight ) {

				// Extract frame for left and right input		
				multiplication( this->win.data(), firstValue_l, this->wSize, tmpWindowLeft );
				multiplication( this->win.data(), firstValue_r, this->wSize, tmpWindowRight );						

				// Compute the N-points for the Fourier domain
				size_t N = pow (2,nextpow2(2 * this->wSize - 1));

				// Compute the frames in the Fourier domain										
				vector<complex<double> > leftFFT = fft( tmpWindowLeft, this->wSize, N );
				vector<complex<double> > rightFFT = fft( tmpWindowRight, this->wSize, N );
																
				// Compute cross-power spectrum
				_conj( rightFFT );
				multiplication( leftFFT.data(), rightFFT.data(), leftFFT.size(), leftFFT.data() );
				
				// Back to time domain
				vector<double> c = ifft( leftFFT.data(), this->wSize, N );
				
				double powL = sumPow( tmpWindowLeft, this->wSize, 2 );
				double powR = sumPow( tmpWindowRight, this->wSize, 2 );
				
				double div = sqrt( powL * powR + EPSILON );
				
				std::size_t jjL = 0;
				if ( this->maxLag > this->wSize ) {
					// Then pad with zeros
					// TODO : Check this case
					for( std::size_t ii = 0 ; ii < this->maxLag - this->wSize ; ++ii, ++jjL ) {
						this->leftPMZ->appendFrameToChannel(jj, jjL, 0 / div);
						this->leftPMZ->setLastChunkSize( jj, jjL, totalFrames);	
					}
					for( std::size_t ii = this->maxLag - this->wSize + 2 ; ii < this->maxLag ; ++ii, ++jjL ) {
						this->leftPMZ->appendFrameToChannel(jj, jjL, c[ii] / div);
						this->leftPMZ->setLastChunkSize( jj, jjL, totalFrames);	
					}
					for( std::size_t ii = 0 ; ii < this->wSize ; ++ii, ++jjL ) {
						this->leftPMZ->appendFrameToChannel(jj, jjL, c[ii] / div);
						this->leftPMZ->setLastChunkSize( jj, jjL, totalFrames);	
					}
					for( std::size_t ii = 0 ; ii < this->maxLag - this->wSize ; ++ii, ++jjL ) {
						this->leftPMZ->appendFrameToChannel(jj, jjL, 0 / div);
						this->leftPMZ->setLastChunkSize( jj, jjL, totalFrames);	
					}
				} else {
					// Else keep lags lower than requested max
					for( std::size_t ii = N - this->maxLag ; ii < N ; ++ii, ++jjL ) {
						this->leftPMZ->appendFrameToChannel(jj, jjL, c[ii] / div);
						this->leftPMZ->setLastChunkSize( jj, jjL, totalFrames);	
					}
					for( std::size_t ii = 0 ; ii < this->maxLag + 1 ; ++ii, ++jjL ) {
						this->leftPMZ->appendFrameToChannel(jj, jjL, c[ii] / div);
						this->leftPMZ->setLastChunkSize( jj, jjL, totalFrames);	
					}
				}		
			}
			
			CrossCorrelation::CrossCorrelation (const string nameArg, shared_ptr<IHCProc > upperProcPtr, double wSizeSec, double hSizeSec, double maxDelaySec, windowType wname )
			: WindowBasedLAGProcs (nameArg, upperProcPtr, _crosscorrelation, this->getNLags( maxDelaySec, upperProcPtr->getFsOut() ), wSizeSec, hSizeSec, wname ) {
				this->maxDelaySec = maxDelaySec;
				
				this->prepareForProcessing();
			}

			CrossCorrelation::~CrossCorrelation () {
				
			}
			
			void CrossCorrelation::processChunk () {	

				this->setNFR ( this->upperProcPtr->getNFR() );

				// Append provided input to the buffer
				this->buffer_l->appendChunk( this->upperProcPtr->getLeftLastChunkAccessor() );
				this->buffer_r->appendChunk( this->upperProcPtr->getRightLastChunkAccessor() );

				/* The buffer should be linearized for windowing. */
				this->buffer_l->linearizeBuffer();
				this->buffer_r->linearizeBuffer();

				vector<shared_ptr<twoCTypeBlock<double> > > l_innerBuffer = buffer_l->getWholeBufferAccesor();
				vector<shared_ptr<twoCTypeBlock<double> > > r_innerBuffer = buffer_r->getWholeBufferAccesor();

				// Quick control of dimensionality
				assert( l_innerBuffer.size() == r_innerBuffer.size() );

				size_t totalFrames = floor( ( this->buffer_l->getSize() - ( this->wSize - this->hSize ) ) / this->hSize );

				for ( std::size_t jj = 0 ; jj < this->get_nChannel() ; ++jj ) {
					this->process( totalFrames, jj, l_innerBuffer[jj]->array1.first, r_innerBuffer[jj]->array1.first );
				}
				
/*				vector<thread> threads;
				for ( size_t jj = 0 ; jj < this->get_nChannel() ; ++jj )
					threads.push_back(thread( &CrossCorrelation::process, this, totalFrames, jj, l_innerBuffer[jj]->array1.first, r_innerBuffer[jj]->array1.first ));
					
				// Waiting to join the threads
				for (auto& t : threads)
					t.join();								
*/				
				this->buffer_l->pop_chunk( totalFrames * this->hSize );
				this->buffer_r->pop_chunk( totalFrames * this->hSize );

			}
			
			// getters
			const double CrossCorrelation::get_cc_maxDelaySec() {return this->maxDelaySec;}
			const double *CrossCorrelation::get_cc_lags() {return this->lags.data();}
			const size_t CrossCorrelation::get_cc_lags_size() {return this->lags.size();}
  
			// setters			
			void CrossCorrelation::set_cc_maxDelaySec(const double arg) {this->maxDelaySec=arg; this->prepareForProcessing ();}
