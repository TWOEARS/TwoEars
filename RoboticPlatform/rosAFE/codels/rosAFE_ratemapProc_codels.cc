#include "acrosAFE.h"
#include "rosAFE_c_types.h"

#include <memory>

#include "genom3_dataFiles.hpp"
#include "stateMachine.hpp"
#include "Ports.hpp"

/* --- Task ratemapProc ------------------------------------------------- */


/* --- Activity RatemapProc --------------------------------------------- */

/** Codel startRatemapProc of activity RatemapProc.
 *
 * Triggered by rosAFE_start.
 * Yields to rosAFE_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
startRatemapProc(const char *name, const char *upperDepName,
                 rosAFE_ratemapProcessors **ratemapProcessorsSt,
                 rosAFE_flagMap **flagMapSt,
                 rosAFE_flagMap **newDataMapSt,
                 rosAFE_ihcProcessors **ihcProcessorsSt,
                 const rosAFE_infos *infos,
                 const rosAFE_ratemapPort *ratemapPort,
                 const char *rm_wname, double rm_wSizeSec,
                 double rm_hSizeSec, const char *rm_scaling,
                 double rm_decaySec, genom_context self)
{
  std::shared_ptr < IHCProc > upperDepProc = ((*ihcProcessorsSt)->processorsAccessor).getProcessor( upperDepName );

  if (!(upperDepProc))
	return rosAFE_e_noUpperDependencie (self);
	
  windowType thisWindow = _hann;
  if ( strcmp( rm_wname, "hamming" ) == 0 )
    thisWindow = _hamming;
  else if ( strcmp( rm_wname, "hanning" ) == 0 )
     thisWindow = _hanning;
  else if ( strcmp( rm_wname, "blackman" ) == 0 )
     thisWindow = _blackman;
  else if ( strcmp( rm_wname, "triang" ) == 0 )
    thisWindow = _triang;
  else if ( strcmp( rm_wname, "sqrt_win" ) == 0 )
    thisWindow = _sqrt_win;

  scalingType thisScaling = _magnitude;
  if ( strcmp( rm_scaling, "power" ) == 0 )
    thisScaling = _power;  
  
  std::shared_ptr < Ratemap > ratemapProcessor ( new Ratemap( name, upperDepProc, rm_wSizeSec, rm_hSizeSec, thisScaling, rm_decaySec, thisWindow ) );
  
  /* Adding this procesor to the ids */
  ((*ratemapProcessorsSt)->processorsAccessor).addProcessor( ratemapProcessor );

  // Initialization of the output port
  PORT::initRatemapPort ( name, ratemapPort, ratemapProcessor->getFsOut(),
						infos->bufferSize_s_port, ratemapProcessor->get_nChannel(), self );
  
  SM::addFlag( name, upperDepName, flagMapSt, self );
  SM::addFlag( name, upperDepName, newDataMapSt, self );

  upperDepProc.reset();
  ratemapProcessor.reset();
  return rosAFE_waitExec;
}

/** Codel waitExec of activity RatemapProc.
 *
 * Triggered by rosAFE_waitExec.
 * Yields to rosAFE_pause_waitExec, rosAFE_exec, rosAFE_ether,
 *           rosAFE_delete.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel execRatemapProc of activity RatemapProc.
 *
 * Triggered by rosAFE_exec.
 * Yields to rosAFE_waitRelease.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
execRatemapProc(const char *name, const char *upperDepName,
                rosAFE_ids *ids, rosAFE_flagMap **flagMapSt,
                genom_context self)
{
  ids->ratemapProcessorsSt->processorsAccessor.getProcessor ( name )->processChunk( );

  // At the end of this codel, the upperDep will be able to overwite the data.
  SM::fallFlag ( name, upperDepName, flagMapSt, self);
  return rosAFE_waitRelease;  
}

/** Codel waitRelease of activity RatemapProc.
 *
 * Triggered by rosAFE_waitRelease.
 * Yields to rosAFE_pause_waitRelease, rosAFE_release, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel releaseRatemapProc of activity RatemapProc.
 *
 * Triggered by rosAFE_release.
 * Yields to rosAFE_pause_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
releaseRatemapProc(const char *name, rosAFE_ids *ids,
                   rosAFE_flagMap **newDataMapSt,
                   const rosAFE_ratemapPort *ratemapPort,
                   genom_context self)
{
  std::shared_ptr < Ratemap > thisProcessor = ids->ratemapProcessorsSt->processorsAccessor.getProcessor ( name );
  thisProcessor->releaseChunk( );
  
  PORT::publishRatemapPort ( name, ratemapPort, thisProcessor->getLeftLastChunkAccessor(), thisProcessor->getRightLastChunkAccessor(), sizeof(double), thisProcessor->getNFR(), self );

  // Informing all the potential childs to say that this is a new chunk.
  SM::riseFlag ( name, newDataMapSt, self );
    
  thisProcessor.reset();
  return rosAFE_pause_waitExec;
}

/** Codel deleteRatemapProc of activity RatemapProc.
 *
 * Triggered by rosAFE_delete.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
deleteRatemapProc(const char *name,
                  rosAFE_ratemapProcessors **ratemapProcessorsSt,
                  const rosAFE_ratemapPort *ratemapPort,
                  genom_context self)
{
  /* Delting the processor */
  ((*ratemapProcessorsSt)->processorsAccessor).removeProcessor( name );
  PORT::deleteRatemapPort ( name, ratemapPort, self ); 
    
  return rosAFE_ether;
}

/** Codel stopRatemapProc of activity RatemapProc.
 *
 * Triggered by rosAFE_stop.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
stopRatemapProc(rosAFE_ratemapProcessors **ratemapProcessorsSt,
                genom_context self)
{
  ((*ratemapProcessorsSt)->processorsAccessor).clear();
  
  delete (*ratemapProcessorsSt);
  
  return rosAFE_ether;
}
