#include "ratemap.hpp"

using namespace openAFE;
using namespace std;

			void Ratemap::processFilter ( const size_t ii,
										   const shared_ptr<twoCTypeBlock<double> > leftChannel,
										   const shared_ptr<twoCTypeBlock<double> > rightChannel ) {
				// Filtering
				size_t dim1 = leftChannel->array1.second;
				size_t dim2 = leftChannel->array2.second;
				
				double* firstValue_l; double* firstValue_r;
				double value1, value2;
				if ( dim1 > 0 ) { 		
 					firstValue_l = leftChannel->array1.first;
					firstValue_r = rightChannel->array1.first;
					for ( size_t iii = 0 ; iii < dim1 ; ++iii ) { 
						this->rmFilter_l[ii]->execFrame( firstValue_l + iii, &value1 );
						this->rmFilter_r[ii]->execFrame( firstValue_r + iii, &value2 );
						
						this->buffer_l->appendFrameToChannel( ii, &value1 );
						this->buffer_r->appendFrameToChannel( ii, &value2 );
					}
				}				
				if ( dim2 > 0 ) {
 					firstValue_l = leftChannel->array2.first;
					firstValue_r = rightChannel->array2.first;
					for ( size_t iii = 0 ; iii < dim2 ; ++iii ) {
						this->rmFilter_l[ii]->execFrame( firstValue_l + iii, &value1 );
						this->rmFilter_r[ii]->execFrame( firstValue_r + iii, &value2 );
						
						this->buffer_l->appendFrameToChannel( ii, &value1 );
						this->buffer_r->appendFrameToChannel( ii, &value2 );
					}
				}
				
				this->buffer_l->setLastChunkSize( ii, dim1 + dim2 );
				this->buffer_r->setLastChunkSize( ii, dim1 + dim2 );
				
				this->buffer_l->linearizeOneBuffer( ii );
				this->buffer_r->linearizeOneBuffer( ii );						
			}			


			void Ratemap::processWindow (  const size_t ii, const size_t totalFrames,
										   const shared_ptr<twoCTypeBlock<double> > leftChannel,
										   const shared_ptr<twoCTypeBlock<double> > rightChannel ) {

				double* firstValue_l = leftChannel->array1.first;
				double* firstValue_r = rightChannel->array1.first;
				double value1, value2;
				
				uint32_t n_start;
			    vector<double > tmpWindowLeft( this->wSize ), tmpWindowRight( this->wSize );

				for ( size_t iii = 0 ; iii < totalFrames ; ++iii ) {
					n_start = iii * this->hSize;

					multiplication( this->win.data(), firstValue_l + n_start, this->wSize, tmpWindowLeft.data() );
					multiplication( this->win.data(), firstValue_r + n_start, this->wSize, tmpWindowRight.data() );
					
					switch( this->scailing) {
						
						default:
						case _magnitude:
							value1 = mean( tmpWindowLeft.data(), this->wSize );
							value2 = mean( tmpWindowRight.data(), this->wSize );
							break;	
						case _power:
							value1 = meanSquare( tmpWindowLeft.data(), this->wSize );
							value2 = meanSquare( tmpWindowRight.data(), this->wSize );
							break;
					}
						
					leftPMZ->appendFrameToChannel( ii, &value1 );
					rightPMZ->appendFrameToChannel( ii, &value2 );						
				}
				leftPMZ->setLastChunkSize( ii, totalFrames );
				rightPMZ->setLastChunkSize( ii, totalFrames );
			}
						
			void Ratemap::populateFilters( filterPtrVector& filterVec, size_t numberOfChannels, double fs ) {
							
				filterVec.resize(numberOfChannels);

				for ( size_t ii = 0 ; ii < numberOfChannels ; ++ii )
					filterVec[ii].reset( new leakyIntegratorFilter( fs, this->decaySec ) );
			}
			
			void Ratemap::prepareForProcessing() {
				
				this->populateFilters( rmFilter_l, this->get_nChannels(), this->getFsIn() );
				this->populateFilters( rmFilter_r, this->get_nChannels(), this->getFsIn() );				
			}
			
			Ratemap::Ratemap (const string nameArg, shared_ptr<IHCProc > upperProcPtr, double wSizeSec, double hSizeSec, scalingType scailingArg, double decaySec, windowType wname  )
			: WindowBasedProcs (nameArg, upperProcPtr, _ratemap, wSizeSec, hSizeSec, wname, scailingArg ) {
				
				this->decaySec = decaySec;
				this->scailing = scailingArg;
				
				this->prepareForProcessing();
			}

			Ratemap::~Ratemap () {
				
			}
			
			void Ratemap::processChunk () {	

				this->setNFR ( this->upperProcPtr->getNFR() );

				vector<shared_ptr<twoCTypeBlock<double> > > inputLeft = this->upperProcPtr->getLeftLastChunkAccessor();
				vector<shared_ptr<twoCTypeBlock<double> > > inputRight = this->upperProcPtr->getRightLastChunkAccessor();
								
				size_t ii;		
				vector<thread> threads;
				for ( ii = 0 ; ii < this->fb_nChannels ; ++ii )
					threads.push_back(thread( &Ratemap::processFilter, this, ii, inputLeft[ii],
																				 inputRight[ii] ));
				// Waiting to join the threads
				for (auto& t : threads)
					t.join();	

				vector<shared_ptr<twoCTypeBlock<double> > > l_innerBuffer = this->buffer_l->getWholeBufferAccesor( );
				vector<shared_ptr<twoCTypeBlock<double> > > r_innerBuffer = this->buffer_r->getWholeBufferAccesor( );
				
				size_t totalFrames = floor( ( this->buffer_l->getSize() - ( this->wSize - this->hSize ) ) / this->hSize );

				for ( ii = 0 ; ii < this->fb_nChannels ; ++ii )
					this->processWindow( ii, totalFrames, l_innerBuffer[ii], r_innerBuffer[ii] );	
					
				this->buffer_l->pop_chunk( totalFrames * this->hSize );
				this->buffer_r->pop_chunk( totalFrames * this->hSize );	
			}
			
			// getters
			const double Ratemap::get_rm_decaySec() {return this->decaySec;}
			const scalingType Ratemap::get_rm_scailing() {return this->scailing;}
  
			// setters			
			void Ratemap::set_rm_decaySec(const double arg) {this->decaySec=arg; this->prepareForProcessing ();}
			void Ratemap::set_rm_scailing(const scalingType arg) {this->scailing=arg; this->prepareForProcessing ();}
