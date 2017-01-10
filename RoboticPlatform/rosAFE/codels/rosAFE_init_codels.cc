#include "acrosAFE.h"

#include "rosAFE_c_types.h"

#include "genom3_dataFiles.hpp"

/* --- Task init -------------------------------------------------------- */


/** Codel initIDS of task init.
 *
 * Triggered by rosAFE_start.
 * Yields to rosAFE_ether.
 */
genom_event
initIDS(rosAFE_ids *ids, genom_context self)
{
  ids->inputProcessorsSt = new rosAFE_inputProcessors();

  ids->preProcessorsSt = new rosAFE_preProcessors();

  ids->gammatoneProcessorsSt = new rosAFE_gammatoneProcessors();

  ids->ihcProcessorsSt = new rosAFE_ihcProcessors();

  ids->ildProcessorsSt = new rosAFE_ildProcessors();

  ids->ratemapProcessorsSt = new rosAFE_ratemapProcessors();

  ids->crossCorrelationProcessorsSt = new rosAFE_crossCorrelationProcessors();
          
  // Creating the structure which will contain all flags.
  ids->flagMapSt = new rosAFE_flagMap();
  ids->newDataMapSt = new rosAFE_flagMap();
  		
  return rosAFE_ether;
}
