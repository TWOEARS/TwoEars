#include "GammatoneFilter.hpp"

using namespace openAFE;

		GammatoneFilter::GammatoneFilter( double cf, double fs, uint32_t n, double bwERB ) : GenericFilter<double, std::complex<double>, double, std::complex<double> > ( ) {

			/*
             *         cf : center frequency of the filter (Hz)
             *         fs : sampling frequency (Hz)
             *          n : Gammatone rising slope order (default, n=4)
             *         bw : Bandwidth of the filter in ERBS 
             *              (default: bw = 1.018 ERBS)
			*/
				
            // One ERB value in Hz at this center frequency
			// double ERBHz = freq2erb ( cf );
            double ERBHz = 24.7 + 0.108 * cf;

            // Bandwidth of the filter in Hertz
            double bwHz = bwERB * ERBHz;

            // Generate an IIR Gammatone filter
            double btmp = 1 - exp( -2*M_PI*bwHz/fs );
                        
            std::vector<std::complex<double> > atmp(2,1);
            std::complex<double> tmp ( -2*M_PI*bwHz/fs, -2*M_PI*cf/fs);
			atmp[1] = -exp ( tmp );
            
            std::vector<double> b(1,1);
            std::vector<std::complex<double> > a(1,1);

			for ( size_t ii = 0 ; ii < n ; ++ii ) {
				b = conv( &btmp, 1, b.data(), b.size() );	
				a = conv( atmp.data(), atmp.size(), a.data(), a.size() );
			}
	
            // The transfer function is complex-valued
            this->setRealTF ( false );
            
            // Populate filter Object properties
            //   1- Global properties
            try {
				this->setCoeff ( b.data(), b.size(), a.data(), a.size() );
			} catch(std::string const& message) {
			   throw std::string( message );
		    }
			this->reset();
			
			//   2- Specific properties
			this->CenterFrequency = cf;     		
			this->FilterOrder = n;
			this->delay = 0; // delaySpl
			
		}
		
		GammatoneFilter::~GammatoneFilter() {}
		
		const double GammatoneFilter::getCenterFrequency() {
			return this->CenterFrequency;
		}
