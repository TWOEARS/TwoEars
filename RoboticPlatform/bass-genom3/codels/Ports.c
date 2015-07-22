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

#include <string.h>

#include "Ports.h"
#include "bass_c_types.h"
#include "AudioCapture.h"

/* initPort ----------------------------------------------------------------- */

int initPort(const bass_Audio *Audio, uint32_t sampleRate,
             uint32_t nFramesPerChunk, uint32_t nChunksOnPort,
             genom_context self)
{
    uint32_t fop; /* total amount of Frames On the Port */
    int ii;

    fop =  nFramesPerChunk * nChunksOnPort;
    if (genom_sequence_reserve(&(Audio->data(self)->left), fop) ||
        genom_sequence_reserve(&(Audio->data(self)->right), fop))
        return -E_NOMEM;

    Audio->data(self)->left._length = fop;
    Audio->data(self)->right._length = fop;

    for (ii = 0; ii < fop; ii++) {
        Audio->data(self)->left._buffer[ii] = 0;
        Audio->data(self)->right._buffer[ii] = 0;
    }
    Audio->data(self)->sampleRate = sampleRate;
    Audio->data(self)->nChunksOnPort = nChunksOnPort;
    Audio->data(self)->nFramesPerChunk = nFramesPerChunk;
    Audio->data(self)->lastFrameIndex = 0;
    Audio->write(self);
    return 0;
}

/* publishPort ------------------------------------------------------------- */

int publishPort(const bass_Audio *Audio, bass_captureStruct *cap,
                genom_context self)
{
    binaudio_portStruct *data;
    uint32_t fpc; /* amount of Frames Per Chunk */
    uint32_t fop; /* total amount of Frames On the Port */
    uint32_t bps; /* amout of Bytes Per Sample */
    int pos, ii;

    data = Audio->data(self);
    fpc = data->nFramesPerChunk;
    fop = fpc * data->nChunksOnPort;
    bps = cap->nBytesPerSample;

    memmove(data->left._buffer, data->left._buffer + fpc, (fop - fpc)*bps);
    memmove(data->right._buffer, data->right._buffer + fpc, (fop - fpc)*bps);

    /*   **1**  **2**  **3**  **4**  **5** **6**   */
    /*   | <-   |                          |new    */
    /*   memmove                          for loop */
    /*   **2**  **3**  **4**  **5**  **6** **7**   */

    for (ii = 0, pos = fop - fpc; pos < fop; ii++, pos++) {
        data->left._buffer[pos] = cap->buff[cap->channels*ii];
        data->right._buffer[pos] = cap->buff[cap->channels*ii + 1];
    }

    data->lastFrameIndex += fpc;
    Audio->write(self);
    return 0;
}


