function dedicatedSocketOpen(ip, bytesPerFrame)
global dedicatedSocket;

dedicatedSocket.p = tcpip(ip,8081);
%TODO: Don't allow multiple connections per client.  
if(nargin>1)
    dedicatedSocket.p.InputBufferSize = bytesPerFrame;
else
    dedicatedSocket.p.InputBufferSize = 1048576; %1Mb
end
fopen(dedicatedSocket.p); 
end