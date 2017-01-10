#ifndef PROCESSORCOMMON_HPP
#define PROCESSORCOMMON_HPP

#include "acrosAFE.h"

#include "rosAFE_c_types.h"

#include "genom3_dataFiles.hpp"

#include <string>

#include <sys/time.h>

namespace PC {
	
	genom_event
	execAnyProc( const char *nameProc, rosAFE_ids *ids, genom_context self );
	
	genom_event
	releaseAnyProc( const char *nameProc, rosAFE_ids *ids, genom_context self );

}; /* namespace PC */

#endif /* PROCESSORCOMMON_HPP */
