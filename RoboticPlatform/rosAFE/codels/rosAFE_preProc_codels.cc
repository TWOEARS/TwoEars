#include "acrosAFE.h"
#include "rosAFE_c_types.h"

#include <memory>

#include "genom3_dataFiles.hpp"
#include "stateMachine.hpp"
#include "Ports.hpp"


/* --- Task preProc ----------------------------------------------------- */


/* --- Activity PreProc ------------------------------------------------- */

/** Codel startPreProc of activity PreProc.
 *
 * Triggered by rosAFE_start.
 * Yields to rosAFE_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
startPreProc(const char *name, const char *upperDepName,
             rosAFE_preProcessors **preProcessorsSt,
             rosAFE_flagMap **flagMapSt, rosAFE_flagMap **newDataMapSt,
             rosAFE_inputProcessors **inputProcessorsSt,
             const rosAFE_infos *infos,
             const rosAFE_preProcPort *preProcPort, bool pp_bRemoveDC,
             double pp_cutoffHzDC, bool pp_bPreEmphasis,
             double pp_coefPreEmphasis, bool pp_bNormalizeRMS,
             double pp_intTimeSecRMS, bool pp_bLevelScaling,
             double pp_refSPLdB, bool pp_bMiddleEarFiltering,
             const char *pp_middleEarModel, bool pp_bUnityComp,
             genom_context self)
{
  std::shared_ptr < InputProc > upperDepProc = ((*inputProcessorsSt)->processorsAccessor).getProcessor( upperDepName );
  
  if (!(upperDepProc))
	return rosAFE_e_noUpperDependencie (self);
  
  middleEarModel thisModel = _jepsen;
  if ( strcmp( pp_middleEarModel, "lopezpoveda" ) == 0 )
	thisModel = _lopezpoveda;
	    
  std::shared_ptr < PreProc > preProcessor (new PreProc( name, upperDepProc,
  pp_bRemoveDC, pp_cutoffHzDC, pp_bPreEmphasis, pp_coefPreEmphasis, pp_bNormalizeRMS, pp_intTimeSecRMS, pp_bLevelScaling,
  pp_refSPLdB, pp_bMiddleEarFiltering, thisModel, pp_bUnityComp) );
  
  // Adding this procesor to the ids
  ((*preProcessorsSt)->processorsAccessor).addProcessor( preProcessor );

  SM::addFlag( name, upperDepName, flagMapSt, self );
  SM::addFlag( name, upperDepName, newDataMapSt, self );

  // Initialization of the output port
  PORT::initPreProcPort( name, preProcPort, infos->sampleRate, infos->bufferSize_s_port, self );

  upperDepProc.reset();
  preProcessor.reset();
  return rosAFE_waitExec;
}

/** Codel waitExec of activity PreProc.
 *
 * Triggered by rosAFE_waitExec.
 * Yields to rosAFE_pause_waitExec, rosAFE_exec, rosAFE_ether,
 *           rosAFE_delete.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
waitExec(const char *name, const char *upperDepName,
         rosAFE_flagMap **newDataMapSt, genom_context self)
{
  // If there is no new data, we will wait
  int check = SM::checkFlag( name, upperDepName, newDataMapSt, self);

  if (check == 0)
	return rosAFE_pause_waitExec;
  if (check == 2) {
	return rosAFE_delete;
  }
  /* Nothing here */

  // That data is now old
  SM::fallFlag ( name, upperDepName, newDataMapSt, self);
  return rosAFE_exec;
}

/** Codel execPreProc of activity PreProc.
 *
 * Triggered by rosAFE_exec.
 * Yields to rosAFE_waitRelease.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
execPreProc(const char *name, const char *upperDepName,
            rosAFE_ids *ids, rosAFE_flagMap **flagMapSt,
            genom_context self)
{
  ids->preProcessorsSt->processorsAccessor.getProcessor ( name )->processChunk( );

  // At the end of this codel, the upperDep will be able to overwite the data.
  SM::fallFlag ( name, upperDepName, flagMapSt, self);
    
  return rosAFE_waitRelease;
}

/** Codel waitRelease of activity PreProc.
 *
 * Triggered by rosAFE_waitRelease.
 * Yields to rosAFE_pause_waitRelease, rosAFE_release, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
waitRelease(const char *name, rosAFE_flagMap **flagMapSt,
            genom_context self)
{
  /* Waiting for all childs */
  if ( ! SM::checkFlag( name, flagMapSt, self) )
	  return rosAFE_pause_waitRelease;  
  
  /* Rising the flag (if any) */
  SM::riseFlag ( name, flagMapSt, self );
  				
  // ALL childs are done
  return rosAFE_release;
}

/** Codel releasePreProc of activity PreProc.
 *
 * Triggered by rosAFE_release.
 * Yields to rosAFE_pause_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
releasePreProc(const char *name, rosAFE_ids *ids,
               rosAFE_flagMap **newDataMapSt,
               const rosAFE_preProcPort *preProcPort,
               genom_context self)
{
  std::shared_ptr < PreProc > thisProcessor = ids->preProcessorsSt->processorsAccessor.getProcessor ( name );
  thisProcessor->releaseChunk( );
  
  PORT::publishPreProcPort ( name, preProcPort, thisProcessor->getLeftLastChunkAccessor(), thisProcessor->getRightLastChunkAccessor(), sizeof(double), thisProcessor->getNFR(), self );

  // Informing all the potential childs to say that this is a new chunk.
  SM::riseFlag ( name, newDataMapSt, self );
    
  thisProcessor.reset();
  return rosAFE_pause_waitExec;
}

/** Codel deletePreProc of activity PreProc.
 *
 * Triggered by rosAFE_delete.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
deletePreProc(const char *name, rosAFE_preProcessors **preProcessorsSt,
              const rosAFE_preProcPort *preProcPort,
              genom_context self)
{
  /* Delting the processor */
  ((*preProcessorsSt)->processorsAccessor).removeProcessor( name );
  PORT::deletePreProcPort ( name, preProcPort, self );
 
  return rosAFE_ether;
}

/** Codel stopPreProc of activity PreProc.
 *
 * Triggered by rosAFE_stop.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
stopPreProc(rosAFE_preProcessors **preProcessorsSt,
            genom_context self)
{
  ((*preProcessorsSt)->processorsAccessor).clear();
  
  delete (*preProcessorsSt);
  
  return rosAFE_ether;
}
