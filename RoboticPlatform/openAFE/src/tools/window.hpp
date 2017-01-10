#ifndef WINDOW_HPP
#define WINDOW_HPP

#include <stdint.h>
#include <vector>
#include <math.h> /* M_PI */
#include <cmath> /* cos */

/*!
 * 
 * This file is modified from : IT++ library : http://itpp.sourceforge.net/4.3.1/
 * 
 * \file
 * \brief Implementation of window functions
 * \author Tony Ottosson, Tobias Ringstrom, Pal Frenger, Adam Piatyszek
 *         and Kumar Appaiah
 *
 * -------------------------------------------------------------------------
 *
 * Copyright (C) 1995-2010  (see AUTHORS file for a list of contributors)
 * -------------------------------------------------------------------------
 */
 
namespace openAFE {

	std::vector<double> hamming( std::size_t n );

	std::vector<double> hanning( std::size_t n );

	// matlab version
	std::vector<double> hann(std::size_t n);

	std::vector<double> blackman(std::size_t n);

	std::vector<double> triang(std::size_t n);

	std::vector<double> sqrt_win(std::size_t n);

}; //namespace openAFE

#endif // #ifndef WINDOW_HPP
