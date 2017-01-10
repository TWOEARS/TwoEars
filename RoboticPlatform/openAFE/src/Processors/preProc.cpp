#include "preProc.hpp"

#define EPSILON_PP 1E-8

using namespace openAFE;
using namespace std;
	
            void PreProc::verifyParameters() {
				
				/* TODO : Follow Matlab AFE to update this function
				 * Nothing at : 17.02.2016
				 */
				
			}
						
			// Actual Processing
			void PreProc::process ( size_t dim1, double* firstValue1, size_t dim2, double* firstValue2, shared_ptr <TimeDomainSignal<double> > PMZ ,
																										bwFilterPtr dcFilter,
																										genericFilterPtr preEmphFilter,
																										genericFilterPtr agcFilter,
																										double* tmp ) {
				double value;
				double dbVar = pow( 10 , ( 100 /* current_dboffset : dbspl(1) = 100 */ - this->pp_refSPLdB ) / 20 );
				
				for ( uint32_t i = 0 ; i < dim1 ; ++i ) {
					// 1- DC Filter
					if ( this->pp_bRemoveDC ) {
						dcFilter->execFrame( firstValue1 + i, &value );
					} else value = * ( firstValue1 + i );
					
					// 2- Pre-whitening
					if ( this->pp_bPreEmphasis )
						preEmphFilter->execFrame( &value, &value );

					// 3- Automatic gain control (part 1)	
					if ( this->pp_bNormalizeRMS ) {
						*( tmp + i ) = pow( value, 2 );
						agcFilter->execFrame( tmp + i, tmp + i );
						*( tmp + i ) = sqrt( *( tmp + i ) ) + EPSILON_PP;
					}

					// 4- Level Scaling
					if ( this->pp_bLevelScaling ) {
						value *= dbVar;
					}

					// TODO : 5- Middle Ear Filtering
					// if ( this->pp_bMiddleEarFiltering ) {}	

					PMZ->appendFrame( &value );
				}						
				for ( uint32_t i = 0 ; i < dim2 ; ++i ) {
					// 1- DC Filter					
					if ( this->pp_bRemoveDC ) {
						dcFilter->execFrame( firstValue2 + i, &value );
					} else value = * ( firstValue2 + i );
					
					// 2- Pre-whitening					
					if ( this->pp_bPreEmphasis )
						preEmphFilter->execFrame( &value, &value );	

					// 3- Automatic gain control (part 1)	
					if ( this->pp_bNormalizeRMS ) {
						*( tmp + i + dim1 ) = pow( value, 2 );
						agcFilter->execFrame( tmp + i + dim1, tmp + i + dim1 );
						*( tmp + i + dim1 ) = sqrt( *( tmp + i + dim1 ) ) + EPSILON_PP;
					}

					// 4- Level Scaling
					if ( this->pp_bLevelScaling ) {
						value *= dbVar;
					}

					// TODO : 5- Middle Ear Filtering
					//if ( this->pp_bMiddleEarFiltering ) {}	

					PMZ->appendFrame( &value );
				}						
						
				PMZ->setLastChunkSize( dim1 + dim2 );
			}

			/* PreProc */
			PreProc::PreProc (const std::string nameArg, std::shared_ptr<InputProc > upperProcPtr, bool pp_bRemoveDC,
																						  double pp_cutoffHzDC,
																						  bool pp_bPreEmphasis,
																						  double pp_coefPreEmphasis,
																						  bool pp_bNormalizeRMS,
																						  double pp_intTimeSecRMS,
																						  bool pp_bLevelScaling,
																						  double pp_refSPLdB,
																						  bool pp_bMiddleEarFiltering,
																						  middleEarModel pp_middleEarModel,
																						  bool pp_bUnityComp
					) : TDSProcessor<double> (nameArg, upperProcPtr->getFsOut(), upperProcPtr->getFsOut(), upperProcPtr->getBufferSize_s(), _inputProc) {

				this->pp_bRemoveDC = pp_bRemoveDC;
				this->pp_cutoffHzDC = pp_cutoffHzDC;
				this->pp_bPreEmphasis = pp_bPreEmphasis;
				this->pp_coefPreEmphasis =  pp_coefPreEmphasis;
				this->pp_bNormalizeRMS = pp_bNormalizeRMS;
				this->pp_intTimeSecRMS = pp_intTimeSecRMS;
				this->pp_bLevelScaling = pp_bLevelScaling;
				this->pp_refSPLdB = pp_refSPLdB;
				this->pp_bMiddleEarFiltering = pp_bMiddleEarFiltering;
				this->pp_middleEarModel = pp_middleEarModel;
				this->pp_bUnityComp = pp_bUnityComp;

				this->upperProcPtr = upperProcPtr;
				
				this->verifyParameters();
				this->prepareForProcessing ();
			}
				
			PreProc::~PreProc () {
				this->dcFilter_l.reset();
				this->dcFilter_r.reset();				
				
				this->preEmphFilter_l.reset();
				this->preEmphFilter_r.reset();
			
				this->agcFilter_l.reset();
				this->agcFilter_r.reset();

				this->midEarFilter_l.reset();
				this->midEarFilter_r.reset();
			}
			
			void PreProc::processChunk () {
	
				this->setNFR ( upperProcPtr->getNFR() ); /* for rosAFE */

				shared_ptr<twoCTypeBlock<double> > leftInput = this->upperProcPtr->getLeftLastChunkAccessor();
				shared_ptr<twoCTypeBlock<double> > rightInput = this->upperProcPtr->getRightLastChunkAccessor();
					
				size_t dim1 = leftInput->array1.second;
				size_t dim2 = leftInput->array2.second;

				double* firstValue1_l = leftInput->array1.first;
				double* firstValue2_l = leftInput->array2.first;
				double* firstValue1_r = rightInput->array1.first;
				double* firstValue2_r = rightInput->array2.first;		

				if ( this->pp_bUnityComp ) {
						
					switch ( this->pp_middleEarModel ) {
						case _jepsen:
							this->meFilterPeakdB = 55.9986;
							break;
						case _lopezpoveda:
							this->meFilterPeakdB = 66.2888;
							break;
						default:
				 			this->meFilterPeakdB = 0;
							break;
					}
				} else this->meFilterPeakdB = 0;

				vector<double> tmp_l, tmp_r;
				// 3- Initialize the filter states if empty  (part init)
				if ( this->pp_bNormalizeRMS ) {
					tmp_l.resize( dim1 + dim2 ); tmp_r.resize( dim1 + dim2 );

					if ( !( agcFilter_l->isInitialized() ) ) {
						double intArg = this->pp_intTimeSecRMS * this->getFsIn();
						double sum_l = 0, sum_r = 0, s0_l, s0_r;
						uint32_t minVal;

						// TODO : this should be compared with dim1 + dim2, however this doesnt occur a functional problem as dim2 is very likely to be 0 at this stage
						minVal = fmin ( dim1, round( intArg ) ); 
						
						// Mean square of input over the time constant
						for ( unsigned int i = 0 ; i < minVal ; ++i ) {
							sum_l += pow( *(firstValue1_l + i ) , 2);
							sum_r += pow( *(firstValue1_r + i ) , 2);
						}
									
						// Initial filter states
						s0_l = exp ( -1 / intArg ) * ( sum_l / minVal );							
						s0_r = exp ( -1 / intArg ) * ( sum_r / minVal );
								
						this->agcFilter_l->reset( &s0_l, 1 );
						this->agcFilter_r->reset( &s0_r, 1 );
					}
				}
										
				thread leftThread( &PreProc::process, this, dim1, firstValue1_l, dim2, firstValue2_l, this->leftPMZ, this->dcFilter_l, this->preEmphFilter_l, this->agcFilter_l, tmp_l.data() );
				thread rightThread( &PreProc::process, this, dim1, firstValue1_r, dim2, firstValue2_r, this->rightPMZ, this->dcFilter_r, this->preEmphFilter_r, this->agcFilter_r, tmp_r.data() );
						
				leftThread.join();                // pauses until left finishes
				rightThread.join();               // pauses until right finishes
				
				// 3- Automatic gain control (part 2)
				if ( this->pp_bNormalizeRMS ) {

					leftInput = this->leftPMZ->getLastChunkAccesor();
					rightInput = this->rightPMZ->getLastChunkAccesor();

					firstValue1_l = leftInput->array1.first;
					firstValue2_l = leftInput->array2.first;
					firstValue1_r = rightInput->array1.first;
					firstValue2_r = rightInput->array2.first;	
									
					dim1 = leftInput->array1.second;
					dim2 = leftInput->array2.second;
																
					for ( uint32_t i = 0 ; i < tmp_l.size() ; ++i ) {
						tmp_l[ i ]  = fmax ( tmp_l[ i ], tmp_r[ i ] );
						if ( i < dim1 )	{
							*(firstValue1_l + i ) /= tmp_l[ i ];
							*(firstValue1_r + i ) /= tmp_l[ i ];
						} else {
							*(firstValue2_l + i ) /= tmp_l[ i ];
							*(firstValue2_r + i ) /= tmp_l[ i ];
							} 
						}							
					}
			}
			
			void PreProc::prepareForProcessing () {

				// Filter instantiation (if needed)	
				if ( this->pp_bRemoveDC ) {
					
					this->dcFilter_l.reset ( new bwFilter ( this->getFsIn(), 4 /* order */, this->pp_cutoffHzDC, (bwType)1 /* High */ ) );
					this->dcFilter_r.reset ( new bwFilter ( this->getFsIn(), 4 /* order */, this->pp_cutoffHzDC, (bwType)1 /* High */ ) );
					
				} else {
					// Deleting the filter objects
					this->dcFilter_l.reset();
					this->dcFilter_r.reset();
				}

				if ( this->pp_bPreEmphasis ) {
					
					vector<double> vectB (2,1);
					vectB[1] = -1 * fabs( this->pp_coefPreEmphasis );
					vector<double> vectA (1,1);
					
					this->preEmphFilter_l.reset ( new GenericFilter<double,double, double, double> ( vectB.data(), vectB.size(), vectA.data(), vectA.size() ) );
					this->preEmphFilter_r.reset ( new GenericFilter<double,double, double, double> ( vectB.data(), vectB.size(), vectA.data(), vectA.size() ) );
					
				} else {
					
					// Deleting the filter objects
					this->preEmphFilter_l.reset();
					this->preEmphFilter_r.reset();
				}
				
				if ( this->pp_bNormalizeRMS ) {

					vector<double> vectB (1,1);
					vector<double> vectA (2,1);
					
					vectA[1] = -1 * exp( -1 / ( this->pp_intTimeSecRMS * this->getFsIn() ) );
					vectB[0] = vectA[0] + vectA[1];

					this->agcFilter_l.reset ( new GenericFilter<double,double, double, double> ( vectB.data(), vectB.size(), vectA.data(), vectA.size() ) );
					this->agcFilter_r.reset ( new GenericFilter<double,double, double, double> ( vectB.data(), vectB.size(), vectA.data(), vectA.size() ) );
					
				} else {
					
					// Deleting the filter objects
					this->agcFilter_l.reset();
					this->agcFilter_r.reset();
				}

				if ( this->pp_bMiddleEarFiltering ) {

					 //this->midEarFilter_l.reset ( new GenericFilter<double,double, double, double> ( vectB.data(), vectB.size(), vectA.data(), vectA.size() ) );
					 //this->midEarFilter_r.reset ( new GenericFilter<double,double, double, double> ( vectB.data(), vectB.size(), vectA.data(), vectA.size() ) );
					
				} else {
					
					// Deleting the filter objects
					this->midEarFilter_l.reset();
					this->midEarFilter_r.reset();
				}			
			}

			/* Comapres informations and the current parameters of two processors */
			bool PreProc::operator==( PreProc& toCompare ) {
				if ( this->compareBase( toCompare ) )
					if ( ( this->get_pp_bRemoveDC() == toCompare.get_pp_bRemoveDC() ) and
					     ( this->get_pp_cutoffHzDC() == toCompare.get_pp_cutoffHzDC() ) and
					     ( this->get_pp_bPreEmphasis() == toCompare.get_pp_bPreEmphasis() ) and	
					     ( this->get_pp_bNormalizeRMS() == toCompare.get_pp_bNormalizeRMS() ) and	     
					     ( this->get_pp_intTimeSecRMS() == toCompare.get_pp_intTimeSecRMS() ) and
					     ( this->get_pp_bLevelScaling() == toCompare.get_pp_bLevelScaling() ) and	
					     ( this->get_pp_refSPLdB() == toCompare.get_pp_refSPLdB() ) and
					     ( this->get_pp_bMiddleEarFiltering() == toCompare.get_pp_bMiddleEarFiltering() ) and
					     ( this->get_pp_middleEarModel() == toCompare.get_pp_middleEarModel() ) and	
					     ( this->get_pp_bUnityComp() == toCompare.get_pp_bUnityComp() ) )					     		     			     
						return true;
				return false;
			}

			// getters
			bool PreProc::get_pp_bRemoveDC() {return this->pp_bRemoveDC;}
			double PreProc::get_pp_cutoffHzDC() {return this->pp_cutoffHzDC;}
			bool PreProc::get_pp_bPreEmphasis() {return this->pp_bPreEmphasis;}
			double PreProc::get_pp_coefPreEmphasis() {return this->pp_coefPreEmphasis;}
			bool PreProc::get_pp_bNormalizeRMS() {return this->pp_bNormalizeRMS;}
			double PreProc::get_pp_intTimeSecRMS() {return this->pp_intTimeSecRMS;}
			bool PreProc::get_pp_bLevelScaling() {return this->pp_bLevelScaling;}
			double PreProc::get_pp_refSPLdB() {return this->pp_refSPLdB;}
			bool PreProc::get_pp_bMiddleEarFiltering() {return this->pp_bMiddleEarFiltering;}
			middleEarModel PreProc::get_pp_middleEarModel() {return this->pp_middleEarModel;}
			bool PreProc::get_pp_bUnityComp() {return this->pp_bUnityComp;}

			// setters			
			void PreProc::set_pp_bRemoveDC(const bool arg) {this->pp_bRemoveDC=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_cutoffHzDC(const double arg) {this->pp_cutoffHzDC=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_bPreEmphasis(const bool arg) {this->pp_bPreEmphasis=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_coefPreEmphasis(const double arg) {this->pp_coefPreEmphasis = arg; this->prepareForProcessing ();}
			void PreProc::set_pp_bNormalizeRMS(const bool arg) {this->pp_bNormalizeRMS=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_intTimeSecRMS(const double arg) {this->pp_intTimeSecRMS=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_bLevelScaling(const bool arg) {this->pp_bLevelScaling=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_refSPLdB(const double arg) {this->pp_refSPLdB=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_bMiddleEarFiltering(const bool arg) {this->pp_bMiddleEarFiltering=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_middleEarModel(const middleEarModel arg) {this->pp_middleEarModel=arg; this->prepareForProcessing ();}
			void PreProc::set_pp_bUnityComp(const bool arg) {this->pp_bUnityComp=arg; this->prepareForProcessing ();}			

			std::string PreProc::get_upperProcName() {return this->upperProcPtr->getName();}

