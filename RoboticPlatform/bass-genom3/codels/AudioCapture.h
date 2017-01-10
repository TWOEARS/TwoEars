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

#ifndef AUDIOCAPTURE_H
#define AUDIOCAPTURE_H

#include <alsa/asoundlib.h>
#include <stdint.h>
#include "bass_c_types.h"

/* size of the alsa ring buffer in number of chunks */
#define ARBSIZE_ON_CHUNKSIZE (3)

struct bass_captureStruct
{
    snd_pcm_stream_t stream;
    snd_pcm_access_t access;
    snd_pcm_format_t format; /* sample format */
    unsigned int nBytesPerSample;
    unsigned int channels; /* count of channels */
    snd_pcm_t *handle;
    char *device;
    int32_t *buff; /* buffer to store the transfer chunk (same type as
                      expected data type on the port) */
    unsigned int rate ; /* stream rate */
    snd_pcm_uframes_t chunkSize; /* Size of transfer chunks in frames */
    snd_pcm_uframes_t arbSize; /* Size of the alsa ring buffer in frames */
    snd_pcm_hw_params_t *hwparams;
    snd_pcm_sw_params_t *swparams;
};

enum {E_NOMEM = 1, E_NODEVICE, E_DEVICE, E_HWPARAMS, E_SWPARAMS};

#define return_bass_exception(err)                           \
  do {                                                       \
    genom_event g;                                           \
    switch (err) {                                           \
      case -E_NOMEM: g = bass_e_nomem(self); break;          \
      case -E_NODEVICE: g = bass_e_nodevice(self); break;    \
      case -E_DEVICE: g = bass_e_device(self); break;        \
      case -E_HWPARAMS: g = bass_e_hwparams(self); break;    \
      case -E_SWPARAMS: g = bass_e_swparams(self); break;    \
    }                                                        \
    return g;                                                \
  } while(0)

int listCaptureDevices(void);
int initCapture(bass_captureStruct **pcap, const char *device,
                uint32_t sampleRate, uint32_t nFramesPerChunk);
int createCapture(bass_captureStruct *cap);
int setHwparams(bass_captureStruct *cap);
int setSwparams(bass_captureStruct *cap);
int runCapture(bass_captureStruct *cap);
int endCapture(bass_captureStruct **pcap);

#endif /* AUDIOCAPTURE_H */

