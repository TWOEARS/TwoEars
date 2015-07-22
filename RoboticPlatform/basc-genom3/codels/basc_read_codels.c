/*
 * Copyright (c) 2014 LAAS/CNRS
 * All rights reserved.
 *
 * Redistribution  and  use  in  source  and binary  forms,  with  or  without
 * modification, are permitted provided that the following conditions are met:
 *
 *   1. Redistributions of  source  code must retain the  above copyright
 *      notice and this list of conditions.
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice and  this list of  conditions in the  documentation and/or
 *      other materials provided with the distribution.
 *
 * THE SOFTWARE  IS PROVIDED "AS IS"  AND THE AUTHOR  DISCLAIMS ALL WARRANTIES
 * WITH  REGARD   TO  THIS  SOFTWARE  INCLUDING  ALL   IMPLIED  WARRANTIES  OF
 * MERCHANTABILITY AND  FITNESS.  IN NO EVENT  SHALL THE AUTHOR  BE LIABLE FOR
 * ANY  SPECIAL, DIRECT,  INDIRECT, OR  CONSEQUENTIAL DAMAGES  OR  ANY DAMAGES
 * WHATSOEVER  RESULTING FROM  LOSS OF  USE, DATA  OR PROFITS,  WHETHER  IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR  OTHER TORTIOUS ACTION, ARISING OUT OF OR
 * IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#include "acbasc.h"

#include "basc_c_types.h"

#include <stdio.h>
#include <stdint.h>


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

int getAudioData(binaudio_portStruct *src, int32_t *destL, int32_t *destR,
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


/* --- Task read -------------------------------------------------------- */


/* --- Activity GetBlocks ----------------------------------------------- */

/* Variables shared between the codels (they could go in the IDS) */
static int N;
static int64_t nfr;
static int32_t *l, *li, *r, *ri;

/** Codel startGetBlocks of activity GetBlocks.
 *
 * Triggered by basc_start.
 * Yields to basc_exec.
 * Throws basc_e_noData.
 */
genom_event
startGetBlocks(uint32_t nFramesPerBlock, int32_t startOffs,
               const basc_Audio *Audio, genom_context self)
{
    /* Check if the client can get data from the server */
    Audio->read(self);
    if (Audio->data(self) == NULL) {
        printf("The server is not streaming or the port is not connected.\n");
        return basc_e_noData(self);
    }

    /* Initialization */
    N = nFramesPerBlock; //N is the amount of frames the client requests
    nfr = startOffs + Audio->data(self)->lastFrameIndex + 1;
    l = malloc(N * sizeof(int32_t)); //l and r are arrays containing the
    r = malloc(N * sizeof(int32_t)); //current block of data
    li = l; ri = r; //li and ri point to the current position in the block

    return basc_exec;
}

/** Codel execGetBlocks of activity GetBlocks.
 *
 * Triggered by basc_exec.
 * Yields to basc_exec, basc_stop.
 * Throws basc_e_noData.
 */
genom_event
execGetBlocks(uint32_t *nBlocks, uint32_t nFramesPerBlock,
              const basc_Audio *Audio, genom_context self)
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
    printf("Requested %6d frames, got %6d.\n", N, n);
    N -= n; li += n; ri += n;

    /* The client deals with data loss here */
    if (loss > 0) printf("!!Lost %d frames!!\n", loss);

    /* If the current block is not complete, call getAudioData again
       to request the remaining part */
    if (N > 0) return basc_exec;

    /* The current block is complete. Reset N, li and ri for next block */
    N = nFramesPerBlock; li = l; ri = r;

    /* The client processes the current block l and r here */
    printf("A new block is ready to be processed.\n");

    if (*nBlocks == 0) return basc_exec;
    if (--*nBlocks > 0) return basc_exec;
    return basc_stop;
}

/** Codel stopGetBlocks of activity GetBlocks.
 *
 * Triggered by basc_stop.
 * Yields to basc_ether.
 * Throws basc_e_noData.
 */
genom_event
stopGetBlocks(genom_context self)
{
    free(l); l = NULL;
    free(r); r = NULL;
    return basc_ether;
}
