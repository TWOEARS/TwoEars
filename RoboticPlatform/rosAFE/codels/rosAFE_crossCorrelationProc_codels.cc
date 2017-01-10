#include "acrosAFE.h"

#include "rosAFE_c_types.h"

#include <memory>
#include <iostream>

#include "genom3_dataFiles.hpp"
#include "stateMachine.hpp"
#include "Ports.hpp"

/* --- Task crossCorrelationProc ---------------------------------------- */


/* --- Activity CrossCorrelationProc ------------------------------------ */

/** Codel startCrossCorrelationProc of activity CrossCorrelationProc.
 *
 * Triggered by rosAFE_start.
 * Yields to rosAFE_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
startCrossCorrelationProc(const char *name, const char *upperDepName,
                          rosAFE_crossCorrelationProcessors **crossCorrelationProcessorsSt,
                          rosAFE_flagMap **flagMapSt,
                          rosAFE_flagMap **newDataMapSt,
                          rosAFE_ihcProcessors **ihcProcessorsSt,
                          const rosAFE_infos *infos,
                          const rosAFE_crossCorrelationPort *crossCorrelationPort,
                          double cc_wSizeSec, double cc_hSizeSec,
                          double cc_maxDelaySec, const char *cc_wname,
                          genom_context self)
{
  std::shared_ptr < IHCProc > upperDepProc = ((*ihcProcessorsSt)->processorsAccessor).getProcessor( upperDepName );

  if (!(upperDepProc))
	return rosAFE_e_noUpperDependencie (self);

  windowType thisWindow = _hann;
  if ( strcmp( cc_wname, "hamming" ) == 0 )
    thisWindow = _hamming;
  else if ( strcmp( cc_wname, "hanning" ) == 0 )
     thisWindow = _hanning;
  else if ( strcmp( cc_wname, "blackman" ) == 0 )
     thisWindow = _blackman;
  else if ( strcmp( cc_wname, "triang" ) == 0 )
    thisWindow = _triang;
  else if ( strcmp( cc_wname, "sqrt_win" ) == 0 )
    thisWindow = _sqrt_win;

  std::shared_ptr < CrossCorrelation > crossCorrelationProcessor ( new CrossCorrelation( name, upperDepProc, cc_wSizeSec, cc_hSizeSec, cc_maxDelaySec, thisWindow  ));

  /* Adding this procesor to the ids */
  ((*crossCorrelationProcessorsSt)->processorsAccessor).addProcessor( crossCorrelationProcessor );   

  // Initialization of the output port
  PORT::initCrossCorrelationPort ( name, crossCorrelationPort, crossCorrelationProcessor->getFsOut(),
								   infos->bufferSize_s_port, crossCorrelationProcessor->get_cc_lags_size(), crossCorrelationProcessor->get_nChannel(), self );					
				
  SM::addFlag( name, upperDepName, flagMapSt, self );
  SM::addFlag( name, upperDepName, newDataMapSt, self );

  upperDepProc.reset();
  crossCorrelationProcessor.reset();   
  return rosAFE_waitExec;
}

/** Codel waitExec of activity CrossCorrelationProc.
 *
 * Triggered by rosAFE_waitExec.
 * Yields to rosAFE_pause_waitExec, rosAFE_exec, rosAFE_ether,
 *           rosAFE_delete.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel execCrossCorrelationProc of activity CrossCorrelationProc.
 *
 * Triggered by rosAFE_exec.
 * Yields to rosAFE_waitRelease.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
execCrossCorrelationProc(const char *name, const char *upperDepName,
                         rosAFE_ids *ids, rosAFE_flagMap **flagMapSt,
                         genom_context self)
{
  ids->crossCorrelationProcessorsSt->processorsAccessor.getProcessor ( name )->processChunk( );

  // At the end of this codel, the upperDep will be able to overwite the data.
  SM::fallFlag ( name, upperDepName, flagMapSt, self);
  
  return rosAFE_waitRelease;
}

/** Codel waitRelease of activity CrossCorrelationProc.
 *
 * Triggered by rosAFE_waitRelease.
 * Yields to rosAFE_pause_waitRelease, rosAFE_release, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel releaseCrossCorrelationProc of activity CrossCorrelationProc.
 *
 * Triggered by rosAFE_release.
 * Yields to rosAFE_pause_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
releaseCrossCorrelationProc(const char *name, rosAFE_ids *ids,
                            rosAFE_flagMap **newDataMapSt,
                            const rosAFE_crossCorrelationPort *crossCorrelationPort,
                            genom_context self)
{
  std::shared_ptr < CrossCorrelation > thisProcessor = ids->crossCorrelationProcessorsSt->processorsAccessor.getProcessor ( name );
  thisProcessor->releaseChunk( );
  
  PORT::publishCrossCorrelationPort ( name, crossCorrelationPort, thisProcessor->getLeftLastChunkAccessor(), sizeof(double), thisProcessor->getNFR(), self );

  // Informing all the potential childs to say that this is a new chunk.
  SM::riseFlag ( name, newDataMapSt, self );
    
  thisProcessor.reset();
  return rosAFE_pause_waitExec;
}

/** Codel deleteCrossCorrelationProc of activity CrossCorrelationProc.
 *
 * Triggered by rosAFE_delete.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
deleteCrossCorrelationProc(const char *name,
                           rosAFE_crossCorrelationProcessors **crossCorrelationProcessorsSt,
                           const rosAFE_crossCorrelationPort *crossCorrelationPort,
                           genom_context self)
{
  /* Delting the processor */
  ((*crossCorrelationProcessorsSt)->processorsAccessor).removeProcessor( name );
  //PORT::deleteCrossCorrelationPort ( name, crossCorrelationPort, self ); 
  
  return rosAFE_ether;
}

/** Codel stopCrossCorrelationProc of activity CrossCorrelationProc.
 *
 * Triggered by rosAFE_stop.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
stopCrossCorrelationProc(rosAFE_crossCorrelationProcessors **crossCorrelationProcessorsSt,
                         genom_context self)
{
  ((*crossCorrelationProcessorsSt)->processorsAccessor).clear();
  
  delete (*crossCorrelationProcessorsSt);

  return rosAFE_ether;
}
