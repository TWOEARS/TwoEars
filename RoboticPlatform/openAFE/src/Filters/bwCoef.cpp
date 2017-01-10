#include "bwCoef.hpp"

	
	double openAFE::bwCoef(unsigned int n, double fs, double f1f, std::vector<double>& vectDcof, std::vector<double>& vectCcof, bwType type,  double f2f) {

		// int n;           - filter order
		// int sff		-  scale flag: 1 to scale, 0 to not scale ccof
		unsigned int i;            	// loop variables
		// double fcf	-     cutoff frequency (fraction of pi)
		double sf = 0;        	// scaling factor
		double *dcof = NULL;     	// d coefficients
		int *ccof  = NULL;        	// c coefficients
		double *ccofD = NULL;      // c coefficients

		f1f = f1f / ( 0.5 * fs );
		f2f = f2f / ( 0.5 * fs );

		/* calculate the coefficients */
		switch (type) {
		case 0:
		  dcof = dcof_bwlp( n, f1f );	/* calculate the d coefficients */
		  ccof = ccof_bwlp( n );	/* calculate the c coefficients */
		  sf = sf_bwlp( n, f1f );	/* scaling factor for the c coefficients */
		  break;

		case 1:
		  dcof = dcof_bwhp( n, f1f );
		  ccof = ccof_bwhp( n );	
		  sf = sf_bwhp( n, f1f );
		  break;

		case 2:
		  dcof = dcof_bwbp( n, f1f, f2f );
		  ccof = ccof_bwbp( n );
		  sf = sf_bwbp( n, f1f, f2f );
		  break;

		case 3:
		  dcof = dcof_bwbs( n, f1f, f2f );
		  ccofD = ccof_bwbs( n, f1f, f2f );
		  sf = sf_bwbs( n, f1f, f2f ); 
		  break;

		default:
		  break;
		}

		if( (dcof == NULL) or ( (ccof == NULL) and (ccofD == NULL) ) ) {
			perror( "Unable to calculate coefficients" );
			return(-1);
		}

		/* Output the c coefficients */
		if (type == _bwbs) {
		for( i = 0; i <= n; ++i)
			 vectCcof[i] = ccofD[i]*sf;
		} else {
		for( i = 0; i <= n; ++i)
			vectCcof[i] = (double)ccof[i]*sf;
		}

		/* Output the d coefficients */
		for( i = 0; i <= n; ++i )
		vectDcof[i] = dcof[i];

		return sf;

	}

