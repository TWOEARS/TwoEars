#include "acrosAFE.h"
#include "rosAFE_c_types.h"

#include <memory>

#include "genom3_dataFiles.hpp"
#include "stateMachine.hpp"
#include "Ports.hpp"


/* --- Task ildProc ----------------------------------------------------- */


/* --- Activity IldProc ------------------------------------------------- */

/** Codel startIldProc of activity IldProc.
 *
 * Triggered by rosAFE_start.
 * Yields to rosAFE_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
startIldProc(const char *name, const char *upperDepName,
             rosAFE_ildProcessors **ildProcessorsSt,
             rosAFE_flagMap **flagMapSt, rosAFE_flagMap **newDataMapSt,
             rosAFE_ihcProcessors **ihcProcessorsSt,
             const rosAFE_infos *infos, const rosAFE_ildPort *ildPort,
             const char *ild_wname, double ild_wSizeSec,
             double ild_hSizeSec, genom_context self)
{	
  std::shared_ptr < IHCProc > upperDepProc = ((*ihcProcessorsSt)->processorsAccessor).getProcessor( upperDepName );

  if (!(upperDepProc))
	return rosAFE_e_noUpperDependencie (self);
	
  windowType thisWindow = _hann;
  if ( strcmp( ild_wname, "hamming" ) == 0 )
    thisWindow = _hamming;
  else if ( strcmp( ild_wname, "hanning" ) == 0 )
     thisWindow = _hanning;
  else if ( strcmp( ild_wname, "blackman" ) == 0 )
     thisWindow = _blackman;
  else if ( strcmp( ild_wname, "triang" ) == 0 )
    thisWindow = _triang;
  else if ( strcmp( ild_wname, "sqrt_win" ) == 0 )
    thisWindow = _sqrt_win;

  std::shared_ptr < ILDProc > ildProcessor ( new ILDProc( name, upperDepProc, ild_wSizeSec, ild_hSizeSec, thisWindow ) );

  /* Adding this procesor to the ids */
  ((*ildProcessorsSt)->processorsAccessor).addProcessor( ildProcessor );

  // Initialization of the output port
  PORT::initILDPort ( name, ildPort, ildProcessor->getFsOut(),
						infos->bufferSize_s_port, ildProcessor->get_nChannel(), self );
  
  SM::addFlag( name, upperDepName, flagMapSt, self );
  SM::addFlag( name, upperDepName, newDataMapSt, self );

  upperDepProc.reset();
  ildProcessor.reset();
  return rosAFE_waitExec;
}

/** Codel waitExec of activity IldProc.
 *
 * Triggered by rosAFE_waitExec.
 * Yields to rosAFE_pause_waitExec, rosAFE_exec, rosAFE_ether,
 *           rosAFE_delete.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel execIldProc of activity IldProc.
 *
 * Triggered by rosAFE_exec.
 * Yields to rosAFE_waitRelease.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
execIldProc(const char *name, const char *upperDepName,
            rosAFE_ids *ids, rosAFE_flagMap **flagMapSt,
            genom_context self)
{
  ids->ildProcessorsSt->processorsAccessor.getProcessor ( name )->processChunk( );

  // At the end of this codel, the upperDep will be able to overwite the data.
  SM::fallFlag ( name, upperDepName, flagMapSt, self);
  return rosAFE_waitRelease;
}

/** Codel waitRelease of activity IldProc.
 *
 * Triggered by rosAFE_waitRelease.
 * Yields to rosAFE_pause_waitRelease, rosAFE_release, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel releaseIldProc of activity IldProc.
 *
 * Triggered by rosAFE_release.
 * Yields to rosAFE_pause_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
releaseIldProc(const char *name, rosAFE_ids *ids,
               rosAFE_flagMap **newDataMapSt,
               const rosAFE_ildPort *ildPort, genom_context self)
{
  std::shared_ptr < ILDProc > thisProcessor = ids->ildProcessorsSt->processorsAccessor.getProcessor ( name );
  thisProcessor->releaseChunk( );
  
  PORT::publishILDPort ( name, ildPort, thisProcessor->getLeftLastChunkAccessor(), sizeof(double), thisProcessor->getNFR(), self );

  // Informing all the potential childs to say that this is a new chunk.
  SM::riseFlag ( name, newDataMapSt, self );
    
  thisProcessor.reset();
  return rosAFE_pause_waitExec;
}

/** Codel deleteIldProc of activity IldProc.
 *
 * Triggered by rosAFE_delete.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
deleteIldProc(const char *name, rosAFE_ildProcessors **ildProcessorsSt,
              const rosAFE_ildPort *ildPort, genom_context self)
{
  /* Delting the processor */
  ((*ildProcessorsSt)->processorsAccessor).removeProcessor( name );
  PORT::deleteILDPort ( name, ildPort, self ); 
    
  return rosAFE_ether;
}

/** Codel stopIldProc of activity IldProc.
 *
 * Triggered by rosAFE_stop.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
stopIldProc(rosAFE_ildProcessors **ildProcessorsSt,
            genom_context self)
{
  ((*ildProcessorsSt)->processorsAccessor).clear();
  
  delete (*ildProcessorsSt);
  
  return rosAFE_ether;
}
