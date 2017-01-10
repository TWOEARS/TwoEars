#include "acrosAFE.h"
#include "rosAFE_c_types.h"

#include <memory>

#include "genom3_dataFiles.hpp"
#include "stateMachine.hpp"
#include "Ports.hpp"

/* --- Task ihcProc ----------------------------------------------------- */


/* --- Activity IhcProc ------------------------------------------------- */

/** Codel startIhcProc of activity IhcProc.
 *
 * Triggered by rosAFE_start.
 * Yields to rosAFE_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
startIhcProc(const char *name, const char *upperDepName,
             rosAFE_ihcProcessors **ihcProcessorsSt,
             rosAFE_flagMap **flagMapSt, rosAFE_flagMap **newDataMapSt,
             rosAFE_gammatoneProcessors **gammatoneProcessorsSt,
             const rosAFE_infos *infos, const rosAFE_ihcPort *ihcPort,
             const char *ihc_method, genom_context self)
{
  std::shared_ptr < GammatoneProc > upperDepProc = ((*gammatoneProcessorsSt)->processorsAccessor).getProcessor( upperDepName );

  if (!(upperDepProc))
	return rosAFE_e_noUpperDependencie (self);
	
  ihcMethod thisMethod = _dau;
  if ( strcmp( ihc_method, "none" ) == 0 )
	thisMethod = _none;
  else if ( strcmp( ihc_method, "halfwave" ) == 0 )
	thisMethod = _halfwave;
  else if ( strcmp( ihc_method, "fullwave" ) == 0 )
	thisMethod = _fullwave;
  else if ( strcmp( ihc_method, "square" ) == 0 )
	thisMethod = _square;
  else if ( strcmp( ihc_method, "hilbert" ) == 0 )
	thisMethod = _hilbert;
  else if ( strcmp( ihc_method, "joergensen" ) == 0 )
	thisMethod = _joergensen;
  else if ( strcmp( ihc_method, "breebart" ) == 0 )
	thisMethod = _breebart;
  else if ( strcmp( ihc_method, "bernstein" ) == 0 )
	thisMethod = _bernstein;
					  
  std::shared_ptr < IHCProc > ihcProcessor ( new IHCProc( name, upperDepProc, thisMethod) );
  
  /* Adding this procesor to the ids */
  ((*ihcProcessorsSt)->processorsAccessor).addProcessor( ihcProcessor );
  
  SM::addFlag( name, upperDepName, flagMapSt, self );
  SM::addFlag( name, upperDepName, newDataMapSt, self );

  // Initialization of the output port
  PORT::initIHCPort( name, ihcPort, infos->sampleRate, infos->bufferSize_s_port, ihcProcessor->get_nChannel(), self );
  
  upperDepProc.reset();
  ihcProcessor.reset();
  return rosAFE_waitExec;
}

/** Codel waitExec of activity IhcProc.
 *
 * Triggered by rosAFE_waitExec.
 * Yields to rosAFE_pause_waitExec, rosAFE_exec, rosAFE_ether,
 *           rosAFE_delete.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel execIhcProc of activity IhcProc.
 *
 * Triggered by rosAFE_exec.
 * Yields to rosAFE_waitRelease.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
execIhcProc(const char *name, const char *upperDepName,
            rosAFE_ids *ids, rosAFE_flagMap **flagMapSt,
            genom_context self)
{
  ids->ihcProcessorsSt->processorsAccessor.getProcessor ( name )->processChunk( );

  // At the end of this codel, the upperDep will be able to overwite the data.
  SM::fallFlag ( name, upperDepName, flagMapSt, self);
  return rosAFE_waitRelease;
}

/** Codel waitRelease of activity IhcProc.
 *
 * Triggered by rosAFE_waitRelease.
 * Yields to rosAFE_pause_waitRelease, rosAFE_release, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel releaseIhcProc of activity IhcProc.
 *
 * Triggered by rosAFE_release.
 * Yields to rosAFE_pause_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
releaseIhcProc(const char *name, rosAFE_ids *ids,
               rosAFE_flagMap **newDataMapSt,
               const rosAFE_ihcPort *ihcPort, genom_context self)
{
  std::shared_ptr < IHCProc > thisProcessor = ids->ihcProcessorsSt->processorsAccessor.getProcessor ( name );
  thisProcessor->releaseChunk( );
  
  PORT::publishIHCPort ( name, ihcPort, thisProcessor->getLeftLastChunkAccessor(), thisProcessor->getRightLastChunkAccessor(), sizeof(double), thisProcessor->getNFR(), self );

  // Informing all the potential childs to say that this is a new chunk.
  SM::riseFlag ( name, newDataMapSt, self );
    
  thisProcessor.reset();
  return rosAFE_pause_waitExec;
}

/** Codel deleteIhcProc of activity IhcProc.
 *
 * Triggered by rosAFE_delete.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
deleteIhcProc(const char *name, rosAFE_ihcProcessors **ihcProcessorsSt,
              const rosAFE_ihcPort *ihcPort, genom_context self)
{
  /* Delting the processor */
  ((*ihcProcessorsSt)->processorsAccessor).removeProcessor( name );
  PORT::deleteIHCPort ( name, ihcPort, self );  
    
  return rosAFE_ether;
}

/** Codel stopIhcProc of activity IhcProc.
 *
 * Triggered by rosAFE_stop.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
stopIhcProc(rosAFE_ihcProcessors **ihcProcessorsSt,
            genom_context self)
{
  ((*ihcProcessorsSt)->processorsAccessor).clear();
  
  delete (*ihcProcessorsSt);
  
  return rosAFE_ether;
}
