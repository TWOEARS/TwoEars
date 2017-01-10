#ifndef GAMMATONEFILTER_HPP
#define GAMMATONEFILTER_HPP

#include <stdint.h>
#include <complex>

#include "GenericFilter.hpp"
#include "../tools/mathTools.hpp"

namespace openAFE {

	class GammatoneFilter : public GenericFilter<double, std::complex<double>, double, std::complex<double> > {
	
	private:
	
        double CenterFrequency;     		// Center frequency for the filter (Hz)
        uint32_t FilterOrder;         	// Gammatone slope order
        double IRduration;         		// Duration of the impulse response for truncation (s)
        double delay;               		// Delay in samples for time alignment	
		
	public:
		
		GammatoneFilter( double cf, double fs, uint32_t n = 4, double bwERB = 1.018 );
		
		~GammatoneFilter();
		
		const double getCenterFrequency();

	};
};

#endif /* GAMMATONEFILTER_HPP */
