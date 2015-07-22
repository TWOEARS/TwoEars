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

#include "Sockets.h"

/* findValue ----------------------------------------------------------------- */

/* This function searches for the 'string' in 'buffer'. If it's found, 
   the number that follows is retrieved. */

int64_t findValue(char *buffer, char *string)
{
    int i=0, j, len=0;
    int32_t pow, auxpow;
    char *startPosition;
    int64_t value=-1;

    startPosition = strstr(buffer, string);
    if(startPosition != NULL)
    {
        startPosition = startPosition  + strlen(string) + 1;
        while(startPosition[i]>=48 && startPosition[i]<=57)
        {
            i++;
        }
        len = i;
        auxpow = len-1;
        value = 0;
        for(i=0; i<len; i++)
        {
            pow = 1;
            for(j=0; j<auxpow; j++)
            {
                pow = pow*10;
            }
            auxpow--;
            value = value + (startPosition[i]-48)*pow;
        }
    }
    return value;
}

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

int getAudioData(binaudio_portStruct *src, int32_t *dest,
                 int N, int64_t *nfr, int *loss)
{
    int n;       /* amount of frames the function will be able to get */
    int fop;     /* total amount of Frames On the Port */
    int64_t lfi; /* Last Frame Index on the port */
    int64_t ofi; /* Oldest Frame Index on the port */
    int pos;     /* current position in the data arrays */
    int i;

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
    n = (fop - pos < N ? fop - pos : N);
    for (i = 0; i < n ; i++, ++pos, ++*nfr) {
        dest[i] = src->left._buffer[pos];
        dest[i+n] = src->right._buffer[pos];
    }

    return n;
}

/* --- getAudioData ----------------------------------------------------- */

/* This function sends the 'buffer' over the file descriptor 'fd' (Socket communication) */

void SocketSend(int fd, int32_t *buffer, int length)
{
    int i, n;
    uint32_t total=0;
    int32_t *aux;
    int good=0, bad=0;

    aux = malloc(length*sizeof(int32_t));

    n = send(fd, buffer, length*sizeof(int32_t), NULL);

    if(n>0)
    {
        good++;
        printf("SENT: n = %d bytes (%d samples)\n", n, n/4);
    }
    total = n/4;
    while(total<length)
    {
        for(i=0; i<(length-total); i++)
        {
            aux[i] = buffer[total+i];
        }
        n = send(fd, aux, i*sizeof(int32_t), NULL);
        if(n>0)
        {
            good++;
            total = total + n/4;
            printf("SENT: n = %d bytes (%d samples)\tTOTAL: n = %d bytes (%d samples)\n", n, n/4, total*4, total);
        }
        else
            bad++;
    }

    free(aux);
    return 0;
}
