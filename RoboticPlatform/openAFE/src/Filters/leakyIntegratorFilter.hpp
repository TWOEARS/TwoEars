#ifndef LEAKYINTEGRATORFILTER_HPP
#define LEAKYINTEGRATORFILTER_HPP

#include <math.h>       /* exp */
#include <vector>

#include "GenericFilter.hpp"

namespace openAFE {

	class leakyIntegratorFilter : public GenericFilter < double, double, double, double > {
		
		private:
		
			double decaySec;		
			
		public:
				
			leakyIntegratorFilter( double fs, double decaySec = 0.008 );
			
			~leakyIntegratorFilter();

	};
};

#endif /* LEAKYINTEGRATORFILTER_HPP */
