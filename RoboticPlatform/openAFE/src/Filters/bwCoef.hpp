#ifndef BWCOEFF_HPP
#define BWCOEFF_HPP

/* THIS FILE IS MODIFIED FROM bwlp file of Exstrom Laboratories LLC */
/* Butterworth filter coefficient calculator. */

/*
 *                            COPYRIGHT
 *
 *  bwlp - Butterworth lowpass filter coefficient calculator
 *  Copyright (C) 2003, 2004, 2005, 2007 Exstrom Laboratories LLC
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
 *  info(AT)exstrom.com
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
#include "bwIIR.hpp"

#include <vector>
#include <assert.h>


namespace openAFE {
	
	enum bwType{
	  _bwlp,	/* low Pass */
	  _bwhp, /* high pass */
	  _bwbp, /* band pass */ 
	  _bwbs  /* band stop */
	};

	double bwCoef(unsigned int n, double fs, double f1f, std::vector<double>& vectDcof, std::vector<double>& vectCcof, bwType type,  double f2f = 0) ;
};

# endif /* BWCOEFF_HPP */
