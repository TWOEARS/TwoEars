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

#ifndef SOCKETS_H
#define SOCKETS_H

#include "bass_c_types.h"

#include <stdint.h>
#include <string.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/poll.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <errno.h>

#define MessageBufferSize	512
#define POLL_SIZE           32
#define infoSize            4   //int32_t x2 and int64_t x1 => int32_t xinfoSize

int server_sockfd, client_sockfd, portno, clilen, n;
char buffer[MessageBufferSize];
int32_t *message, *messageInfo;
int64_t sizeofMessage;



struct sockaddr_in serv_addr, cli_addr;
struct pollfd poll_set[POLL_SIZE];

int64_t findValue(char *buffer, char *value);
int getAudioData(binaudio_portStruct *src, int32_t *dest,
                 int N, int64_t *nfr, int *loss);
void SocketSend(int fd, int32_t *buffer, int length);

#endif /* SOCKETS_H */
