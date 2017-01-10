function [ chunkLeft chunkRight ] = adaptTFS( framesOnPort, numberOfChannels, left, isBinaural, right )
%adaptTFS [ chunkLeft chunkRight ] = adaptTFS( framesOnPort, numberOfChannels, left, isBinaural, right )
%   Adapts a the incoming RosAFE style TimeFrequenctSignal signal to Matlab
%   AFE style TimeFrequenctSignal

	chunkLeft = zeros(framesOnPort, numberOfChannels);
    if ( isBinaural )
        chunkRight = zeros( size(chunkLeft) ); 
    end
    
    if ( isBinaural )
        for jj = 1:numberOfChannels
            chunkLeft(:,jj) = cell2mat(left.dataN{jj}.data)';
            chunkRight(:,jj) = cell2mat(right.dataN{jj}.data)';
        end
    else
        for jj = 1:numberOfChannels
            chunkLeft(:,jj) = cell2mat(left.dataN{jj}.data)';
        end
    end
 end

