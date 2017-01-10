#include "leakyIntegratorFilter.hpp"

using namespace openAFE;

			leakyIntegratorFilter::leakyIntegratorFilter( double fs, double decaySec ) : GenericFilter < double, double, double, double > ( ) {
								
				// Filter decay
				double intDecay = std::exp( -( 1 / (fs * decaySec) ) );

                // Integration gain
                double intGain = 1 - intDecay;				

                std::vector<double> a(2,1);
				a[1] = -intDecay;
				
				this->setCoeff ( &intGain, 1, a.data(), a.size() );
				
				this->decaySec = decaySec;
			}
			
			leakyIntegratorFilter::~leakyIntegratorFilter() {}
