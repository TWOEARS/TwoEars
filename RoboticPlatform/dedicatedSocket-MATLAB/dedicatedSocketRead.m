function [n, loss, nfr, data] = dedicatedSocketRead(N, nfr)
%function [data] = dedicatedSocketRead(port)
global dedicatedSocket;

fprintf(dedicatedSocket.p, sprintf('Read Port - N %d - nfr %d', N, nfr));
        

%Wait for the first four bytes which contain the number of blocks to read.
while(dedicatedSocket.p.BytesAvailable<4)
end
message=fread(dedicatedSocket.p, 16);
n = message(1) + message(2)*256 + message(3)*65536 + message(4)*16777216;
dedicatedSocket.bytes = n*2*4;
loss = message(5) + message(6)*256 + message(7)*65536 + message(8)*16777216;
nfr = 0;
for i=0:7
    nfr = nfr + message(9+i)*power(256, i);
end

while(dedicatedSocket.p.BytesAvailable<dedicatedSocket.bytes)
end
message=fread(dedicatedSocket.p, dedicatedSocket.bytes);
[audio.left, audio.right, audio.output] = conversionBinaryMex(message);

%framesAvailable = blocksAvailable*periodSize;
framesAvailable=length(audio.left);
data.left = zeros(framesAvailable, 1);
data.right = zeros(framesAvailable, 1);
data.output = zeros(framesAvailable, 2);

%data.left = audio.left((end-framesAvailable+1):end);
%data.right = audio.right((end-framesAvailable+1):end);
%data.output(:, 1) = audio.output((end-framesAvailable+1):end,1);
%data.output(:, 2) = audio.output((end-framesAvailable+1):end,2);
data.left = audio.left;
data.right = audio.right;
data.output(:, 1) = audio.output(:, 1);
data.output(:, 2) = audio.output(:, 2);
end