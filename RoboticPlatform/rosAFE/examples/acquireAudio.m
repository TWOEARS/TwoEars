function [ ] = acquireAudio( bass, rosAFE, sampleRate, bufferSize_s_bass, nFramesPerChunk, inputDevice )

    nChunksOnPort = sampleRate * bufferSize_s_bass / nFramesPerChunk;

    %% Acquiring Audio
    acquire = bass.Acquire('-a', inputDevice, sampleRate, nFramesPerChunk, nChunksOnPort);
    pause(0.2);
    if ( strcmp(acquire.status,'error') )
       error(strcat('Error',acquire.exception.ex));
    end

    %% Connecting rosAFE to BASS
    connection = rosAFE.connect_port('Audio', 'bass/Audio');
    pause(0.2);
    if ( strcmp(connection.status,'error') )
        error(strcat('Error',connection.exception.ex));
    end

end