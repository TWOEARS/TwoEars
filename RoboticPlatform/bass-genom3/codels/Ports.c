/* Copyright (c) 2014, LAAS/CNRS
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <string.h>
#include <sys/time.h>

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
    struct timeval timeNow;

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

    // http://docs.ros.org/indigo/api/rostime/html/src_2time_8cpp_source.html
    // Lines 108 to 111.
    gettimeofday(&timeNow, NULL);
    data->stamp.sec = timeNow.tv_sec;
    data->stamp.nsec = timeNow.tv_usec*1000;
    
    Audio->write(self);
    return 0;
}


