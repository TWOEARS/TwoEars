#ifndef MATFILES_HPP
#define MATFILES_HPP

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <vector>
#include <memory>

#include "mat.h"
#include "../src/Signals/dataType.hpp"


namespace matFiles {
	
	int readMatFile(const char *file, std::vector <std::vector<double> >& earSignals, double *fsHz);
	
	int writeTDSMatFile(const char *file, std::shared_ptr<openAFE::twoCTypeBlock<double> > left, std::shared_ptr<openAFE::twoCTypeBlock<double> > right, double fsHz);

	int writeTFSMatFile(const char *file, std::vector<std::shared_ptr<openAFE::twoCTypeBlock<double> > >& left, std::vector<std::shared_ptr<openAFE::twoCTypeBlock<double> > >& right, double fsHz);

	int writeXCORRMatFile(const char *file, std::vector<std::vector<std::shared_ptr<openAFE::twoCTypeBlock<double> > > >& left, double fsHz);
	
}; /* namespace matFiles */

#endif /* MATFILES_HPP */
