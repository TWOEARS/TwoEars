#include "acrosAFE.h"
#include "rosAFE_c_types.h"

#include "genom3_dataFiles.hpp"
#include "stateMachine.hpp"
#include "Ports.hpp"

#include <cmath>
/* --- getAudioData ----------------------------------------------------- */

/* This function takes samples from the structure pointed by src
   (input data from the server's port), and copies them at the
   locations pointed by destL and destR. Note that destL and destR
   should point to allocated memory.
   It copies N samples at most from each channel (left and right
   sequence members of *src), starting at the index *nfr (next frame
   to read).
   The return value n is the amount of samples that the function was
   actually able to get (n <= N).
   If loss is not NULL, the function stores the amount of frames that
   were lost in *loss (*loss equals 0 if no loss).
 */

int
getAudioData(binaudio_portStruct *src, double *destL, double *destR,
                 int N, int64_t *nfr, int *loss)
{
    int n;       /* amount of frames the function will be able to get */
    int fop;     /* total amount of Frames On the Port */
    int64_t lfi; /* Last Frame Index on the port */
    int64_t ofi; /* Oldest Frame Index on the port */
    int pos;     /* current position in the data arrays */

    fop = src->nFramesPerChunk * src->nChunksOnPort;
    lfi = src->lastFrameIndex;
    ofi = (lfi-fop+1 < 0 ? 0 : lfi-fop+1);

    /* Detect a data loss */
    if (loss) *loss = 0;
    if (*nfr < ofi) {
        if (loss) *loss = ofi - *nfr;
        *nfr = ofi;
    }

    /* Compute the starting position in the left and right input arrays */
    pos = fop - (lfi - *nfr + 1);

    /* Fill the output arrays l and r */
    for (n = 0; n < N && pos < fop; ++n, ++pos, ++*nfr) {
        destL[n] = src->left._buffer[pos];
        destR[n] = src->right._buffer[pos];
    }

    return n;
}


/* Variables shared between the codels (they could go in the IDS) */
static int N;
static unsigned int globalLoss;
static int64_t nfr;
static double *li, *ri;
std::vector<double> l, r;


/* --- Task input ------------------------------------------------------- */

/* --- Activity InputProc ----------------------------------------------- */

/** Codel startInputProc of activity InputProc.
 *
 * Triggered by rosAFE_start.
 * Yields to rosAFE_waitExec.
 * Throws rosAFE_e_noData, rosAFE_e_noMemory, rosAFE_e_existsAlready.
 */
genom_event
startInputProc(const char *name, uint32_t nFramesPerBlock,
               double bufferSize_s_port, double bufferSize_s_getSignal,
               rosAFE_inputProcessors **inputProcessorsSt,
               const rosAFE_Audio *Audio, rosAFE_infos *infos,
               const rosAFE_inputProcPort *inputProcPort,
               genom_context self)
{	
  /* Check if the client can get data from the server */
  Audio->read(self);
  if (Audio->data(self) == NULL) {
      printf("The server is not streaming or the port is not connected.\n");
      return rosAFE_e_noData(self);
  }
  
  infos->sampleRate = Audio->data(self)->sampleRate;
  infos->bufferSize_s_port = bufferSize_s_port;
  
  // infos->bufferSize_s_getSignal can't be less than 2 times nFramesPerBlock
  double tmp = nFramesPerBlock * 2 / infos->sampleRate;
  infos->bufferSize_s_getSignal = ( bufferSize_s_getSignal < tmp ? tmp : bufferSize_s_getSignal );
    
  std::shared_ptr< InputProc > inputP ( new InputProc( name, infos->sampleRate, infos->bufferSize_s_getSignal, true ) );
  
  /* Adding this procesor to the ids */
  ((*inputProcessorsSt)->processorsAccessor).addProcessor( inputP );
  
  /* Initialization */
  N = nFramesPerBlock; //N is the amount of frames the client requests
  nfr = Audio->data(self)->lastFrameIndex + 1;
  l.resize(N, 0); // l and r are arrays containing the
  r.resize(N, 0); // current block of data

  li = l.data(); ri = r.data(); // li and ri point to the current position in the block

  /* Initialization of the output port */
  PORT::initInputPort( inputProcPort, infos->sampleRate, infos->bufferSize_s_port, self );

  globalLoss = 0;
  
  inputP.reset();   
  return rosAFE_waitExec;
}

/** Codel waitExecInputProc of activity InputProc.
 *
 * Triggered by rosAFE_waitExec.
 * Yields to rosAFE_pause_waitExec, rosAFE_exec, rosAFE_stop.
 * Throws rosAFE_e_noData, rosAFE_e_noMemory, rosAFE_e_existsAlready.
 */
