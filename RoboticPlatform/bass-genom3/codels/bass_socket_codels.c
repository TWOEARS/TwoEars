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
#include "acbass.h"

#include "bass_c_types.h"

#include "Sockets.h"


int yes=1;
int numfds = 0;
int max_fd = 0;
int fd_index, i, end=0;


/* --- Task socket ------------------------------------------------------ */


/** Codel sInitModule of task socket.
 *
 * Triggered by bass_start.
 * Yields to bass_ether.
 */
genom_event
sInitModule(genom_context self)
{
    end = 1;
    return bass_ether;
}


/* --- Activity DedicatedSocket ----------------------------------------- */

/** Codel initModule of activity DedicatedSocket.
 *
 * Triggered by bass_start.
 * Yields to bass_ether, bass_recv.
 */
genom_event
initModule(const bass_Audio *Audio, genom_context self)
{
    uint32_t i;
	server_sockfd = socket(AF_INET, SOCK_STREAM, 0);
    
	if(server_sockfd < 0)
	{
		printf("ERROR: Socket not opened.\n");
		return bass_ether;	
	}	
	printf("Socket opened.\n");
	bzero((char *)&serv_addr, sizeof(serv_addr));
	portno = 8081;
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = INADDR_ANY;
	serv_addr.sin_port = htons(portno);


	if (setsockopt(server_sockfd,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1) 
	{
		printf("ERROR: setsockopt.\n");
		return bass_ether;
	} 

	if(bind(server_sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
	{
		printf("Error binding.\n");
		close(server_sockfd);
		return bass_ether;
	}
	printf("Bind correctly\n");
    
    listen(server_sockfd, 5); /*5 connections allowed on the incoming queue*/

    fd_set writefds, read_fds;
    struct timeval timeout;
    timeout.tv_usec = 5000; 
    FD_ZERO(&writefds);
    FD_SET(client_sockfd, &writefds);
    
    numfds = 0;
    memset(poll_set, '\0', sizeof(poll_set));
    poll_set[numfds].fd = server_sockfd;
    poll_set[numfds].events = POLLIN;
    numfds++;
    max_fd = server_sockfd;

    end = 0;

    sizeofMessage = 2*(Audio->data(self)->nChunksOnPort*Audio->data(self)->nFramesPerChunk)*sizeof(int32_t);
    message = malloc(sizeofMessage);

    messageInfo = malloc(infoSize*sizeof(int32_t));

    return bass_recv;
}

/** Codel Transfer of activity DedicatedSocket.
 *
 * Triggered by bass_recv.
 * Yields to bass_recv, bass_ether.
 */
genom_event
Transfer(const bass_Audio *Audio, genom_context self)
{
    int64_t nfr;
    int N, loss, nFrames;
    int32_t *l, *li, *r, *ri;
    binaudio_portStruct *data;

    if(end==0)
    { 
        poll(poll_set, numfds, 10);

        for(fd_index=0; fd_index<numfds; fd_index++)
        {
            if(poll_set[fd_index].revents & POLLIN)
            {
                printf("[%d] received event POLLIN - fd_index %d \n",  poll_set[fd_index].fd, fd_index);
                if(poll_set[fd_index].fd == server_sockfd)
                {
                    clilen = sizeof(cli_addr); 
                    client_sockfd = accept(server_sockfd, (struct sockaddr *)&cli_addr, &clilen);
                    poll_set[numfds].fd = client_sockfd;
                    poll_set[numfds].events = POLLIN;
                    printf("New client [%d] added\n", poll_set[numfds].fd);
                    numfds++;
                    printf("[After adding new client] fd_index: %d - numfds: %d\n", fd_index, numfds);
                    printf("Current connections: ");
                    for(i=0; i<numfds; i++)
                        printf("%d ", poll_set[i].fd);   
                    printf("\n");   
                    break;              
                }
                else
                {
                    n = read(poll_set[fd_index].fd, buffer, MessageBufferSize-1);
                    if(n == 0)
                    {
                        close(poll_set[fd_index].fd);
                        poll_set[fd_index].events = 0;
                        printf("Removing client [%d]\n", poll_set[fd_index].fd);
                        poll_set[fd_index] = poll_set[numfds-1];      
                        numfds--;
                        printf("[After Removing] fd_index: %d - numfds: %d\n", fd_index, numfds);
                        printf("Current connections: ");
                        for(i=0; i<numfds; i++)
                            printf("%d ", poll_set[i].fd);  
                        printf("\n");              
                    }
                    else
                    {
                        printf("\nMessage received from [%d]: %s",poll_set[fd_index].fd, buffer);

                        if(strstr(buffer, "Read Port"))
                        {
                            /* Get the values sent by the client */
                            N = (int) findValue(buffer, "N");   /*The casting is because findValue returns int64_t and N is int*/
                            nfr = findValue(buffer, "nfr");
                            if(N>=0 && nfr>=0)
                            {
                                /* Read data from the port */
                                data = Audio->data(self);

                                nFrames = getAudioData(data, message, N, &nfr, &loss);

                                /*Send information related to Data*/
                                messageInfo[0] = nFrames;
                                messageInfo[1] = loss;
                                messageInfo[2] = (int32_t) nfr; // get the low 32 bits
                                messageInfo[3] = (nfr >> 32);   // get the high 32 bits
                                SocketSend(poll_set[fd_index].fd, messageInfo, infoSize);
                       
                                /*Send Data*/
                                SocketSend(poll_set[fd_index].fd, message, (2*nFrames));                               
                            }
                        }                       
                    }
                }
            }
        }
        return bass_recv;
    }
    else
        return bass_ether;
}


/* --- Activity CloseSocket --------------------------------------------- */

/** Codel closeSocket of activity CloseSocket.
 *
 * Triggered by bass_start.
 * Yields to bass_ether.
 */
genom_event
closeSocket(genom_context self)
{
    end = 1;
    free(message);
    free(messageInfo);
    for(i=0; i<numfds; i++)
        close(poll_set[i].fd);
    printf("Connections closed.\n"); 
        
    return bass_ether;
}
