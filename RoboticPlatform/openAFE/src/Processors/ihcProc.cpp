#include "ihcProc.hpp"

#include <numeric>
#include <chrono>

using namespace openAFE;
using namespace std;

			void IHCProc::populateFilters( filterPtrVector& filters ) {

				 filters.resize( this->get_nChannel() );

                 switch ( this->method ) {

                     case _joergensen:
                         // First order butterworth filter @ 150Hz
						 for ( size_t ii = 0 ; ii < this->get_nChannel() ; ++ii )
							filters[ii].reset(new bwFilter( this->getFsIn(), 1, 150, _bwlp ) );
                         break;

                     case _dau:
                         // Second order butterworth filter @ 1000Hz
						 for ( size_t ii = 0 ; ii < this->get_nChannel() ; ++ii )
							filters[ii].reset(new bwFilter( this->getFsIn(), 2, 1000, _bwlp ) );						 
                         break;

                     case _breebart:
                         // First order butterworth filter @ 2000Hz cascaded 5 times
						 for ( size_t ii = 0 ; ii < this->get_nChannel() ; ++ii ) {
							 // TODO : implement THIS
						 }
                         break;

                     case _bernstein:
                         // Second order butterworth filter @ 425Hz
						 for ( size_t ii = 0 ; ii < this->get_nChannel() ; ++ii ) {
							filters[ii].reset(new bwFilter( this->getFsIn(), 2, 425, _bwlp ) );
						 }
                         break;

                     default:
                         this->ihcFilter_l.clear();
                         this->ihcFilter_r.clear();
                         break;

				}	

			}

			void IHCProc::processNone  ( const size_t ii, const shared_ptr<twoCTypeBlock<double> > leftChannel, 
														  const shared_ptr<twoCTypeBlock<double> > rightChannel ) {
															
				// 0- Initialization
				size_t dim1 = leftChannel->array1.second;
				size_t dim2 = leftChannel->array2.second;
						
				if ( dim1 > 0 ) { 		
 					double* firstValue_l = leftChannel->array1.first;
					double* firstValue_r = rightChannel->array1.first;
					for ( size_t iii = 0 ; iii < dim1 ; ++iii ) {
						leftPMZ->appendFrameToChannel( ii, ( firstValue_l + iii ) );
						rightPMZ->appendFrameToChannel( ii, ( firstValue_r + iii ) );
					}
				}				
				if ( dim2 > 0 ) {
 					double* firstValue_l = leftChannel->array2.first;
					double* firstValue_r = rightChannel->array2.first;
					for ( size_t iii = 0 ; iii < dim2 ; ++iii ) {
						leftPMZ->appendFrameToChannel( ii, ( firstValue_l + iii ) );
						rightPMZ->appendFrameToChannel( ii, ( firstValue_r + iii ) );
					}
				}
				
				leftPMZ->setLastChunkSize( ii, dim1 + dim2 );
				rightPMZ->setLastChunkSize( ii, dim1 + dim2 );				
			}
		
			void IHCProc::processHalfWave  ( const size_t ii, const shared_ptr<twoCTypeBlock<double> > leftChannel, 
														const shared_ptr<twoCTypeBlock<double> > rightChannel ) {
															
				// 0- Initialization
				size_t dim1 = leftChannel->array1.second;
				size_t dim2 = leftChannel->array2.second;
						
				double value1, value2;
				if ( dim1 > 0 ) { 		
 					double* firstValue_l = leftChannel->array1.first;
					double* firstValue_r = rightChannel->array1.first;
					for ( size_t iii = 0 ; iii < dim1 ; ++iii ) {			
						value1 = fmax( *( firstValue_l + iii ), 0 );
						value2 = fmax( *( firstValue_r + iii ), 0 );
						
						leftPMZ->appendFrameToChannel( ii, &value1 );
						rightPMZ->appendFrameToChannel( ii, &value2 );						
					}
				}				
				if ( dim2 > 0 ) {
 					double* firstValue_l = leftChannel->array2.first;
					double* firstValue_r = rightChannel->array2.first;
					for ( size_t iii = 0 ; iii < dim2 ; ++iii ) {
						value1 = fmax( *( firstValue_l + iii ), 0 );
						value2 = fmax( *( firstValue_r + iii ), 0 );
						
						leftPMZ->appendFrameToChannel( ii, &value1 );
						rightPMZ->appendFrameToChannel( ii, &value2 );	
					}
				}
				
				leftPMZ->setLastChunkSize( ii, dim1 + dim2 );
				rightPMZ->setLastChunkSize( ii, dim1 + dim2 );				
			}
						
			void IHCProc::processFullWave  ( const size_t ii, const shared_ptr<twoCTypeBlock<double> > leftChannel, 
														const shared_ptr<twoCTypeBlock<double> > rightChannel ) {
															
				// 0- Initialization
				size_t dim1 = leftChannel->array1.second;
				size_t dim2 = leftChannel->array2.second;
						
				double value1, value2;
				if ( dim1 > 0 ) { 		
 					double* firstValue_l = leftChannel->array1.first;
					double* firstValue_r = rightChannel->array1.first;
					for ( size_t iii = 0 ; iii < dim1 ; ++iii ) {
						value1 = fabs( *( firstValue_l + iii ) );
						value2 = fabs( *( firstValue_r + iii ) );
						
						leftPMZ->appendFrameToChannel( ii, &value1 );
						rightPMZ->appendFrameToChannel( ii, &value2 );
					}
				}				
				if ( dim2 > 0 ) {
 					double* firstValue_l = leftChannel->array2.first;
					double* firstValue_r = rightChannel->array2.first;
					for ( size_t iii = 0 ; iii < dim2 ; ++iii ) {
						value1 = fabs( *( firstValue_l + iii ) );
						value2 = fabs( *( firstValue_r + iii ) );
						
						leftPMZ->appendFrameToChannel( ii, &value1 );
						rightPMZ->appendFrameToChannel( ii, &value2 );
					}
				}
				
				leftPMZ->setLastChunkSize( ii, dim1 + dim2 );
				rightPMZ->setLastChunkSize( ii, dim1 + dim2 );				
			}

			void IHCProc::processSquare  ( const size_t ii, const shared_ptr<twoCTypeBlock<double> > leftChannel, 
														const shared_ptr<twoCTypeBlock<double> > rightChannel ) {
															
				// 0- Initialization
				size_t dim1 = leftChannel->array1.second;
				size_t dim2 = leftChannel->array2.second;
						
				double value1, value2;
				if ( dim1 > 0 ) { 		
 					double* firstValue_l = leftChannel->array1.first;
					double* firstValue_r = rightChannel->array1.first;
					for ( size_t iii = 0 ; iii < dim1 ; ++iii ) {
						value1 = pow( fabs( *( firstValue_l + iii ) ), 2 );
						value2 = pow( fabs( *( firstValue_r + iii ) ), 2 );
						
						leftPMZ->appendFrameToChannel( ii, &value1 );
						rightPMZ->appendFrameToChannel( ii, &value2 );
					}
				}				
				if ( dim2 > 0 ) {
 					double* firstValue_l = leftChannel->array2.first;
					double* firstValue_r = rightChannel->array2.first;
					for ( size_t iii = 0 ; iii < dim2 ; ++iii ) {
						value1 = pow( fabs( *( firstValue_l + iii ) ), 2 );
						value2 = pow( fabs( *( firstValue_r + iii ) ), 2 );
						
						leftPMZ->appendFrameToChannel( ii, &value1 );
						rightPMZ->appendFrameToChannel( ii, &value2 );
					}
				}
				
				leftPMZ->setLastChunkSize( ii, dim1 + dim2 );
				rightPMZ->setLastChunkSize( ii, dim1 + dim2 );				
			}
			
			void IHCProc::processDAU ( const size_t ii, const shared_ptr<twoCTypeBlock<double> > leftChannel, 
														const shared_ptr<twoCTypeBlock<double> > rightChannel, 
														bwFilterPtr filter_l,
														bwFilterPtr filter_r ) {
															
				// 0- Initialization
				size_t dim1 = leftChannel->array1.second;
				size_t dim2 = leftChannel->array2.second;
						
				// DAU = Halfwave rectification + BW filtering
				double value1, value2;
				if ( dim1 > 0 ) { 		
 					double* firstValue_l = leftChannel->array1.first;
					double* firstValue_r = rightChannel->array1.first;
					for ( size_t iii = 0 ; iii < dim1 ; ++iii ) {
						value1 = fmax( *( firstValue_l + iii ), 0 ); 
						value2 = fmax( *( firstValue_r + iii ), 0 ); 

						filter_l->execFrame( &value1, &value1 );
						filter_r->execFrame( &value2, &value2 );
						
						leftPMZ->appendFrameToChannel( ii, &value1 );
						rightPMZ->appendFrameToChannel( ii, &value2 );
					}
				}				
				if ( dim2 > 0 ) {
 					double* firstValue_l = leftChannel->array2.first;
					double* firstValue_r = rightChannel->array2.first;
					for ( size_t iii = 0 ; iii < dim2 ; ++iii ) {
						value1 = fmax( *( firstValue_l + iii ), 0 ); 
						value2 = fmax( *( firstValue_r + iii ), 0 ); 

						filter_l->execFrame( &value1, &value1 );
						filter_r->execFrame( &value2, &value2 );
						
						leftPMZ->appendFrameToChannel( ii, &value1 );
						rightPMZ->appendFrameToChannel( ii, &value2 );
					}
				}
				
				leftPMZ->setLastChunkSize( ii, dim1 + dim2 );
				rightPMZ->setLastChunkSize( ii, dim1 + dim2 );				
			}

			void IHCProc::processChannel ( const size_t ii,
									       const shared_ptr<twoCTypeBlock<double> > leftChannel,
									       const shared_ptr<twoCTypeBlock<double> > rightChannel ) {
										  				
					  switch ( this->method ) {
						  case _joergensen: // Not implemented yet
						  case _breebart: // Not implemented yet
						  case _bernstein: // Not implemented yet
						  case _none:
							this->processNone( ii, leftChannel, rightChannel );
							break;
						  case _halfwave:
							this->processHalfWave( ii, leftChannel, rightChannel );
							break;
						  case _fullwave:
							this->processFullWave( ii, leftChannel, rightChannel );
							break;
					      case _square:
							this->processSquare( ii, leftChannel, rightChannel );
							break;						  
						  case _dau:
							this->processDAU( ii, leftChannel, rightChannel, this->ihcFilter_l[ii], this->ihcFilter_r[ii] );
							break;
						  default :
							break;
					  }
			}
																
			IHCProc::IHCProc (const std::string nameArg, std::shared_ptr<GammatoneProc > upperProcPtr, ihcMethod method ) : TFSProcessor<double > (nameArg, upperProcPtr->getFsOut(), upperProcPtr->getFsOut(), upperProcPtr->getBufferSize_s(), upperProcPtr->get_nChannel(), _magnitude, _ihc) {
					
				this->upperProcPtr = upperProcPtr;
				this->method = method;
				this->prepareForProcessing();																							 
			}
			
			IHCProc::~IHCProc () {
				
				this->ihcFilter_l.clear();
				this->ihcFilter_r.clear();
			}
			
			void IHCProc::prepareForProcessing() {
				this->populateFilters( this->ihcFilter_l );
				this->populateFilters( this->ihcFilter_r );
			}
			
			void IHCProc::processChunk ( ) {
				this->setNFR ( this->upperProcPtr->getNFR() );

				vector<shared_ptr<twoCTypeBlock<double> > > leftInput = this->upperProcPtr->getLeftLastChunkAccessor();
				vector<shared_ptr<twoCTypeBlock<double> > > rightInput = this->upperProcPtr->getRightLastChunkAccessor();
				
				vector<thread> threads;
				for ( size_t ii = 0 ; ii < this->get_nChannel() ; ++ii )
					threads.push_back(thread( &IHCProc::processChannel, this, ii, leftInput[ii], rightInput[ii] ));
					
				// Waiting to join the threads
				for (auto& t : threads)
					t.join();
			}
			
			/* Comapres informations and the current parameters of two processors */
			bool IHCProc::operator==( IHCProc& toCompare ) {
				if ( this->compareBase( toCompare ) )
					if ( this->get_ihc_method() == toCompare.get_ihc_method() )				     		     			     
						return true;
				return false;
			}

			// getters
			const ihcMethod IHCProc::get_ihc_method() {return this->method;}
			
			// setters
			void IHCProc::set_ihc_method(const ihcMethod arg) {this->method=arg; this->prepareForProcessing ();}

			std::string IHCProc::get_upperProcName() {return this->upperProcPtr->getName();}
