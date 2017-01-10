#ifndef BWFILTER_HPP
#define BWFILTER_HPP

#include <stdlib.h>
#include <string.h>
#include <math.h>

#include <vector>
#include <assert.h>

#include "CascadeFilters.hpp"
#include "bwCoef.hpp"

namespace openAFE {

	class bwFilter : public GenericFilter < double, double, double, double > {
				
		public:
				
			bwFilter(double fs, uint32_t argOrder = 2, double f1 = 1000, bwType type = _bwlp, double f2 = 0);
			
			~bwFilter();
			
	};
};

#endif /* BWFILTER_HPP */
