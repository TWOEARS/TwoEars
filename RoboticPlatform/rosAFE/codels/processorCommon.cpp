#include "processorCommon.hpp"

    genom_event
    PC::execAnyProc( const char *nameProc, rosAFE_ids *ids, genom_context self ) {
		
	  if ( ids->preProcessorsSt->processorsAccessor.getProcessor ( nameProc ) ) {
		ids->preProcessorsSt->processorsAccessor.getProcessor ( nameProc )->processChunk( );
		return genom_ok;
	  }
	  if ( ids->gammatoneProcessorsSt->processorsAccessor.getProcessor ( nameProc ) ) {
		ids->gammatoneProcessorsSt->processorsAccessor.getProcessor ( nameProc )->processChunk( );
		return genom_ok;
	  }
	  if ( ids->ihcProcessorsSt->processorsAccessor.getProcessor ( nameProc ) ) {
		ids->ihcProcessorsSt->processorsAccessor.getProcessor ( nameProc )->processChunk( );
		return genom_ok;
	  }
	  if ( ids->ildProcessorsSt->processorsAccessor.getProcessor ( nameProc ) ) {
		ids->ildProcessorsSt->processorsAccessor.getProcessor ( nameProc )->processChunk( );
		return genom_ok;
	  }		
		return rosAFE_e_noSuchProcessor(self);
	}
	
	genom_event
	PC::releaseAnyProc( const char *nameProc, rosAFE_ids *ids, genom_context self ) {
				
	  if ( ids->preProcessorsSt->processorsAccessor.getProcessor ( nameProc ) ) {
		preProcPtr thisProcessor = ids->preProcessorsSt->processorsAccessor.getProcessor ( nameProc );
		
		thisProcessor->appendChunk( );
		thisProcessor->calcLastChunk( );
  
		thisProcessor.reset();
		return genom_ok;
	  }
	  if ( ids->gammatoneProcessorsSt->processorsAccessor.getProcessor ( nameProc ) ) {
		gammatoneProcPtr thisProcessor = ids->gammatoneProcessorsSt->processorsAccessor.getProcessor ( nameProc );
		
		thisProcessor->appendChunk( );
		thisProcessor->calcLastChunk( );
  
		thisProcessor.reset();
		return genom_ok;
	  }
	  if ( ids->ihcProcessorsSt->processorsAccessor.getProcessor ( nameProc ) ) {
		ihcProcPtr thisProcessor = ids->ihcProcessorsSt->processorsAccessor.getProcessor ( nameProc );
		
		thisProcessor->appendChunk( );
		thisProcessor->calcLastChunk( );
  
		thisProcessor.reset();
		return genom_ok;
		}
	  if ( ids->ildProcessorsSt->processorsAccessor.getProcessor ( nameProc ) ) {
		ildProcPtr thisProcessor = ids->ildProcessorsSt->processorsAccessor.getProcessor ( nameProc );
		
		thisProcessor->appendChunk( );
		thisProcessor->calcLastChunk( );
  
		thisProcessor.reset();
		return genom_ok;
	  }				
				
	  return rosAFE_e_noSuchProcessor(self);		
				
	}	
