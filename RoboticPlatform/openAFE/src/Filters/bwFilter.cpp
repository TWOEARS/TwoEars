#include "bwFilter.hpp"

		openAFE::bwFilter::bwFilter(double fs, uint32_t argOrder, double f1, openAFE::bwType type, double f2) : GenericFilter < double, double, double, double > ( ) {
			
			std::vector<double> vectDcof(argOrder + 1, 0);
			std::vector<double> vectCcof(argOrder + 1, 0);

			bwCoef(argOrder, fs, f1, vectDcof, vectCcof, type, f2);

			this->setCoeff ( vectCcof.data(), vectCcof.size(), vectDcof.data(), vectDcof.size() );				
			
		}
		
		openAFE::bwFilter::~bwFilter() {
			
		}