genom_event
waitExecInputProc(uint32_t nFramesPerBlock, const rosAFE_Audio *Audio,
                  genom_context self)
{
    binaudio_portStruct *data;
    int n, loss;
    
    /* Read data from the input port */
    Audio->read(self);
    data = Audio->data(self);

    /* Get N frames from the Audio port. getAudioData returns the
       amount of frames n it was actually able to get. The amount N
       required by the client is updated, as well as li and ri */
    n = getAudioData(data, li, ri, N, &nfr, &loss);
    // printf("Requested %6d frames, got %6d.\n", N, n);
    N -= n; li += n; ri += n;

    /* The client deals with data loss here */
    // if (loss > 0) printf("!!Lost %d frames!!\n", loss);
	globalLoss += loss;
    /* If the current block is not complete, call getAudioData again
       to request the remaining part */
    if (N > 0) return rosAFE_pause_waitExec;

    /* The current block is complete. Reset N, li and ri for next block */
    N = nFramesPerBlock; li = l.data(); ri = r.data();
    
    if ( ( globalLoss >= l.size() ) || ( globalLoss >= r.size() ) ) {
	/* Everythink is lost */
		globalLoss = 0;		
		return rosAFE_pause_waitExec;
	}

    return rosAFE_exec;
}

/** Codel execInputProc of activity InputProc.
 *
 * Triggered by rosAFE_exec.
 * Yields to rosAFE_waitRelease, rosAFE_stop.
 * Throws rosAFE_e_noData, rosAFE_e_noMemory, rosAFE_e_existsAlready.
 */
genom_event
execInputProc(const char *name,
              rosAFE_inputProcessors **inputProcessorsSt,
              genom_context self)
{
  // The client processes the current block l and r here
  (((*inputProcessorsSt)->processorsAccessor).getProcessor( name ))->processChunk( l.data(), l.size() - globalLoss, r.data(), r.size() - globalLoss);
  globalLoss = 0;
    
  return rosAFE_waitRelease;
}

/** Codel waitReleaseInputProc of activity InputProc.
 *
 * Triggered by rosAFE_waitRelease.
 * Yields to rosAFE_pause_waitRelease, rosAFE_release, rosAFE_stop.
 * Throws rosAFE_e_noData, rosAFE_e_noMemory, rosAFE_e_existsAlready.
 */
genom_event
waitReleaseInputProc(const char *name, rosAFE_flagMap **flagMapSt,
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

/** Codel releaseInputProc of activity InputProc.
 *
 * Triggered by rosAFE_release.
 * Yields to rosAFE_pause_waitExec, rosAFE_stop.
 * Throws rosAFE_e_noData, rosAFE_e_noMemory, rosAFE_e_existsAlready.
 */
genom_event
releaseInputProc(const char *name,
                 rosAFE_inputProcessors **inputProcessorsSt,
                 rosAFE_flagMap **newDataMapSt,
                 const rosAFE_inputProcPort *inputProcPort,
                 genom_context self)
{
  std::shared_ptr< InputProc > thisProcessor = ((*inputProcessorsSt)->processorsAccessor).getProcessor( name );
 
  // Relasing the data
  thisProcessor->releaseChunk( );
  thisProcessor->setNFR ( nfr );
  
  // Publishing on the output port
  PORT::publishInputPort ( inputProcPort, thisProcessor->getLeftLastChunkAccessor(), thisProcessor->getRightLastChunkAccessor(), sizeof(double), nfr, self );
  
  
  // Informing all the potential childs to say that this is a new chunk.
  SM::riseFlag ( name, newDataMapSt, self );
    
  thisProcessor.reset();
  return rosAFE_pause_waitExec;
}

/** Codel stopInputProc of activity InputProc.
 *
 * Triggered by rosAFE_stop.
 * Yields to rosAFE_ether.
 * Throws rosAFE_e_noData, rosAFE_e_noMemory, rosAFE_e_existsAlready.
 */
genom_event
stopInputProc(const char *name,
              rosAFE_inputProcessors **inputProcessorsSt,
              rosAFE_flagMap **flagMapSt,
              rosAFE_flagMap **newDataMapSt, genom_context self)
{
	l.clear(); r.clear();
		
	// Deleting all flags
    (*flagMapSt)->allFlags.clear();
    (*newDataMapSt)->allFlags.clear();
	
	delete (*flagMapSt);
	delete (*newDataMapSt);
	
	((*inputProcessorsSt)->processorsAccessor).removeProcessor( name );
	((*inputProcessorsSt)->processorsAccessor).clear();
	delete (*inputProcessorsSt);

    return rosAFE_ether;
}
