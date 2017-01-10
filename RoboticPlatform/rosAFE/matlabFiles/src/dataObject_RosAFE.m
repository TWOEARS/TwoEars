classdef dataObject_RosAFE < dynamicprops
%DATAOBJECT: Signal container class for the auditory front-end (AFE) framework.
%   A data object is necessary for running the AFE framework. It contains as individual
%   properties all signals: the input signal, the output signal(s) requested by the user, 
%   but also all the intermediary representations necessary to compute the request.
%   All signals are individual objects inheriting the Signal class.
%
%   DATAOBJECT properties:
%       bufferSize_s - Global buffer size for all signals in seconds.
%       isStereo     - Flag indicating a binaural signal.
%       'signalname' - All the contained signals are defined as dynamic properties. The
%                      property name is taken from the signal object name property.
%                      Multiple signals with same names are arranged in a cell array, with
%                      columns spanning left/right channels.
%
%   DATAOBJECT methods:
%       dataObject          - Constructor for the class.
%       addsignal           - Adds a signal to the data object.
%       clearData           - Clears buffered data in all contained signals.
%       getParameterSummary - Returns the parameters used for computing all signals.
%       play                - Plays back the audio from the input signal.
%       plot                - Plots the input signal waveform.
%                      
%
% See also Signal, signals (folder)
    
    properties
        % bufferSize_s - Global buffer size for all signals (seconds). Due to the
        % compatibility with chunk-based processing, all signals need to be buffered to a
        % certain duration as the duration of the input signal is unknown and assumed
        % infinite.
        % See also circVBuf, circVBufArrayInterface

        bufferSize_s_rosAFE_port;
        bufferSize_s_rosAFE_getSignal;
        bufferSize_s_matlab;

        framesPerChunk;
        
        sampleRate;
        RosAFE;
        bass;
        
    end
    
    
    methods
        function dObj = dataObject_RosAFE( bassArg, rosAFEArg, inputDevice, sampleRate, framesPerChunk, bufferSize_s_bass, bufferSize_s_rosAFE_port, bufferSize_s_rosAFE_getSignal, bufferSize_s_matlab )
            %dataObject     Constructs a data object from an input device
            %
            %USAGE
            %       dObj = dataObject_RosAFE( bassArg, rosAFEArg, inputDevice, sampleRate )
            %       dObj = dataObject_RosAFE( bassArg, rosAFEArg, inputDevice, sampleRate, bufferSize_s )
            %
            %INPUT ARGUMENTS
            %     device : The input device
            % sampleRate : Sampling frequency
            % bufferSize : length of the signal buffer in seconds (default = 10)
            %
            %OUTPUT ARGUMENTS
            %       dObj : Data object
            
            if (nargin<5)
                error('The inputs should be provided.') 
            end
            
            if (nargin==5)
                bufferSize_s_rosAFE_port = 1;
                bufferSize_s_rosAFE_getSignal = 0.5;
                bufferSize_s_matlab = 10;
            end

            dObj.framesPerChunk = framesPerChunk;
            
            dObj.bufferSize_s_rosAFE_port = bufferSize_s_rosAFE_port;
            dObj.bufferSize_s_rosAFE_getSignal= bufferSize_s_rosAFE_getSignal;
            dObj.bufferSize_s_matlab = bufferSize_s_matlab;            
            
            dObj.RosAFE = rosAFEArg;
            dObj.bass = bassArg;
            dObj.sampleRate = sampleRate;
            
            nFramesPerChunk = 2205;
            nChunksOnPort =  floor(bufferSize_s_bass * sampleRate / nFramesPerChunk);

            acquire = dObj.bass.Acquire('-a', inputDevice, sampleRate, nFramesPerChunk, nChunksOnPort);
            pause(0.2);
            if ( strcmp(acquire.status,'error') )
                 error(strcat('Error',acquire.exception.ex));
            end
