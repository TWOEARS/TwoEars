#include "acrosAFE.h"
#include "rosAFE_c_types.h"

#include <memory>

#include "genom3_dataFiles.hpp"
#include "stateMachine.hpp"
#include "Ports.hpp"

/* --- Task gammatoneProc ----------------------------------------------- */


/* --- Activity GammatoneProc ------------------------------------------- */

/** Codel startGammatoneProc of activity GammatoneProc.
 *
 * Triggered by rosAFE_start.
 * Yields to rosAFE_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
startGammatoneProc(const char *name, const char *upperDepName,
                   rosAFE_gammatoneProcessors **gammatoneProcessorsSt,
                   rosAFE_flagMap **flagMapSt,
                   rosAFE_flagMap **newDataMapSt,
                   rosAFE_preProcessors **preProcessorsSt,
                   const rosAFE_infos *infos,
                   const rosAFE_gammatonePort *gammatonePort,
                   const char *fb_type, double fb_lowFreqHz,
                   double fb_highFreqHz, double fb_nERBs,
                   uint32_t fb_nChannels,
                   const sequence_double *fb_cfHz, uint32_t fb_nGamma,
                   double fb_bwERBs, genom_context self)
{    
  std::shared_ptr<PreProc > upperDepProc = ((*preProcessorsSt)->processorsAccessor).getProcessor( upperDepName );

  if (!(upperDepProc))
	return rosAFE_e_noUpperDependencie (self);
	
  filterBankType thisBank = _gammatoneFilterBank;
  if ( strcmp( fb_type, "drnl" ) == 0 )
	thisBank = _drnlFilterBank;

  std::shared_ptr < GammatoneProc > gammatoneProcessor (new GammatoneProc( name, upperDepProc,
	thisBank, fb_lowFreqHz, fb_highFreqHz, fb_nERBs, fb_nChannels, fb_cfHz->_buffer, fb_cfHz->_length, fb_nGamma, fb_bwERBs ) );
  
  /* Adding this procesor to the ids */
  ((*gammatoneProcessorsSt)->processorsAccessor).addProcessor( gammatoneProcessor );

  SM::addFlag( name, upperDepName, flagMapSt, self );
  SM::addFlag( name, upperDepName, newDataMapSt, self );

  // Initialization of the output port
  PORT::initGammatonePort( name, gammatonePort, infos->sampleRate, infos->bufferSize_s_port, gammatoneProcessor->get_nChannel(), self );
  
  upperDepProc.reset();
  gammatoneProcessor.reset();
  
  return rosAFE_waitExec;
}

/** Codel waitExec of activity GammatoneProc.
 *
 * Triggered by rosAFE_waitExec.
 * Yields to rosAFE_pause_waitExec, rosAFE_exec, rosAFE_ether,
 *           rosAFE_delete.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel execGammatoneProc of activity GammatoneProc.
 *
 * Triggered by rosAFE_exec.
 * Yields to rosAFE_waitRelease.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
execGammatoneProc(const char *name, const char *upperDepName,
                  rosAFE_ids *ids, rosAFE_flagMap **flagMapSt,
                  genom_context self)
{
  ids->gammatoneProcessorsSt->processorsAccessor.getProcessor ( name )->processChunk( );

  // At the end of this codel, the upperDep will be able to overwite the data.
  SM::fallFlag ( name, upperDepName, flagMapSt, self);
    
  return rosAFE_waitRelease;
}

/** Codel waitRelease of activity GammatoneProc.
 *
 * Triggered by rosAFE_waitRelease.
 * Yields to rosAFE_pause_waitRelease, rosAFE_release, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
/* already defined in service PreProc */


/** Codel releaseGammatoneProc of activity GammatoneProc.
 *
 * Triggered by rosAFE_release.
 * Yields to rosAFE_pause_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
releaseGammatoneProc(const char *name, rosAFE_ids *ids,
                     rosAFE_flagMap **newDataMapSt,
                     const rosAFE_gammatonePort *gammatonePort,
                     genom_context self)
{
  std::shared_ptr < GammatoneProc > thisProcessor = ids->gammatoneProcessorsSt->processorsAccessor.getProcessor ( name );
  thisProcessor->releaseChunk( );
  
  PORT::publishGammatonePort ( name, gammatonePort, thisProcessor->getLeftLastChunkAccessor(), thisProcessor->getRightLastChunkAccessor(), sizeof(double), thisProcessor->getNFR(), self );

  // Informing all the potential childs to say that this is a new chunk.
  SM::riseFlag ( name, newDataMapSt, self );
    
  thisProcessor.reset();
  return rosAFE_pause_waitExec;
}

/** Codel deleteGammatoneProc of activity GammatoneProc.
 *
 * Triggered by rosAFE_delete.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
deleteGammatoneProc(const char *name,
                    rosAFE_gammatoneProcessors **gammatoneProcessorsSt,
                    const rosAFE_gammatonePort *gammatonePort,
                    genom_context self)
{
  /* Delting the processor */
  ((*gammatoneProcessorsSt)->processorsAccessor).removeProcessor( name );
  PORT::deleteGammatonePort ( name, gammatonePort, self );  
  return rosAFE_ether;
}

/** Codel stopGammatoneProc of activity GammatoneProc.
 *
 * Triggered by rosAFE_stop.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noUpperDependencie, rosAFE_e_existsAlready,
 *        rosAFE_e_noSuchProcessor.
 */
genom_event
stopGammatoneProc(rosAFE_gammatoneProcessors **gammatoneProcessorsSt,
                  genom_context self)
{
  ((*gammatoneProcessorsSt)->processorsAccessor).clear();
  
  delete (*gammatoneProcessorsSt);
  
  return rosAFE_ether;
}
