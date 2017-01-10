#ifndef STATEMACHINE_HPP
#define STATEMACHINE_HPP

#include "acrosAFE.h"

#include "rosAFE_c_types.h"

#include "genom3_dataFiles.hpp"

#include <string>

namespace SM {
	
	void addFlag( const char *name, const char *upperDep, rosAFE_flagMap **flagMapSt, genom_context self );
	
	int checkFlag ( const char *name, const char *upperDep, rosAFE_flagMap **newDataMapSt, genom_context self  );
	
	bool checkFlag ( const char *name, rosAFE_flagMap **newDataMapSt, genom_context self  );

	void fallFlag ( const char *name, const char *upperDep, rosAFE_flagMap **newDataMapSt, genom_context self  );

	void riseFlag ( const char *name, rosAFE_flagMap **newDataMapSt, genom_context self  );

	bool removeFlag ( const char *name, rosAFE_flagMap **newDataMapSt, genom_context self );
}; /* namespace SM */

#endif /* STATEMACHINE_HPP */
