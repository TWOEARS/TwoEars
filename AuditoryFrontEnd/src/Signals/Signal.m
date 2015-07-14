classdef Signal < handle
%SIGNAL Superclass for all signals involved in the auditory front-end (AFE) framework.
%   All signals involved in the AFE are inheriting this class, which defines properties
%   and methods shared among all signals.
%
%   SIGNAL properties:
%       Label      - Short and plain description of the signal (used e.g., as plot titles)
%       Name       - Single-word nametag for the signal
%       Dimensions - String describing signal's dimensions
%       FsHz       - Sampling frequency of the signal (in Hz)
%       Channel    - String indicating which audio channel the signal corresponds to
%
%   SIGNAL abstract method:
%       plot - Plots the signal. Should be implemented by any children class.
%
%   SIGNAL methods:
%       Signal         - Super-constructor for all signal objects
%       appendChunk    - Append a chunk of data to a signal buffer
%       setData        - Initialize the signal buffer
%       clearData      - Clears a signal buffer
%       getSignalBlock - Returns a data block from signal buffer
%       findProcessor  - Finds the processor that computed the signal
%       getParameters  - Returns the parameters used to compute the signal
%
% See also signals (folder), circVBuf, circVBufArrayInterface

    properties (SetAccess=protected)
        Label           % Used to label the signal (e.g., in plots)
        Name            % Used as an instance name in Matlab
        Dimensions      % String describing the dimensions of the signal
        FsHz            % Sampling frequency
        Channel         % Flag keeping track of the channel: 'mono', 'left'
                        %   or 'right'
    end
    
    properties (SetAccess = protected)
        Data;
    end

    properties (Access = protected)
        Buf;
    end

    methods (Abstract = true)
        h = plot(sObj,h_prev)
            % This method should create a figure displaying the data in the
            % signal object. As data can be of different nature for
            % different signal children objects, this method remains
            % abstract here.
               
    end
    
    methods
        
        function sObj = Signal( procHandle, bufferSize_s, bufferElemSize )
            %Signal     Super-constructor for the signal class
            %
            %USAGE:
            %   sObj = Signal(fs,bufferSize_s,bufferElemSize)
            %
            %INPUT ARGUMENTS:
            %             fs : Sampling frequency (Hz)
            %   bufferSize_s : Buffer duration in s
            % bufferElemSize : Additional dimensions of the buffer
            %                  [dim2,dim3,...]
            %
            %OUTPUT ARGUMENT:
            %           sObj : Signal instance
            
            % Set up sampling frequency
            sObj.FsHz = procHandle.FsHzOut;
            
            % Get the buffer size in samples
            bufferSizeSamples = ceil( bufferSize_s * sObj.FsHz );
            
            % Instantiate a buffer, and an array interface
            sObj.Buf = circVBuf( bufferSizeSamples, bufferElemSize );
            sObj.Data = circVBufArrayInterface( sObj.Buf );
            
            % Populate name and label
            sObj.Name = procHandle.getProcessorInfo.requestName;
            sObj.Label = procHandle.getProcessorInfo.requestLabel;
            
        end
        
        function appendChunk(sObj,data)
            %appendChunk   This method appends the chunk in data to the signal object
            %
            %USAGE
            %   sObj.appendChunk(data)
            %
            %INPUTS
            %   sObj : Signal object
            %   data : New chunk (re. time) to be appended to existing data
            %
            %DISCLAIMER:
            %This method is likely called numerous times hence there is no
            %checking on the provided data chunk (e.g., regarding its
            %dimensionality) to improve efficiency. Although for practical
            %reason it remains public, it should not be called "manually"
            %by a user.
            
            sObj.Buf.append( data );
            
        end

        function setData(sObj, data)
            %setData    Initialize the cyclic buffer using provided data
            %
            %USAGE:
            %   sObj.setData(data)
            %
            %INPUT ARGUMENTS:
            %   sObj : Signal instance
            %   data : Block of data to initialize the signal with
            
            % First: clear the buffer
            sObj.Buf.clear();

            % Then append the provided data
            if ~isempty(data), sObj.Buf.append( data ); end;

        end
        
        function clearData(sObj)
            %clearData  Clears the data in a signal object without changing
            %           its other properties
            %
            %USAGE
            %   sObj.clearData
            
            sObj.Buf.clear();
        end
        
        function sb = getSignalBlock(sObj,blocksize_s,backOffset_s)
            %getSignalBlock   Returns this Signal object's signal data
            %truncated to the last blocksize_s seconds. In case of too
            %little data, the block gets filled with zeros from beginning.
            %
            %USAGE:
            %   sb = sObj.getSignalBlock(blocksize_s)
            %   sb = sObj.getSignalBlock(blocksize_s,backOffset_s)
            %
            %INPUT ARGUMENTS:
            %         sObj : Signal instance
            %  blocksize_s : Length of the required data block in seconds
            % backOffset_s : Offset from the end of the signal to the 
            %                requested block's end in seconds (default: 0s)
            %
            %OUTPUT ARGUMENTS:
            %    sb : signal data block
            
            % Get the block duration in samples
            blocksize_samples = ceil( sObj.FsHz * blocksize_s );
            
            % Set default value for backOffset_s
            if nargin < 3, backOffset_s = 0; end;
            
            % Get the offset in samples...
            offset_samples = ceil( sObj.FsHz * backOffset_s );
            
            % ... with a warning if the requested signal is "too old"
            if offset_samples >= length(sObj.Data)
                warning( ['You are requesting a block that is not in the ',...
                    'buffer anymore.'] );
            end
            
            % Figure out the starting index in the buffer
            blockStart = max( 1, length( sObj.Data ) - ...
                blocksize_samples - offset_samples + 1 );
            
            % Extract the data block
            sb = sObj.Data(blockStart:end-offset_samples);
            
            % Zero-pad the data if not enough samples are available
            if size( sb, 1 ) < blocksize_samples
                sb = [zeros( blocksize_samples - size(sb,1), size(sb,2) ); sb];
            end
            
        end
            
        function pObj = findProcessor(sObj,mObj)
            %findProcessor   Returns a handle to the processor instance
            %that generated this signal.
            %
            %USAGE:
            %    pObj = sObj.findProcessor(mObj)
            %
            %INPUT ARGUMENTS:
            %    sObj : Signal instance
            %    mObj : Manager instance containing the sought processor
            %
            %OUTPUT ARGUMENTS:
            %    pObj : Handle to the processor instance which computed the
            %           signal (empty if none found)
            
            % NB: This brute force approach could be made more subtle by
            % looking into the type of signal sObj is. However it shouldn't
            % be necessary.
            
            % Number of instantiated processors
            n = numel(mObj.Processors);
            
            % Initialize output
            pObj = [];
            
            % Loop over all of them
            for ii = 1:n
                % Check that it is actually a processors
                if isa(mObj.Processors{ii},'Processor')
                    % Check if it outputs the signal of interest
                    for jj = 1:size(mObj.Processors{ii}.Output,2)
                        if sObj == mObj.Processors{ii}.Output{jj}
                            pObj = mObj.Processors{ii};
                        end
                    end
                end
            end 
        end
        
        function parStruct = getParameters(sObj,mObj)
            %getParameters  This methods returns a list of parameter
            %values used to compute a given signal.
            %
            %USAGE:
            %   parStruct = sObj.getParameters(mObj)
            %
            %INPUT PARAMETERS:
            %   sObj : Signal object instance
            %   mObj : Manager instance containing the processor responsible
            %   for computing the signal of interest
            %
            %OUTPUT PARAMETERS:
            %   parStruct : Parameter structure
            
            % Find the processor that computed sObj
            proc = sObj.findProcessor(mObj);
            
            % Get the parameters under which this processor was running
            if ~isempty(proc)
                parStruct = proc.getCurrentParameters;
            else
                % Couldn't find the processor in charge
                parStruct = struct;
                % Return a warning, unless sObj is the original ear signal
                if ~strcmp(sObj.Name,'input')
                    warning('Could not find the processor that computed the signal ''%s.''',sObj.Name)
                end
            end
            
        end
        
    end
    
    methods (Static)
        
        function sList = signalList()
            
            % Signal directory
            signalDir = mfilename('fullpath');
            
            % Get file information
            fileList = listFiles(signalDir(1:end-7),'*.m',-1);
            
            % Extract name only
            sList = cell(size(fileList));
            for ii = 1:size(fileList)
                % Get file name
                [~,fName] = fileparts(fileList(ii).name);
                
                % Check if it is a valid signal
                try
                    s = feval(str2func(fName));
                    if isa(s,'Signal')
                        sList{ii} = fName;
                    else
                        sList{ii} = [];
                    end
                catch
                    sList{ii} = [];
                end
                
            end
                
            % Remove empty elements
            sList = sList(~cellfun('isempty',sList));
            
        end
       
        function signalName = findSignalFromParameter(parameterName,no_warning)
            %Signal.findSignalFromParameter   Finds the signal that uses a given plotting
            %parameter
            %
            %USAGE:
            %   signalName = Signal.findSignalFromParameter(parName)
            %   signalName = Signal.findSignalFromParameter(parName, no_warning)
            %
            %INPUT ARGUMENT:
            %      parName : Name of the parameter
            %   no_warning : Set to 1 (default: 0) to suppress warning message
            %
            %OUTPUT ARGUMENT:
            %   signalName : Name of the signal using that parameter

            if nargin<2||isempty(no_warning); no_warning = 0; end
            
            % Get a list of processor
            signalList = Signal.signalList;

            % Add the general plot properties to the list
            signalList = ['Signal'; signalList];
            
            % Loop over each processor
            for ii = 1:size(signalList,1)
                try
                    sigParNames = feval([signalList{ii} '.getPlottingParameterInfo']);
                    
                    if ismember(parameterName,sigParNames)
                        signalName = signalList{ii};
                        return
                    end
                    
                catch
                    % Do not return a warning here, as this is called in a loop
                end

            end

            % If still running, then we haven't found it
            if ~no_warning
                warning('Could not find a signal which uses plotting parameter ''%s''',...
                        parameterName)
            end
            signalName = [];
            
            
        end
        
        function [names, defaultValues, descriptions] = getPlottingParameterInfo()
            %GETPLOTTINGPARAMETERINFO   Stores plot parameters that are common to all
            %signals.
            
            
            names = {'ftype',...
                    'fsize_label',...
                    'fsize_title',...
                    'fsize_axes',...
                    'color',...
                    'colors',...
                    'linewidth_s',...
                    'linewidth_m',...
                    'linewidth_l'};
                 
            descriptions = {'Plots font name', ...
                    'Labels font size', ...
                    'Titles font size', ...
                    'Axes font size', ...
                    'Main plot color', ...
                    'Multiple plot colors', ...
                    'Small linewidth', ...
                    'Medium linewidth', ...
                    'Large linewidth'};
                
            defaultValues = {'Helvetica', ...
                    12, ...
                    14, ...
                    10, ...
                    'b', ...
                    {'b', 'r', 'g', 'c'}, ...
                    1, ...
                    2, ...
                    3};
            
        end
        
    end
    
end