%             menu('Launch rosbag now','Done');
            
            connection = dObj.RosAFE.connect_port('Audio', 'bass/Audio');
            pause(0.2);
            if ( strcmp(connection.status,'error') )
                 error(strcat('Error',connection.exception.ex));
            end
        end
        
        function addSignal(dObj,sObj)
            %addSignal  Incorporates an additional signal object to a data object
            %
            %USAGE
            %     dObj.addSignal(sObj)
            %
            %INPUT ARGUMENTS
            %      dObj : Data object to add the signal to
            %      sObj : Signal object to add
            %
            %N.B. This method uses dynamic property names. The data object dObj will
            %     contain the signal sObj as a new property, named after sObj.Name. If
            %     such a property existed beforehand, the new signal will be incorporated
            %     in a cell array under that property name.
            
            % Which channel (left, right, mono) is this signal
            if strcmp(sObj.Channel,'right')
                jj = 2;
            else
                jj = 1;
            end
            
            % Check if a signal with this name already exist
            if isprop(dObj,sObj.Name)
                ii = size(dObj.(sObj.Name),1)+2-jj;
                dObj.(sObj.Name){ii,jj} = sObj;
            else
                dObj.addprop(sObj.Name);
                dObj.(sObj.Name) = {sObj};
            end
            
        end
 
        function clearData(dObj,bClearSignal)
            %clearData  Clears data of all signals in the data structure
            %
            %USAGE:
            %   dObj.clearData
            %   
            %N.B. Use dObj.clearData(0) to clear all signals BUT the input signal.
            
            if nargin<2 || isempty(bClearSignal)
                bClearSignal = 1;
            end
            
            % Get a list of the signals contained in the data object
            sig_list = fieldnames(dObj);
            
            % Remove the "isStereo" and "bufferSize_s" properties from the list
            sig_list = setdiff(sig_list,{'isStereo' 'bufferSize_s'});
            
            % Remove the signal from the list if needed
            if ~bClearSignal
                sig_list = setdiff(sig_list,{'input'});
            end
                
            % Loop over all the signals
            for ii = 1:size(sig_list,1)
                
                % There should always be a left or mono channel
                dObj.(sig_list{ii}){1}.clearData;
                
                % Check if there is a right channels
                if size(dObj.(sig_list{ii}),2)>1
                    
                    % It could still be empty (e.g. for "mix" signals)
                    if isa(dObj.(sig_list{ii}){2},'Signal')
                        dObj.(sig_list{ii}){2}.clearData;
                    end
                    
                end
                
            end
           
            
        end
        
        function p = getParameterSummary(dObj,mObj)
            %getParameterSummary  Returns a structure parameters used for computing each 
            %                     signal in the data object.
            %
            %USAGE:
            %   p = dObj.getParameterSummary(mObj)
            %
            %INPUT ARGUMENTS: 
            %   dObj : Data object instance
            %   mObj : Manager instance associated to the data
            %
            %OUTPUT ARGUMENTS:
            %      p : Structure of used parameter values
            
            % TODO: Update to refactored code version
            
            % Get a list of instantiated signals
            prop_list = properties(dObj);
            sig_list = setdiff(prop_list,{'isStereo' 'bufferSize_s'});
            
            % Initialize the output
            p = struct;
            
            % Loop on each signal
            for ii = 1:size(sig_list,1)
                
                % Test if multiple representations exist 
                if size(dObj.(sig_list{ii}),1)>1
                    % There are multiple representations with this name
                    
                    % Use a cell array
                    p.(sig_list{ii}) = cell(size(dObj.(sig_list{ii}),1),1);
                    
                    % Get the parameters
                    for jj = 1:size(dObj.(sig_list{ii}),1)
                        p.(sig_list{ii}){jj} = dObj.(sig_list{ii}){jj,1}.getParameters(mObj);
                    end
                    
                else
                    % There is only one such representation
                    p.(sig_list{ii}) = dObj.(sig_list{ii}){1,1}.getParameters(mObj);
                end
                    
                
            end
            
            
        end

    end
end
