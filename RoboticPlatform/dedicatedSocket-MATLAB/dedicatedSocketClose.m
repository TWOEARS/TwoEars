function dedicatedSocketClose()
global dedicatedSocket;

fprintf(dedicatedSocket.p, 'Close');

fclose(dedicatedSocket.p);      
end