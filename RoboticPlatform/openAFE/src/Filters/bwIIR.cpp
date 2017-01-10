#include "bwIIR.hpp"

	
	double *openAFE::binomial_mult( int n, double *p ) {
		int i, j;
		double *a;

		a = (double *)calloc( 2 * n, sizeof(double) );
		if( a == NULL ) return( NULL );

		for( i = 0; i < n; ++i )
		{
		for( j = i; j > 0; --j )
		{
			a[2*j] += p[2*i] * a[2*(j-1)] - p[2*i+1] * a[2*(j-1)+1];
			a[2*j+1] += p[2*i] * a[2*(j-1)+1] + p[2*i+1] * a[2*(j-1)];
		}
		a[0] += p[2*i];
		a[1] += p[2*i+1];
		}
		return( a );
	}

	double *openAFE::trinomial_mult( int n, double *b, double *c ) {
		int i, j;
		double *a;

		a = (double *)calloc( 4 * n, sizeof(double) );
		if( a == NULL ) return( NULL );

		a[2] = c[0];
		a[3] = c[1];
		a[0] = b[0];
		a[1] = b[1];
	  
		for( i = 1; i < n; ++i )
		{
		a[2*(2*i+1)]   += c[2*i]*a[2*(2*i-1)]   - c[2*i+1]*a[2*(2*i-1)+1];
		a[2*(2*i+1)+1] += c[2*i]*a[2*(2*i-1)+1] + c[2*i+1]*a[2*(2*i-1)];

		for( j = 2*i; j > 1; --j )
		{
			a[2*j]   += b[2*i] * a[2*(j-1)]   - b[2*i+1] * a[2*(j-1)+1] + 
			c[2*i] * a[2*(j-2)]   - c[2*i+1] * a[2*(j-2)+1];
			a[2*j+1] += b[2*i] * a[2*(j-1)+1] + b[2*i+1] * a[2*(j-1)] +
			c[2*i] * a[2*(j-2)+1] + c[2*i+1] * a[2*(j-2)];
		}

		a[2] += b[2*i] * a[0] - b[2*i+1] * a[1] + c[2*i];
		a[3] += b[2*i] * a[1] + b[2*i+1] * a[0] + c[2*i+1];
		a[0] += b[2*i];
		a[1] += b[2*i+1];
		}

		return( a );
	}

	double *openAFE::dcof_bwlp( int n, double fcf ) {
		int k;            // loop variables
		double theta;     // M_PI * fcf / 2.0
		double st;        // sine of theta
		double ct;        // cosine of theta
		double parg;      // pole angle
		double sparg;     // sine of the pole angle
		double cparg;     // cosine of the pole angle
		double a;         // workspace variable
		double *rcof;     // binomial coefficients
		double *dcof;     // dk coefficients

		rcof = (double *)calloc( 2 * n, sizeof(double) );
		if( rcof == NULL ) return( NULL );

		theta = M_PI * fcf;
		st = sin(theta);
		ct = cos(theta);

		for( k = 0; k < n; ++k )
		{
		parg = M_PI * (double)(2*k+1)/(double)(2*n);
		sparg = sin(parg);
		cparg = cos(parg);
		a = 1.0 + st*sparg;
		rcof[2*k] = -ct/a;
		rcof[2*k+1] = -st*cparg/a;
		}

		dcof = binomial_mult( n, rcof );
		free( rcof );

		dcof[1] = dcof[0];
		dcof[0] = 1.0;
		for( k = 3; k <= n; ++k )
			dcof[k] = dcof[2*k-2];
		return( dcof );
	}

	double *openAFE::dcof_bwhp( int n, double fcf ) {
		return( dcof_bwlp( n, fcf ) );
	}

	double *openAFE::dcof_bwbp( int n, double f1f, double f2f ) {
		int k;            // loop variables
		double theta;     // M_PI * (f2f - f1f) / 2.0
		double cp;        // cosine of phi
		double st;        // sine of theta
		double ct;        // cosine of theta
		double s2t;       // sine of 2*theta
		double c2t;       // cosine 0f 2*theta
		double *rcof;     // z^-2 coefficients
		double *tcof;     // z^-1 coefficients
		double *dcof;     // dk coefficients
		double parg;      // pole angle
		double sparg;     // sine of pole angle
		double cparg;     // cosine of pole angle
		double a;         // workspace variables

		cp = cos(M_PI * (f2f + f1f) / 2.0);
		theta = M_PI * (f2f - f1f) / 2.0;
		st = sin(theta);
		ct = cos(theta);
		s2t = 2.0*st*ct;        // sine of 2*theta
		c2t = 2.0*ct*ct - 1.0;  // cosine of 2*theta

		rcof = (double *)calloc( 2 * n, sizeof(double) );
		tcof = (double *)calloc( 2 * n, sizeof(double) );

		for( k = 0; k < n; ++k )
		{
		parg = M_PI * (double)(2*k+1)/(double)(2*n);
		sparg = sin(parg);
		cparg = cos(parg);
		a = 1.0 + s2t*sparg;
		rcof[2*k] = c2t/a;
		rcof[2*k+1] = s2t*cparg/a;
		tcof[2*k] = -2.0*cp*(ct+st*sparg)/a;
		tcof[2*k+1] = -2.0*cp*st*cparg/a;
		}

		dcof = trinomial_mult( n, tcof, rcof );
		free( tcof );
		free( rcof );

		dcof[1] = dcof[0];
		dcof[0] = 1.0;
		for( k = 3; k <= 2*n; ++k )
			dcof[k] = dcof[2*k-2];
		return( dcof );
	}

	double *openAFE::dcof_bwbs( int n, double f1f, double f2f ) {
		int k;            // loop variables
		double theta;     // M_PI * (f2f - f1f) / 2.0
		double cp;        // cosine of phi
		double st;        // sine of theta
		double ct;        // cosine of theta
		double s2t;       // sine of 2*theta
		double c2t;       // cosine 0f 2*theta
		double *rcof;     // z^-2 coefficients
		double *tcof;     // z^-1 coefficients
		double *dcof;     // dk coefficients
		double parg;      // pole angle
		double sparg;     // sine of pole angle
		double cparg;     // cosine of pole angle
		double a;         // workspace variables

		cp = cos(M_PI * (f2f + f1f) / 2.0);
		theta = M_PI * (f2f - f1f) / 2.0;
		st = sin(theta);
		ct = cos(theta);
		s2t = 2.0*st*ct;        // sine of 2*theta
		c2t = 2.0*ct*ct - 1.0;  // cosine 0f 2*theta

		rcof = (double *)calloc( 2 * n, sizeof(double) );
		tcof = (double *)calloc( 2 * n, sizeof(double) );  

		for( k = 0; k < n; ++k )
		{
		parg = M_PI * (double)(2*k+1)/(double)(2*n);
		sparg = sin(parg);
		cparg = cos(parg);
		a = 1.0 + s2t*sparg;
		rcof[2*k] = c2t/a;
		rcof[2*k+1] = -s2t*cparg/a;
		tcof[2*k] = -2.0*cp*(ct+st*sparg)/a;
		tcof[2*k+1] = 2.0*cp*st*cparg/a;
		}

		dcof = trinomial_mult( n, tcof, rcof );
		free( tcof );
		free( rcof );

		dcof[1] = dcof[0];
		dcof[0] = 1.0;
		for( k = 3; k <= 2*n; ++k )
			dcof[k] = dcof[2*k-2];
		return( dcof );
	}

	int *openAFE::ccof_bwlp( int n ) {
		int *ccof;
		int m;
		int i;

		ccof = (int *)calloc( n+1, sizeof(int) );
		if( ccof == NULL ) return( NULL );

		ccof[0] = 1;
		ccof[1] = n;
		m = n/2;
		for( i=2; i <= m; ++i)
		{
			ccof[i] = (n-i+1)*ccof[i-1]/i;
			ccof[n-i]= ccof[i];
		}
		ccof[n-1] = n;
		ccof[n] = 1;

		return( ccof );
	}

	int *openAFE::ccof_bwhp( int n ) {
		int *ccof;
		int i;

		ccof = ccof_bwlp( n );
		if( ccof == NULL ) return( NULL );

		for( i = 0; i <= n; ++i)
			if( i % 2 ) ccof[i] = -ccof[i];

		return( ccof );
	}

	int *openAFE::ccof_bwbp( int n ) {
		int *tcof;
		int *ccof;
		int i;

		ccof = (int *)calloc( 2*n+1, sizeof(int) );
		if( ccof == NULL ) return( NULL );

		tcof = ccof_bwhp(n);
		if( tcof == NULL ) return( NULL );

		for( i = 0; i < n; ++i)
		{
			ccof[2*i] = tcof[i];
			ccof[2*i+1] = 0.0;
		}
		ccof[2*n] = tcof[n];

		free( tcof );
		return( ccof );
	}

	double *openAFE::ccof_bwbs( int n, double f1f, double f2f ) {
		double alpha;
		double *ccof;
		int i, j;

		alpha = -2.0 * cos(M_PI * (f2f + f1f) / 2.0) / cos(M_PI * (f2f - f1f) / 2.0);

		ccof = (double *)calloc( 2*n+1, sizeof(double) );

		ccof[0] = 1.0;

		ccof[2] = 1.0;
		ccof[1] = alpha;
	  
		for( i = 1; i < n; ++i )
		{
		ccof[2*i+2] += ccof[2*i];
		for( j = 2*i; j > 1; --j )
			ccof[j+1] += alpha * ccof[j] + ccof[j-1];

		ccof[2] += alpha * ccof[1] + 1.0;
		ccof[1] += alpha;
		}

		return( ccof );
	}

	double openAFE::sf_bwlp( int n, double fcf ) {
		// int m, 
		int k;         // loop variables
		double omega;     // M_PI * fcf
		double fomega;    // function of omega
		double parg0;     // zeroth pole angle
		double sf;        // scaling factor

		omega = M_PI * fcf;
		fomega = sin(omega);
		parg0 = M_PI / (double)(2*n);

		// m = n / 2;
		sf = 1.0;
		for( k = 0; k < n/2; ++k )
			sf *= 1.0 + fomega * sin((double)(2*k+1)*parg0);

		fomega = sin(omega / 2.0);

		if( n % 2 ) sf *= fomega + cos(omega / 2.0);
		sf = pow( fomega, n ) / sf;

		return(sf);
	}

	double openAFE::sf_bwhp( int n, double fcf ) {
		// int m, 
		int k;         // loop variables
		double omega;     // M_PI * fcf
		double fomega;    // function of omega
		double parg0;     // zeroth pole angle
		double sf;        // scaling factor

		omega = M_PI * fcf;
		fomega = sin(omega);
		parg0 = M_PI / (double)(2*n);

		// m = n / 2;
		sf = 1.0;
		for( k = 0; k < n/2; ++k )
			sf *= 1.0 + fomega * sin((double)(2*k+1)*parg0);

		fomega = cos(omega / 2.0);

		if( n % 2 ) sf *= fomega + sin(omega / 2.0);
		sf = pow( fomega, n ) / sf;

		return(sf);
	}

	double openAFE::sf_bwbp( int n, double f1f, double f2f ) {
		int k;            // loop variables
		double ctt;       // cotangent of theta
		double sfr, sfi;  // real and imaginary parts of the scaling factor
		double parg;      // pole angle
		double sparg;     // sine of pole angle
		double cparg;     // cosine of pole angle
		double a, b, c;   // workspace variables

		ctt = 1.0 / tan(M_PI * (f2f - f1f) / 2.0);
		sfr = 1.0;
		sfi = 0.0;

		for( k = 0; k < n; ++k )
		{
		parg = M_PI * (double)(2*k+1)/(double)(2*n);
		sparg = ctt + sin(parg);
		cparg = cos(parg);
		a = (sfr + sfi)*(sparg - cparg);
		b = sfr * sparg;
		c = -sfi * cparg;
		sfr = b - c;
		sfi = a - b - c;
		}

		return( 1.0 / sfr );
	}

	double openAFE::sf_bwbs( int n, double f1f, double f2f ) {
		int k;            // loop variables
		double tt;        // tangent of theta
		double sfr, sfi;  // real and imaginary parts of the scaling factor
		double parg;      // pole angle
		double sparg;     // sine of pole angle
		double cparg;     // cosine of pole angle
		double a, b, c;   // workspace variables

		tt = tan(M_PI * (f2f - f1f) / 2.0);
		sfr = 1.0;
		sfi = 0.0;

		for( k = 0; k < n; ++k )
		{
		parg = M_PI * (double)(2*k+1)/(double)(2*n);
		sparg = tt + sin(parg);
		cparg = cos(parg);
		a = (sfr + sfi)*(sparg - cparg);
		b = sfr * sparg;
		c = -sfi * cparg;
		sfr = b - c;
		sfi = a - b - c;
		}

		return( 1.0 / sfr );
	}

