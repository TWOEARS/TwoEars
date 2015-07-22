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
#include "acbass.h"

#include "bass_c_types.h"

#include <stdio.h>
#include <stdint.h>
#include "AudioCapture.h"
#include "Ports.h"

/* --- Task capture ----------------------------------------------------- */

/* --- Activity Acquire ------------------------------------------------- */

/** Codel startAcquire of activity Acquire.
 *
 * Triggered by bass_start.
 * Yields to bass_exec, bass_ether.
 * Throws bass_e_nomem, bass_e_device, bass_e_hwparams,
 * bass_e_swparams.
 */
genom_event
startAcquire(const char *device, uint32_t sampleRate,
             uint32_t nFramesPerChunk, uint32_t nChunksOnPort,
             bass_ids *ids, const bass_Audio *Audio,
             genom_context self)
{
    int err;

    /* Prepare the Port */
    if ((err = initPort(Audio, sampleRate, nFramesPerChunk, nChunksOnPort,
                        self)) < 0)
        return_bass_exception(err);

    /* Start the capture */
    initCapture(&(ids->cap), device, sampleRate, nFramesPerChunk);
    if ((err = createCapture(ids->cap)) < 0) {
        endCapture(&(ids->cap));
        return_bass_exception(err);
    }

    return bass_exec;
}

/** Codel execAcquire of activity Acquire.
 *
 * Triggered by bass_exec.
 * Yields to bass_exec, bass_stop.
 * Throws bass_e_nomem, bass_e_device, bass_e_hwparams,
 * bass_e_swparams.
 */
genom_event
execAcquire(bass_ids *ids, const bass_Audio *Audio,
            genom_context self)
{
    int err;

    /* Get the data */
    if ((err = runCapture(ids->cap)) < 0) {
        endCapture(&(ids->cap));
        return_bass_exception(err);
    }

    /* Publish the data on the Port */
    publishPort(Audio, ids->cap, self);
    return bass_exec;
}

/** Codel stopAcquire of activity Acquire.
 *
 * Triggered by bass_stop.
 * Yields to bass_ether.
 * Throws bass_e_nomem, bass_e_device, bass_e_hwparams,
 * bass_e_swparams.
 */
genom_event
stopAcquire(bass_ids *ids, genom_context self)
{
    endCapture(&(ids->cap));
    return bass_ether;
}
