#ifndef BWIIR_HPP
#define BWIIR_HPP

/*
 *                            COPYRIGHT
 *
 *  liir - Recursive digital filter functions
 *  Copyright (C) 2007 Exstrom Laboratories LLC
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  A copy of the GNU General Public License is available on the internet at:
 *
 *  http://www.gnu.org/copyleft/gpl.html
 *
 *  or you can write to:
 *
 *  The Free Software Foundation, Inc.
 *  675 Mass Ave
 *  Cambridge, MA 02139, USA
 *
 *  You can contact Exstrom Laboratories LLC via Email at:
 *
 *  stefan(AT)exstrom.com
 *
 *  or you can write to:
 *
 *  Exstrom Laboratories LLC
 *  P.O. Box 7651
 *  Longmont, CO 80501, USA
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

/**********************************************************************
  binomial_mult - multiplies a series of binomials together and returns
  the coefficients of the resulting polynomial.
  
  The multiplication has the following form:
  
  (x+p[0])*(x+p[1])*...*(x+p[n-1])

  The p[i] coefficients are assumed to be complex and are passed to the 
  function as a pointer to an array of doubles of length 2n.

  The resulting polynomial has the following form:
  
  x^n + a[0]*x^n-1 + a[1]*x^n-2 + ... +a[n-2]*x + a[n-1]
  
  The a[i] coefficients can in general be complex but should in most
  cases turn out to be real. The a[i] coefficients are returned by the
  function as a pointer to an array of doubles of length 2n. Storage
  for the array is allocated by the function and should be freed by the
  calling program when no longer needed.
  
  Function arguments:
  
  n  -  The number of binomials to multiply
  p  -  Pointer to an array of doubles where p[2i] (i=0...n-1) is
        assumed to be the real part of the coefficient of the ith binomial
        and p[2i+1] is assumed to be the imaginary part. The overall size
        of the array is then 2n.
*/


namespace openAFE {
	
	double *binomial_mult( int n, double *p );

	/**********************************************************************
	  trinomial_mult - multiplies a series of trinomials together and returns
	  the coefficients of the resulting polynomial.
	  
	  The multiplication has the following form:

	  (x^2 + b[0]x + c[0])*(x^2 + b[1]x + c[1])*...*(x^2 + b[n-1]x + c[n-1])

	  The b[i] and c[i] coefficients are assumed to be complex and are passed
	  to the function as a pointers to arrays of doubles of length 2n. The real
	  part of the coefficients are stored in the even numbered elements of the
	  array and the imaginary parts are stored in the odd numbered elements.

	  The resulting polynomial has the following form:
	  
	  x^2n + a[0]*x^2n-1 + a[1]*x^2n-2 + ... +a[2n-2]*x + a[2n-1]
	  
	  The a[i] coefficients can in general be complex but should in most cases
	  turn out to be real. The a[i] coefficients are returned by the function as
	  a pointer to an array of doubles of length 4n. The real and imaginary
	  parts are stored, respectively, in the even and odd elements of the array.
	  Storage for the array is allocated by the function and should be freed by
	  the calling program when no longer needed.
	  
	  Function arguments:
	  
	  n  -  The number of trinomials to multiply
	  b  -  Pointer to an array of doubles of length 2n.
	  c  -  Pointer to an array of doubles of length 2n.
	*/

	double *trinomial_mult( int n, double *b, double *c );


	/**********************************************************************
	  dcof_bwlp - calculates the d coefficients for a butterworth lowpass 
	  filter. The coefficients are returned as an array of doubles.

	*/

	double *dcof_bwlp( int n, double fcf );

	/**********************************************************************
	  dcof_bwhp - calculates the d coefficients for a butterworth highpass 
	  filter. The coefficients are returned as an array of doubles.

	*/

	double *dcof_bwhp( int n, double fcf );


	/**********************************************************************
	  dcof_bwbp - calculates the d coefficients for a butterworth bandpass 
	  filter. The coefficients are returned as an array of doubles.

	*/

	double *dcof_bwbp( int n, double f1f, double f2f );

	/**********************************************************************
	  dcof_bwbs - calculates the d coefficients for a butterworth bandstop 
	  filter. The coefficients are returned as an array of doubles.

	*/

	double *dcof_bwbs( int n, double f1f, double f2f );

	/**********************************************************************
	  ccof_bwlp - calculates the c coefficients for a butterworth lowpass 
	  filter. The coefficients are returned as an array of integers.

	*/

	int *ccof_bwlp( int n );

	/**********************************************************************
	  ccof_bwhp - calculates the c coefficients for a butterworth highpass 
	  filter. The coefficients are returned as an array of integers.

	*/

	int *ccof_bwhp( int n );

	/**********************************************************************
	  ccof_bwbp - calculates the c coefficients for a butterworth bandpass 
	  filter. The coefficients are returned as an array of integers.

	*/

	int *ccof_bwbp( int n );

	/**********************************************************************
	  ccof_bwbs - calculates the c coefficients for a butterworth bandstop 
	  filter. The coefficients are returned as an array of integers.

	*/

	double *ccof_bwbs( int n, double f1f, double f2f );

	/**********************************************************************
	  sf_bwlp - calculates the scaling factor for a butterworth lowpass filter.
	  The scaling factor is what the c coefficients must be multiplied by so
	  that the filter response has a maximum value of 1.

	*/

	double sf_bwlp( int n, double fcf );

	/**********************************************************************
	  sf_bwhp - calculates the scaling factor for a butterworth highpass filter.
	  The scaling factor is what the c coefficients must be multiplied by so
	  that the filter response has a maximum value of 1.

	*/

	double sf_bwhp( int n, double fcf );

	/**********************************************************************
	  sf_bwbp - calculates the scaling factor for a butterworth bandpass filter.
	  The scaling factor is what the c coefficients must be multiplied by so
	  that the filter response has a maximum value of 1.

	*/

	double sf_bwbp( int n, double f1f, double f2f );

	/**********************************************************************
	  sf_bwbs - calculates the scaling factor for a butterworth bandstop filter.
	  The scaling factor is what the c coefficients must be multiplied by so
	  that the filter response has a maximum value of 1.

	*/

	double sf_bwbs( int n, double f1f, double f2f );
};

#endif /* BWIIR_HPP */
