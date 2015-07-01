classdef manager < handle
%MANAGER Processor managing class for the auditory front-end (AFE) framework. A manager 
%   object controls the processing of the AFE framework. It is responsible for 
%   instantiating the required processors as well as correctly routing their respective 
%   inputs/outputs, given a request from the user. In addition, the manager methods allow 
%   the user to request a new representation or ask for the processing to be performed. 
%   Hence, the manager object represents the core of the AFE framework. 
%
%   MANAGER properties:
%       Processors - Cell array of processor objects.
%       InputList  - Handles to the input of each processors.
%       OutputList - Handles to the output of each processors.
%       Data       - Handle to the data object containing all computed signals.
%
%   MANAGER methods:
%       manager       - Constructor for the class. Requires a dataObject instance.
%       addProcessor  - Request a new auditory representation to extract.
%       processSignal - Requests the (offline) processing of an input signal.
%       processChunk  - Requests the (online) processing for a new chunk of signal..
%       hasProcessor  - Test if a given processor is already instantiated.
%       reset         - Resets internal states of all processors.
%       
%   See also dataObject, requestList, parameterHelper
%
% Disclamer: Known limitations that will be addressed in future releases
%   - When a processor becomes obsolete, its instance is not cleared from memory
%   - Few processors are not fully compatible with chunk-based processing (will return
%     erroneous representations in the vicinity of chunk boundaries):
%       * IHC methods involving Hilbert envelope extraction ('hilbert', 'joergensen', 
%         and 'bernstein')
%       * Spectro-temporal modulation extraction
%   - Pitch estimation might (though highely unlikely) be misestimated at chunk boundaries
%     in chunk-based processing scenarios
    
    
    properties (SetAccess = protected)
        % Processors - Cell array of processor objects. First column of the array contains
        % processors in charge of the left (or single) channel, second column of the
        % right channel. Different lines in the array are for different processor
        % instances.
        Processors = {};     
        
        % InputList - Cell array of handles to the input signal of each processors. A
        % signal at a given position in the array is the input to the processor stored
        % at the same position in the Processors property.
        InputList       
        
        % OutputList - Cell array of handles to the output signal of each processors. A
        % signal at a given position in the array is the output from the processor stored
        % at the same position in the Processors property.
        OutputList      
        
        % Data - Handle to the data object associated with this instance of the manager.
        Data
        
    end
    
    properties (GetAccess = protected)
        use_mex         % Flag for using mex files to speed up computation 
                        % when available
        Map             % Vector mapping the processing order to the 
                        % processors order. Allows for avoiding to reorder
                        % the processors array when new processors are
                        % added.
    end
    
    
    methods
        function mObj = manager(data,request,p,use_mex)
            %manager    Constructs a manager object
            %
            %USAGE
            %     mObj = manager(data)
            %     mObj = manager(data,request)
            %     mObj = manager(data,request,p)
            %
            %INPUT ARGUMENTS
            %     data : Handle of an existing data structure
            %  request : Single request as a string (e.g., 'ild'), OR cell array of
            %            requested signals, cues or features.
            %        p : Single parameter structure, if all requests share the same 
            %            parameters, OR cell array of individual parameter structures 
            %            corresponding to each request.
            %
            %OUTPUT ARGUMENTS
            %     mObj : Manager instance
            %
            %EXAMPLE USE (given an instance of dataObject, dObj)
            %- 'Empty' manager:
            %   mObj = manager(dObj)
            %- Single request, default parameters:
            %   mObj = manager(dObj,'autocorrelation')
            %- Multiple request with same parameters
            %   mObj = manager(dObj,{'ild','itd'},genParStruct('fb_nChannels',16))
            %  
            %
            %SEE ALSO: dataObject requestList genParStruct
            
            if nargin>0     % Failproof for Matlab empty calls
            
            % Input check
            if nargin<4||isempty(use_mex);use_mex=1;end
            if nargin<3||isempty(p);p=[];end
            if nargin<2
                request = [];
            end
            if nargin<1
                error(['Too few arguments, the manager is built upon '...
                    'an existing data Object'])
            end
            
            % Add use_mex property for the manager
            mObj.use_mex = use_mex;
            
            % Add pointer to the data structure
            mObj.Data = data;
            
            % Instantiate the requested processors
            if ~isempty(request)
                if iscell(request) && numel(request) == 1
                    % Then we have a one request with multiple parameters
                    if iscell(p)
                        %... with individual parameters
                        for ii = 1:size(p,2)
                            mObj.addProcessor(request,p{ii});
                        end
                    else
                        mObj.addProcessor(request,p);
                    end
                elseif iscell(request)
                    % Then we have a multiple request...
                    if iscell(p)
                        %... with individual parameters
                        if size(request,2)~=size(p,2)
                            error('Number of requests and number of provided parameters do not match')
                        else
                            for ii = 1:size(request,2)
                                mObj.addProcessor(request{ii},p{ii});
                            end
                        end
                    else
                        %... all with the same set of parameters
                        for ii = 1:size(request,2)
                            mObj.addProcessor(request{ii},p);
                        end
                    end
                elseif iscell(p)
                    % Then it is a same request but with multiple parameters
                    for ii = 1:size(p,2)
                        mObj.addProcessor(request,p{ii});
                    end
                else
                    % Then it is a single request
                     mObj.addProcessor(request,p);
                end
            end
            end
        end
        
        function processSignal(mObj)
            %processSignal      Requests a manager object to extract the requested 
            %                   features for the complete signal in mObj.Data.input
            %
            %USAGE
            %    mObj.processSignal()
            %
            %INPUT ARGUMENT
            %   mObj : Manager object
            %
            %NB: As opposed to the method processChunk, this method will
            %reset the internal states of the processors prior to
            %processing, assuming a completely new signal.
            %
            %SEE ALSO: processChunk
            
            % Check that there is an available signal
            if isempty(mObj.Data.input)
                warning('No signal available for processing')
            else            
                % Reset the processors internal states
                mObj.reset;
                
                % Number of processors
                n_proc = size(mObj.Processors,1);

                % Loop on each processor
                for ii = 1:n_proc
                    % Get index of current processor
                    jj = mObj.Map(ii);

                    mObj.Processors{jj,1}.initiateProcessing;
                    
                    if size(mObj.Processors,2) == 2 && ~isempty(mObj.Processors{jj,2})
                        mObj.Processors{jj,2}.initiateProcessing;
                    end
                    
%                     if ~mObj.Processors{jj,1}.isBinaural
%                         % Apply processing for left channel (or mono if
%                         % interaural cue/feature)
%                         mObj.OutputList{jj,1}.setData( ...
%                             mObj.Processors{jj,1}.processChunk(mObj.InputList{jj,1}.Data(:)) );
% 
%                         % Apply for right channel if stereo cue/feature
%                         if mObj.Data.isStereo && ~isempty(mObj.Processors{jj,2})
%                             mObj.OutputList{jj,2}.setData(...
%                                 mObj.Processors{jj,2}.processChunk(mObj.InputList{jj,2}.Data(:))...
%                                 );
%                         end
%                     else
%                         if ~mObj.Processors{jj,1}.hasTwoOutputs
%                             % If the processor extracts a binaural cue, inputs
%                             % from left and right channel should be routed
%                             mObj.OutputList{jj,1}.setData( ...
%                                 mObj.Processors{jj,1}.processChunk(mObj.InputList{jj,1}.Data(:),...
%                                 mObj.InputList{jj,2}.Data(:))...
%                                 );
%                         else
%                             if size(mObj.InputList,2)>1
%                                 [out_l, out_r] = mObj.Processors{jj,1}.processChunk(mObj.InputList{jj,1}.Data(:),...
%                                     mObj.InputList{jj,2}.Data(:));
%                             else
%                                 [out_l, out_r] = mObj.Processors{jj,1}.processChunk(mObj.InputList{jj,1}.Data(:),...
%                                     []);
%                             end
%                             mObj.OutputList{jj,1}.setData(out_l);
%                             if ~isempty(out_r)
%                                 mObj.OutputList{jj,2}.setData(out_r);
%                             end
%                         end
%                     end
                end
            end
        end
        
        function processChunk(mObj,sig_chunk,do_append)
            %processChunk   Update the signal with a new chunk of data and calls the 
            %               processing chain for this new chunk.
            %
            %USAGE
            %   mObj.processChunk(sig_chunk)
            %   mObj.processChunk(sig_chunk,append)
            %
            %INPUT ARGUMENTS
            %      mObj : Manager object
            % sig_chunk : New signal chunk
            %    append : Flag indicating if the newly generated output
            %             should be appended (append = 1) to previous
            %             output or should overwrite it (append = 0,
            %             default)
            %
            %NB: Even if the previous output is overwritten, the
            %processChunk method allows for chunk-based processing by keeping
            %track of the processors' internal states between chunks.
            %
            %SEE ALSO: processSignal
            
            if nargin<3||isempty(do_append);do_append = 0;end
            
            % Check that the signal chunk has correct number of channels
            if size(sig_chunk,2) ~= mObj.Data.isStereo+1
                % TO DO: Change that to a warning and handle appropriately
                error(['The dimensionality of the provided signal chunk'...
                    'is incompatible with previous chunks'])
            end
            
            % Delete previous output if necessary
            if ~do_append
                mObj.Data.clearData;
            end
            
            
            % Append the signal chunk
            if mObj.Data.isStereo
               mObj.Data.input{1}.appendChunk(sig_chunk(:,1));
               mObj.Data.input{2}.appendChunk(sig_chunk(:,2));
            else            
               mObj.Data.input{1}.appendChunk(sig_chunk);
            end
            
            % Number of processors
            n_proc = size(mObj.Processors,1);
            
            % Loop on each processor
            for ii = 1:n_proc
                % Get index of current processor
                jj = mObj.Map(ii);

                mObj.Processors{jj,1}.initiateProcessing;

                if size(mObj.Processors,2) == 2 && ~isempty(mObj.Processors{jj,2})
                    mObj.Processors{jj,2}.initiateProcessing;
                end
            end
            
            % Loop on each processor
%             for ii = 1:n_proc
%                 % Get index of current processor
%                 jj = mObj.Map(ii);
%                 
%                 if ~mObj.Processors{jj,1}.isBinaural
%                     % Apply processing for left channel (or mono if
%                     % interaural cue/feature):
% 
%                     % Getting input signal handle (for code readability)
%                     in = mObj.InputList{jj,1};
% 
%                     % Perform the processing
%                     out = mObj.Processors{jj,1}.processChunk(in.Data('new'));
% 
%                     % Store the result
%                     mObj.OutputList{jj,1}.appendChunk(out);
% 
%                     % Apply similarly for right channel if binaural cue/feature
%                     if mObj.Data.isStereo && ~isempty(mObj.Processors{jj,2})
%                         in = mObj.InputList{jj,2};
%                         out = mObj.Processors{jj,2}.processChunk(in.Data('new'));
%                         mObj.OutputList{jj,2}.appendChunk(out);
%                     end
%                     
%                 else
%                     % Inputs from left AND right channels are needed at
%                     % once
%                     
%                     % Getting input signal handles for both channels
%                     in_l = mObj.InputList{jj,1};
%                     
%                     if ~mObj.Processors{jj,1}.hasTwoOutputs
%                         
%                         in_r = mObj.InputList{jj,2};
%                         
%                         % Perform the processing
%                         out = mObj.Processors{jj,1}.processChunk(...
%                             in_l.Data('new'),...
%                             in_r.Data('new'));
% 
%                         % Store the result
%                         mObj.OutputList{jj,1}.appendChunk(out);
%                     else
%                         
%                         if size(mObj.InputList,2)>1
%                             in_r = mObj.InputList{jj,2};
%                             
%                             % Perform the processing
%                             [out_l, out_r] = mObj.Processors{jj,1}.processChunk(...
%                                 in_l.Data('new'),...
%                                 in_r.Data('new'));
%                         else
%                             % Perform the processing
%                             [out_l, out_r] = mObj.Processors{jj,1}.processChunk(...
%                                 in_l.Data('new'));
%                         end
% 
%                         % Store the result
%                         mObj.OutputList{jj,1}.appendChunk(out_l);
%                         
%                         if ~isempty(out_r)
%                             mObj.OutputList{jj,2}.appendChunk(out_r);
%                         end
%                     end
%                 end
                
%                 % Getting input signal handle (for code readability)
%                 in = mObj.InputList{jj};
%                 
%                 % Perform the processing
%                 out = mObj.Processors{jj}.processChunk(in.Data('new'));
%                 
%                 % Store the result
%                 mObj.OutputList{jj}.appendChunk(out);
                
            
        end
        
        function hProc = hasProcessor(mObj,name,p,channel)
            %hasProcessor    Determines if a processor with a given set of parameters
            %                (including those of its dependencies) is already instantiated
            %
            %USAGE
            %   hProc = mObj.hasProcessor(name,p)
            %   hProc = mObj.hasProcessor(name,p,channel)
            %
            %INPUT ARGUMENTS
            %    mObj : Instance of manager object
            %    name : Name of processor
            %       p : Complete structure of parameters for that processor
            % channel : Channel the sought processor should be acting on
            %           ('left', 'right', or 'mono'). If unspecified, any
            %           processor with matching parameter will be returned.
            %
            %OUTPUT ARGUMENT
            %   hProc : Handle to an existing processor, if any, 0 else
            
            %TODO: Will need maintenance when introducing processors with multiple lower
            %dependencies
            
            ch_name = {'left','right','mono'};
            
            if nargin<4 %|| isempty(channel)
                channel = ch_name;
            elseif ~ismember(channel,ch_name)
                error('Invalid tag for channel name. Valid tags are as follow: %s',strjoin(ch_name))
            end
            
            if ~iscell(channel)
                channel = {channel};
            end
            
            % Initialize the output
            hProc = 0;
            
            % Look into corresponding ear depending on channel request.
            % Left and mono are always in the first column of the
            % processors cell array, right in the second.
            if strcmp(channel,'right')
                earIndex = 2;
            else
                earIndex = 1;
            end
            
            % Loop over the processors to find the ones with suitable name
            for ii = 1:size(mObj.Processors,1)
                
                % Get a handle to that processor, for readability in the
                % following
                proc = mObj.Processors{ii,earIndex};
                
                % Is the current processor one of the sought type?
                if isa(proc,name) && ismember(proc.Channel,channel)
                    
                    % Does it have the requested parameters?
                    if proc.hasParameters(p)
                        
                        % Then it is a suitable candidate, we should
                        % investigate its dependencies
                        while true
                            
                            if isempty(proc.LowerDependencies)
                                % Then we reached the end of the dependency
                                % list without finding a mismatch in
                                % parameters. The original processor is a
                                % solution:
                                hProc = mObj.Processors{ii,earIndex};
                                return
                            end
                            
                            % Set current processor to proc dependency
                            proc = proc.LowerDependencies{1};
                            
                            % Does the dependency also have requested
                            % parameters? If not, break of the while loop
                            if ~proc.hasParameters(p)
                                break
                            end
                            
                        end
                        
                        
                    end
                    
                end
                
                % If not, move along in the loop
                
            end
            
        end
        
        function [out,varargout] = addProcessor(mObj,request,p)
            %addProcessor   Add new processor(s) needed to compute a user request.
            %               Optionally returns a handle to the corresponding output signal
            %
            %USAGE:
            %           mObj.addProcessor(request,p)
            %    sOut = mObj.addProcessor(...)
            %
            %INPUT ARGUMENTS
            %    mObj : Manager instance
            % request : Requested signal (string)
            %       p : Structure of non-default parameters
            %
            %OUTPUT ARGUMENTS
            %    sOut : Handle to the requested signal
            %
            %EXAMPLE USE
            %- Single request, default parameters:
            %   sOut = mObj.addProcessor('autocorrelation');
            %- Multiple request with same non-default parameters
            %   [sOut1,sOut2] = manager({'ild','itd'}, genParStruct('fb_nChannels',16));
           
%             if nargin<3 || isempty(p)
%                 % Initialize parameter structure
%                 p = struct;
%             end
            
            if nargin<3; p = []; end
                

            % Deal with multiple requests via pseudo-recursion
            if iscell(request) || iscell(p)
                
                if iscell(request) && ~iscell(p)
                    % All the requests have the same parameters, replicate
                    % them
                    p = repmat({p},size(request));
                elseif ~iscell(request) && iscell(p)
                    % One request with different parameters, replicate the request
                    request = repmat({request},size(p));
                end
                
                if size(p,2)~=size(request,2)
                    error(['Provided number of parameter structures'...
                        ' does not match the number of requests made'])
                end
                
                % Call addProcessor method for each individual request
                varargout = cell(1,size(request,2)-1);
                out = mObj.addProcessor(request{1},p{1});
                for ii = 2:size(request,2)
                    varargout{ii-1} = mObj.addProcessor(request{ii},p{ii});
                end
                return
                
            end
            
%             if ~isfield(p,'fs')
%                 % Add sampling frequency to the parameter structure
%                 p.fs = mObj.Data.input{1}.FsHz;
%             end

            fs = mObj.Data.input{1}.FsHz;
            
            % Find most suitable initial processor for that request
            [initProc,dep_list] = mObj.findInitProc(request,p);
            
            % Replace the initProc with dummy processor(s) if empty
            if isempty(initProc)
                if mObj.Data.isStereo
                    initProc = {identityProc(fs), identityProc(fs)};
                    initProc{1}.Output = mObj.Data.input(1);
                    initProc{2}.Output = mObj.Data.input(2);
                else
                    initProc = {identityProc(fs)};
                    initProc{1}.Output = mObj.Data.input;
                end
            end
            
            % Algorithm should proceed further even if the requested
            % processor already exists
            if isempty(dep_list)
                proceed = 1;
            end
            
            % The processing order is the reversed list of dependencies
            dep_list = fliplr(dep_list);
 
            % Former and new number of processors
            n_proc = size(mObj.Processors,1);
            n_new_proc = size(dep_list,2);
            
            % Preallocation
            if isempty(mObj.Processors)
                if mObj.Data.isStereo
                    n_chan = 2;
                else
                    n_chan = 1;
                end
                mObj.Processors = cell(n_new_proc,n_chan);   
            end
            
            
            % Initialize pointer to dependency 
            dependency = initProc;
            
            % Processors instantiation and data object property population
            for ii = n_proc+1:n_proc+n_new_proc   
                
                proceed = 1;     % Initialize a flag to identify invalid requests (binaural representation requested on a mono signal)
                %% Commented out old processor and signal instantiation
%                 switch dep_list{ii-n_proc}
%                     
%                     case 'time'
%                         % TO DO: Include actual time processor
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = preProc(p.fs,p);
% %                             mObj.Processors{ii,2} = identityProc(p.fs);
%                             % Generate new signals
%                             sig_l = TimeDomainSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'time','Time domain signal',[],'left');
%                             sig_r = TimeDomainSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'time','Time domain signal',[],'right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii} = preProc(fs,p);
%                             % Generate a new signal
%                             sig = TimeDomainSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'time','Time domain signal',[],'mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                                      
%                     case 'framedSignal'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = framingProc(p.fs,p.fr_wname,p.fr_wSize,p.fr_hSize);
%                             mObj.Processors{ii,2} = framingProc(p.fs,p.fr_wname,p.fr_wSize,p.fr_hSize);
%                             % Generate new signals
%                             sig_l = FramedSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,p.fr_wSize,mObj.Processors{ii,1}.FsHzIn,'framedSignal','Framed signal','left');
%                             sig_r = FramedSignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,p.fr_wSize,mObj.Processors{ii,1}.FsHzIn,'framedSignal','Framed signal','right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii} = framingProc(p.fs,p.fr_wname,p.fr_wSize,p.fr_hSize);
%                             % Generate a new signal
%                             sig = FramedSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,p.fr_wSize,mObj.Processors{ii,1}.FsHzIn,'framedSignal','Framed signal','mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'filterbank'
%                         
%                         switch p.fb_type
%                             
%                             case 'gammatone'
%                                 if mObj.Data.isStereo
%                                     % Instantiate left and right ear processors
%                                     switch gamma_init
%                                         case 'cfHz'
%                                             mObj.Processors{ii,1} = gammatoneProc(p.fs,[],[],[],[],p.fb_cfHz,p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
%                                             mObj.Processors{ii,2} = gammatoneProc(p.fs,[],[],[],[],p.fb_cfHz,p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
% 
%                                         case 'nChannels'
%                                             mObj.Processors{ii,1} = gammatoneProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,[],p.fb_nChannels,[],p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
%                                             mObj.Processors{ii,2} = gammatoneProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,[],p.fb_nChannels,[],p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
% 
%                                         case 'standard'
%                                             mObj.Processors{ii,1} = gammatoneProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,p.fb_nERBs,[],[],p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
%                                             mObj.Processors{ii,2} = gammatoneProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,p.fb_nERBs,[],[],p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
%                                     end
%                                     % Generate new signals
%                                     sig_l = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'gammatone',mObj.Processors{ii}.cfHz,'Gammatone filterbank output',[],'left');
%                                     sig_r = TimeFrequencySignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'gammatone',mObj.Processors{ii}.cfHz,'Gammatone filterbank output',[],'right');
%                                     % Add the signals to the data object
%                                     mObj.Data.addSignal(sig_l);
%                                     mObj.Data.addSignal(sig_r)
%                                 else
%                                     % Instantiate a processor
%                                     switch gamma_init
%                                         case 'cfHz'
%                                             mObj.Processors{ii,1} = gammatoneProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,[],[],p.fb_cfHz,p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
%                                         case 'nChannels'
%                                             mObj.Processors{ii,1} = gammatoneProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,[],p.fb_nChannels,[],p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
%                                         case 'standard'
%                                             mObj.Processors{ii,1} = gammatoneProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,p.fb_nERBs,[],[],p.fb_bAlign,p.fb_nGamma,p.fb_bwERBs);
%                                     end
%                                     % Generate a new signal
%                                     sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'gammatone',mObj.Processors{ii}.cfHz,'Gammatone filterbank output',[],'mono');
%                                     % Add signal to the data object
%                                     mObj.Data.addSignal(sig);
%                                 end
%                         
%                             case 'drnl'
%                                 if mObj.Data.isStereo
%                                     switch fb_init
%                                         case 'cfHz'
%                                             mObj.Processors{ii,1} = drnlProc(p.fs,[],[],[],[],p.fb_cfHz,p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
%                                             mObj.Processors{ii,2} = drnlProc(p.fs,[],[],[],[],p.fb_cfHz,p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
% 
%                                             % Throw a warning if conflicting information was provided
%         %                                     if isfield(p,'fb_lowFreqHz')||isfield(p,'fb_highFreqHz')||isfield(p,'fb_nERBs')||isfield(p,'fb_nChannels')
%         %                                         warning(['Conflicting information was provided for the DRNL filterbank instantiation. The filterbank '...
%         %                                             'will be generated from the provided vector of center frequencies.'])
%         %                                     end
% 
%                                         case 'nChannels'
%                                             mObj.Processors{ii,1} = drnlProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,[],p.fb_nChannels,[],p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
%                                             mObj.Processors{ii,2} = drnlProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,[],p.fb_nChannels,[],p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
% 
%                                             % Throw a warning if conflicting information was provided
%         %                                     if isfield(p,'fb_nERBs')
%         %                                         warning(['Conflicting information was provided for the DRNL filterbank instantiation. The filterbank '...
%         %                                             'will be generated from the provided frequency range and number of channels.'])
%         %                                     end
% 
%                                         case 'standard'
%                                             mObj.Processors{ii,1} = drnlProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,p.fb_nERBs,[],[],p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
%                                             mObj.Processors{ii,2} = drnlProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,p.fb_nERBs,[],[],p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
%                                     end
%                                     % Generate new signals
%                                     sig_l = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'drnl',mObj.Processors{ii}.cfHz,'DRNL filterbank output',[],'left');
%                                     sig_r = TimeFrequencySignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'drnl',mObj.Processors{ii}.cfHz,'DRNL filterbank output',[],'right');
%                                     % Add the signals to the data object
%                                     mObj.Data.addSignal(sig_l);
%                                     mObj.Data.addSignal(sig_r)
%                                 else
%                                     % Instantiate a processor
%                                     switch fb_init
%                                         case 'cfHz'
%                                             mObj.Processors{ii,1} = drnlProc(p.fs,[],[],[],[],p.fb_cfHz,p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
%                                         case 'nChannels'
%                                             mObj.Processors{ii,1} = drnlProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,[],p.fb_nChannels,[],p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
%                                         case 'standard'
%                                             mObj.Processors{ii,1} = drnlProc(p.fs,p.fb_lowFreqHz,p.fb_highFreqHz,p.fb_nERBs,[],[],p.fb_mocIpsi,p.fb_mocContra,p.fb_model);
%                                     end
%                                     % Generate a new signal
%                                     sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'drnl',mObj.Processors{ii}.cfHz,'DRNL filterbank output',[],'mono');
%                                     % Add signal to the data object
%                                     mObj.Data.addSignal(sig);
%                                 end
%                                 
%                             otherwise
%                                 error('Incorrect filterbank name')
%                         end
%    
%                     case 'innerhaircell'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = ihcProc(dep_proc_l.FsHzOut,p.ihc_method);
%                             mObj.Processors{ii,2} = ihcProc(dep_proc_r.FsHzOut,p.ihc_method);
%                             % Generate new signals
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Get the center frequencies from dependencies
%                             sig_l = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'innerhaircell',cfHz,'Inner hair-cell envelope',[],'left');
%                             sig_r = TimeFrequencySignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'innerhaircell',cfHz,'Inner hair-cell envelope',[],'right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii} = ihcProc(dep_proc.FsHzOut,p.ihc_method);
%                             % Generate a new signal
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Get the center frequencies from dependencies
%                             sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'innerhaircell',cfHz,'Inner hair-cell envelope',[],'mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%              
%                     case 'adaptation'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = adaptationProc(p.fs,p.adpt_lim, p.adpt_mindB, p.adpt_tau);
%                             mObj.Processors{ii,2} = adaptationProc(p.fs,p.adpt_lim, p.adpt_mindB, p.adpt_tau);
%                             % Generate new signals
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Get the center frequencies from dependencies
%                             sig_l = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'adaptation',cfHz,'Adaptation loop output',[],'left');
%                             sig_r = TimeFrequencySignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'adaptation',cfHz,'Adaptation loop output',[],'right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii} = adaptationProc(p.fs,p.adpt_lim, p.adpt_mindB, p.adpt_tau);
%                             % Generate a new signal
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Get the center frequencies from dependencies
%                             sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'adaptation',cfHz,'Adaptation loop output',[],'mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
% 
%                     case 'ams_features'
%                         if mObj.Data.isStereo
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Vector of center audio frequencies
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = modulationProc(dep_proc_l.FsHzOut,numel(cfHz),p.ams_cfHz,p.ams_nFilters,p.ams_lowFreqHz,p.ams_highFreqHz,p.ams_wname,p.ams_wSizeSec,p.ams_hSizeSec,p.ams_fbType,p.ams_dsRatio);
%                             mObj.Processors{ii,2} = modulationProc(dep_proc_r.FsHzOut,numel(cfHz),p.ams_cfHz,p.ams_nFilters,p.ams_lowFreqHz,p.ams_highFreqHz,p.ams_wname,p.ams_wSizeSec,p.ams_hSizeSec,p.ams_fbType,p.ams_dsRatio);
%                             % Generate new signals
%                             modCfHz = mObj.Processors{ii,1}.modCfHz;            % Vector of center modulation frequencies
%                             sig_l = ModulationSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'ams_features',cfHz,modCfHz,'Amplitude modulation spectrogram',[],'left');
%                             sig_r = ModulationSignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'ams_features',cfHz,modCfHz,'Amplitude modulation spectrogram',[],'right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Vector of center audio frequencies
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = modulationProc(dep_proc.FsHzOut,numel(cfHz),p.ams_cfHz,p.ams_nFilters,p.ams_lowFreqHz,p.ams_highFreqHz,p.ams_wname,p.ams_wSizeSec,p.ams_hSizeSec,p.ams_fbType,p.ams_dsRatio);
%                             % Generate a new signal
%                             modCfHz = mObj.Processors{ii,1}.modCfHz;            % Vector of center modulation frequencies
%                             sig = ModulationSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'ams_features',cfHz,modCfHz,'Amplitude modulation spectrogram',[],'mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         clear modCfHz cfHz
%                         
%                     case 'autocorrelation'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = autocorrelationProc(dep_proc_l.FsHzOut,p,mObj.use_mex);
%                             mObj.Processors{ii,2} = autocorrelationProc(dep_proc_r.FsHzOut,p,mObj.use_mex);
%                             % Generate new signals
%                             lags = ((1:(2 * round(mObj.Processors{ii,1}.wSizeSec * p.fs * 0.5)-1))-1)/p.fs;
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');         % Vector of center frequencies
%                             sig_l = CorrelationSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'autocorrelation',cfHz,lags,'Auto-correlation function',[],'left');
%                             sig_r = CorrelationSignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'autocorrelation',cfHz,lags,'Auto-correlation function',[],'right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = autocorrelationProc(dep_proc.FsHzOut,p,mObj.use_mex);
%                             % Generate a new signal
%                             lags = ((1:(2 * round(mObj.Processors{ii,1}.wSizeSec * p.fs * 0.5)-1))-1)/p.fs;
%                             cfHz = dep_proc.getDependentParameter('cfHz');         % Vector of center frequencies
%                             sig = CorrelationSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'autocorrelation',cfHz,lags,'Auto-correlation function',[],'mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         clear lags
%                         
%                     case 'pitch'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             lags = dep_sig_l.lags;
%                             mObj.Processors{ii,1} = pitchProc(dep_proc_l.FsHzOut,lags,p);
%                             mObj.Processors{ii,2} = pitchProc(dep_proc_r.FsHzOut,lags,p);
%                             % Generate new signals
%                             sig_l = FeatureSignal(mObj.Processors{ii,1}.FsHzOut,{'pitch','rawPitch','confidence'},mObj.Data.bufferSize_s,'pitch','Pitch estimation','left');
%                             sig_r = FeatureSignal(mObj.Processors{ii,1}.FsHzOut,{'pitch','rawPitch','confidence'},mObj.Data.bufferSize_s,'pitch','Pitch estimation','left');
% %                             sig_l = TimeDomainSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'pitch','Pitch estimation',[],'left');
% %                             sig_r = TimeDomainSignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'pitch','Pitch estimation',[],'right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             lags = dep_sig.lags;
%                             mObj.Processors{ii,1} = pitchProc(dep_proc.FsHzOut,lags,p);
%                             % Generate a new signal
%                             sig = FeatureSignal(mObj.Processors{ii,1}.FsHzOut,{'pitch','rawPitch','confidence'},mObj.Data.bufferSize_s,'pitch','Pitch estimation','mono');
% %                             sig = TimeDomainSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'pitch','Pitch estimation',[],'mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'crosscorrelation'
%                         % Check that two channels are available
%                         if ~mObj.Data.isStereo
%                             warning('Manager cannot instantiate a binaural cue extractor for a single-channel signal')
%                             proceed = 0;
%                         else
% %                             mObj.Processors{ii,1} = crosscorrelationProc(p.fs,p);
%                                 
%                             % TEMP:
%                             mObj.Processors{ii,1} = crosscorrelationProc(dep_proc_l.FsHzOut,p,mObj.use_mex);
% 
%                             maxLag = ceil(mObj.Processors{ii,1}.maxDelaySec*dep_proc_l.FsHzOut);
%                             lags = (-maxLag:maxLag)/dep_proc_l.FsHzOut;                           % Lags
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');        % Center frequencies 
%                             sig = CorrelationSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'crosscorrelation',cfHz,lags,'Cross-correlation function',[],'mono');
%                             mObj.Data.addSignal(sig);
%                             clear maxLag lags
%                         end
%                         
%                     case 'crosscorrelation_feature'
%                         % Check that two channels are available
%                         if ~mObj.Data.isStereo
%                             warning('Manager cannot instantiate a binaural cue extractor for a single-channel signal')
%                             proceed = 0;
%                         else
%                             mObj.Processors{ii,1} = ccFeatureProc(dep_proc.FsHzOut,p.ccf_factor);
% 
%                             % Previous lag vector
%                             lags = dep_sig.lags;
%                             n_lags = size(lags,2);
%                             
%                             % Downsample this vector
%                             origin = (n_lags+1)/2;
%                             n_lags_ds = floor((origin-1)/p.ccf_factor);
%                             lags_ds = lags(origin-n_lags_ds*p.ccf_factor:p.ccf_factor:origin+n_lags_ds*p.ccf_factor);
%                             
%                             % Center frequencies
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');        % Center frequencies 
%                             
%                             % Instantiate a new signal
%                             sig = CorrelationSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'crosscorrelation_feature',cfHz,lags_ds,'Cross-correlation feature',[],'mono');
%                             mObj.Data.addSignal(sig);
%                             clear lags n_lags origin n_lags_ds lags_ds
%                         end
%                         
%                     case 'ratemap'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = ratemapProc(dep_proc_l.FsHzOut,p,mObj.use_mex);
%                             mObj.Processors{ii,2} = ratemapProc(dep_proc_r.FsHzOut,p,mObj.use_mex);
%                             % Generate new signals
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Center frequencies
%                             sig_l = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'ratemap',cfHz,'Ratemap',[],'left',p.rm_scaling);
%                             sig_r = TimeFrequencySignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'ratemap',cfHz,'Ratemap',[],'right',p.rm_scaling);
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = ratemapProc(dep_proc.FsHzOut,p,mObj.use_mex);
%                             % Generate a new signal
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Center frequencies
%                             sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'ratemap',cfHz,'Ratemap',[],'mono',p.rm_scaling);
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                                                 
%                     case 'onset_strength'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = onsetProc(dep_proc_l.FsHzOut,p);
%                             mObj.Processors{ii,2} = onsetProc(dep_proc_r.FsHzOut,p);
%                             % Generate new signals
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Center frequencies
%                             sig_l = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'onset_strength',cfHz,'Onset strength',[],'left');
%                             sig_r = TimeFrequencySignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'onset_strength',cfHz,'Onset strength',[],'right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = onsetProc(dep_proc.FsHzOut,p);
%                             % Generate a new signal
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Center frequencies
%                             sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'onset_strength',cfHz,'Onset strength',[],'mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'offset_strength'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = offsetProc(dep_proc_l.FsHzOut,p);
%                             mObj.Processors{ii,2} = offsetProc(dep_proc_r.FsHzOut,p);
%                             % Generate new signals
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Center frequencies
%                             sig_l = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'offset_strength',cfHz,'Offset strength',[],'left');
%                             sig_r = TimeFrequencySignal(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'offset_strength',cfHz,'Offset strength',[],'right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = offsetProc(dep_proc.FsHzOut,p);
%                             % Generate a new signal
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Center frequencies
%                             sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'offset_strength',cfHz,'Offset strength',[],'mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'onset_map'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = transientMapProc(dep_proc_l.FsHzOut,p);
%                             mObj.Processors{ii,2} = transientMapProc(dep_proc_r.FsHzOut,p);
%                             % Generate new signals
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Center frequencies
%                             sig_l = BinaryMask(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'onset_map',cfHz,'Onset map',[],'left',dep_proc_l.Input);
%                             sig_r = BinaryMask(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'onset_map',cfHz,'Onset map',[],'right',dep_proc_r.Input);
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = transientMapProc(dep_proc.FsHzOut,p);
%                             % Generate a new signal
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Center frequencies
%                             sig = BinaryMask(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'onset_map',cfHz,'Onset map',[],'mono',dep_proc.Input);
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'offset_map'
%                         if mObj.Data.isStereo
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = transientMapProc(dep_proc_l.FsHzOut,p);
%                             mObj.Processors{ii,2} = transientMapProc(dep_proc_r.FsHzOut,p);
%                             % Generate new signals
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Center frequencies
%                             sig_l = BinaryMask(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'offset_map',cfHz,'Offset map',[],'left',dep_proc_l.Input);
%                             sig_r = BinaryMask(mObj.Processors{ii,2}.FsHzOut,mObj.Data.bufferSize_s,'offset_map',cfHz,'Offset map',[],'right',dep_proc_r.Input);
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = transientMapProc(dep_proc.FsHzOut,p);
%                             % Generate a new signal
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Center frequencies
%                             sig = BinaryMask(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'offset_map',cfHz,'Offset map',[],'mono',dep_proc.Input);
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'spectral_features'
%                         if mObj.Data.isStereo
%                             % Get the center frequencies from dependent processors
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = spectralFeaturesProc(dep_proc_l.FsHzOut,cfHz,p.sf_requests,p.sf_br_cf,p.sf_ro_perc);
%                             mObj.Processors{ii,2} = spectralFeaturesProc(dep_proc_r.FsHzOut,cfHz,p.sf_requests,p.sf_br_cf,p.sf_ro_perc);
%                             % Generate new signals
% %                             sig_l = SpectralFeaturesSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Processors{ii,1}.requestList,mObj.Data.bufferSize_s,'spectral_features','Spectral Features','left');
% %                             sig_r = SpectralFeaturesSignal(mObj.Processors{ii,2}.FsHzOut,mObj.Processors{ii,2}.requestList,mObj.Data.bufferSize_s,'spectral_features','Spectral Features','right');
%                             sig_l = FeatureSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Processors{ii,1}.requestList,mObj.Data.bufferSize_s,'spectral_features','Spectral features','left');
%                             sig_r = FeatureSignal(mObj.Processors{ii,2}.FsHzOut,mObj.Processors{ii,2}.requestList,mObj.Data.bufferSize_s,'spectral_features','Spectral features','right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Get the center frequencies from dependent processors
%                             cfHz = dep_proc.getDependentParameter('cfHz');
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = spectralFeaturesProc(dep_proc.FsHzOut,cfHz,p.sf_requests,p.sf_br_cf,p.sf_ro_perc);
%                             % Generate a new signal
% %                             sig = SpectralFeaturesSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Processors{ii,1}.requestList,mObj.Data.bufferSize_s,'spectral_features','Spectral Features','mono');
%                             sig = FeatureSignal(mObj.Processors{ii,1}.FsHzOut,mObj.Processors{ii,1}.requestList,mObj.Data.bufferSize_s,'spectral_features','Spectral Features','mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                         
%                         
%                     case 'ild'
%                         % Check that two channels are available
%                         if ~mObj.Data.isStereo
%                             warning('Manager cannot instantiate a binaural cue extractor for a single-channel signal')
%                             proceed = 0;
%                         else
%                             mObj.Processors{ii,1} = ildProc(dep_proc_l.FsHzOut,p);
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');    % Center frequencies
%                             sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'ild',cfHz,'Interaural level difference',[],'mono');
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'ic'
%                         if ~mObj.Data.isStereo
%                             warning('Manager cannot instantiate a binaural cue extractor for a single-channel signal')
%                             proceed = 0;
%                         else
%                             mObj.Processors{ii,1} = icProc(dep_proc.FsHzOut,p);
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Center frequencies
%                             sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'ic',cfHz,'Interaural coherence',[],'mono');
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'itd'
%                         if ~mObj.Data.isStereo
%                             warning('Manager cannot instantiate a binaural cue extractor for a single-channel signal')
%                             proceed = 0;
%                         else
%                             mObj.Processors{ii,1} = itdProc(dep_proc.FsHzOut,p);
%                             cfHz = dep_proc.getDependentParameter('cfHz');    % Center frequencies
%                             sig = TimeFrequencySignal(mObj.Processors{ii,1}.FsHzOut,mObj.Data.bufferSize_s,'itd',cfHz,'Interaural time difference',[],'mono');
%                             mObj.Data.addSignal(sig);
%                         end
%                         
%                     case 'gabor'
%                         if mObj.Data.isStereo
%                             % Get the center frequencies from dependent processors
%                             cfHz = dep_proc_l.getDependentParameter('cfHz');
%                             % Instantiate left and right ear processors
%                             mObj.Processors{ii,1} = gaborProc(dep_proc_l.FsHzOut,p,size(cfHz,2));
%                             mObj.Processors{ii,2} = gaborProc(dep_proc_l.FsHzOut,p,size(cfHz,2));
%                             
%                             
%                             nFeat = mObj.Processors{ii,1}.nFeat;
%                             fList = cell(1,nFeat);
%                             for jj = 1:nFeat
%                                 fList{jj} = num2str(jj);
%                             end
%                         
%                             % Generate new signals
%                             sig_l = FeatureSignal(mObj.Processors{ii,1}.FsHzOut,fList,mObj.Data.bufferSize_s,'gabor','Gabor features','left');
%                             sig_r = FeatureSignal(mObj.Processors{ii,2}.FsHzOut,fList,mObj.Data.bufferSize_s,'gabor','Gabor features','right');
%                             % Add the signals to the data object
%                             mObj.Data.addSignal(sig_l);
%                             mObj.Data.addSignal(sig_r)
%                         else
%                             % Get the center frequencies from dependent processors
%                             cfHz = dep_proc.getDependentParameter('cfHz');
%                             % Instantiate a processor
%                             mObj.Processors{ii,1} = gaborProc(dep_proc.FsHzOut,p,size(cfHz,2));
%                             
%                             % List of features
%                             nFeat = mObj.Processors{ii,1}.nFeat;
%                             fList = cell(1,nFeat);
%                             for jj = 1:nFeat
%                                 fList{jj} = num2str(jj);
%                             end
%                             
%                             % Generate a new signal
%                             sig = FeatureSignal(mObj.Processors{ii,1}.FsHzOut,fList,mObj.Data.bufferSize_s,'gabor','Gabor features','mono');
%                             % Add signal to the data object
%                             mObj.Data.addSignal(sig);
%                         end
%                     % TO DO: Populate that list further
%                     
%                     % N.B: No need for "otherwise" case once complete
%                     
%                     otherwise
%                         error('%s is not supported at the moment',...
%                             dep_list{ii+1});
%                 end
                
                %% New instantiation
                
                % Get the name of the processor to instantiate
                procName = Processor.findProcessorFromRequest(dep_list{ii-n_proc},p);
                
                
                % Check if one or two processors should be instantiated (mono or stereo)
                procInfo = feval([procName '.getProcessorInfo']);
                if size(dependency,2) == 2 && procInfo.isBinaural == 0
                    % Instantiate two processors, each having a single-channel dependency
                    newProc_l = mObj.addSingleProcessor(procName, p, dependency(1), 1, ...
                                                        ii, 'stereo');
                    newProc_r = mObj.addSingleProcessor(procName, p, dependency(2), 2, ...
                                                        ii, 'stereo');
                    dependency = {newProc_l, newProc_r};
                elseif numel(dependency) == 1 && size(dependency{1}.Output,2) == 2
                    % Instantiate two processors, each having the same multi-channel
                    % dependency
                    newProc_l = mObj.addSingleProcessor(procName, p, dependency, 1, ...
                                                        ii, 'stereo');
                    newProc_r = mObj.addSingleProcessor(procName, p, dependency, 2, ...
                                                        ii, 'stereo');
                    dependency = {newProc_l, newProc_r};
                else
                    if procInfo.isBinaural == 1 && ~mObj.Data.isStereo
                        warning(['Cannot instantiate a binaural processor with a '...
                            'mono input signal!'])
                        proceed = 0;
                    else
                        % Instantiate a single processor having a single dependency
                        newProc = mObj.addSingleProcessor(procName, p, dependency, 1, ii,...
                                                            'mono');
                        dependency = {newProc};
                    end
                end
                
                
                %% Old code again, commented for folding
                % Instantiate processors
%                 mObj.Processors{ii,1} = feval(procName, dep_proc{1}.FsHzOut, p);
%                 if mObj.Data.isStereo && ~mObj.Processors{ii,1}.isBinaural
%                     mObj.Processors{ii,2} = feval(procName, dep_proc{1}.FsHzOut, p);
%                 end
%                 
%                 mObj.findInitProc(mObj.Processors{ii,1}.getProcessorInfo.requestName,p) == dep_proc{1}
%                 
%                 % Link to dependencies
%                 if mObj.Processors{ii,1}.isBinaural
%                     mObj.Processors{ii,1}.Dependencies = dep_proc;
%                 else
%                     mObj.Processors{ii,1}.Dependencies = dep_proc(1);
%                     if mObj.Data.isStereo
%                         mObj.Processors{ii,2}.Dependencies = dep_proc(2);
%                     end
%                 end
%                 
%                 % Instantiate output signal
%                 sig = {feval(mObj.Processors{ii,1}.getProcessorInfo.outputType,...
%                             mObj.Processors{ii,1},...
%                             mObj.Data.bufferSize_s,...
%                             'mono')};
%                 if (mObj.Data.isStereo && ~mObj.Processors{ii,1}.isBinaural) || ...
%                         mObj.Processors{ii,1}.hasTwoOutputs
%                     sig = [sig feval(mObj.Processors{ii,1}.getProcessorInfo.outputType,...
%                                     mObj.Processors{ii,1},...
%                                     mObj.Data.bufferSize_s,...
%                                     'mono')];
%                 end
%                         
%                         
%                       
%                 % Add signal to the Data object
%                 mObj.Data.addSignal(sig);
                
%                 if ~isempty(mObj.Processors{ii})
%                 
%                     % Add input/output pointers, dependencies, and update dependencies.
%                     % Three possible scenarios:
% 
%                     if mObj.Processors{ii}.isBinaural
% 
%                         if ~mObj.Processors{ii}.hasTwoOutputs
%                             % 1-Then there are two inputs (left&right) and one output
%                             mObj.InputList{ii,1} = dep_sig_l;
%                             mObj.InputList{ii,2} = dep_sig_r;
%                             mObj.OutputList{ii,1} = sig;
%                             mObj.OutputList{ii,2} = [];
% 
%                             mObj.Processors{ii}.Input{1} = dep_sig_l;
%                             mObj.Processors{ii}.Input{2} = dep_sig_r;
%                             mObj.Processors{ii}.Output = sig;
% 
%                             mObj.Processors{ii,1}.Dependencies = {dep_proc_l,dep_proc_r};
%                             dep_sig = sig;
%                             dep_proc = mObj.Processors{ii};
%                         else
%                             if exist('sig','var')&&strcmp(sig.Channel,'mono')
%                                 % 1bis - Two inputs and two outputs
%                                 mObj.InputList{ii,1} = dep_sig;
%                                 mObj.OutputList{ii,1} = sig;
% 
%                                 mObj.Processors{ii}.Input = dep_sig;
%                                 mObj.Processors{ii}.Output = sig;
% 
%                                 mObj.Processors{ii,1}.Dependencies = {dep_proc};
%                                 dep_sig = sig;
%                                 dep_proc = mObj.Processors{ii};
%                             else
%                                 % 1bis - Two inputs and two outputs
%                                 mObj.InputList{ii,1} = dep_sig_l;
%                                 mObj.InputList{ii,2} = dep_sig_r;
%                                 mObj.OutputList{ii,1} = sig_l;
%                                 mObj.OutputList{ii,2} = sig_r;
% 
%                                 mObj.Processors{ii}.Input{1} = dep_sig_l;
%                                 mObj.Processors{ii}.Input{2} = dep_sig_r;
% %                                 mObj.Processors{ii}.Output{1} = sig_l;
% %                                 mObj.Processors{ii}.Output{2} = sig_r;
%                                 mObj.Processors{ii}.Output = sig_l;
%                                 
% 
% 
%                                 mObj.Processors{ii,1}.Dependencies = {dep_proc_l,dep_proc_r};
%                                 dep_sig_l = sig_l;
%                                 dep_sig_r = sig_r;
%                                 dep_proc_l = mObj.Processors{ii};
%                                 dep_proc_r = mObj.Processors{ii};
%                             end
%                         end
%                     elseif exist('sig','var')&&strcmp(sig.Channel,'mono') && proceed
% 
%                         % 2-Then there is a single input and single output
%                         mObj.InputList{ii,1} = dep_sig;
%                         mObj.OutputList{ii,1} = sig;
% 
%                         mObj.Processors{ii}.Input = dep_sig;
%                         mObj.Processors{ii}.Output = sig;
% 
%                         mObj.Processors{ii}.Dependencies = {dep_proc};
%                         dep_sig = sig;
%                         dep_proc = mObj.Processors{ii};
% 
%                     elseif ~proceed
% 
%                         % Do nothing, this request is invalid and should be
%                         % skipped
% 
%                     else
% 
%                         % 3-Else there are two inputs and two outputs
%                         mObj.InputList{ii,1} = dep_sig_l;
%                         mObj.InputList{ii,2} = dep_sig_r;
%                         mObj.OutputList{ii,1} = sig_l;
%                         mObj.OutputList{ii,2} = sig_r;
% 
%                         mObj.Processors{ii,1}.Input = dep_sig_l;
%                         mObj.Processors{ii,2}.Input = dep_sig_r;
%                         mObj.Processors{ii,1}.Output = sig_l;
%                         mObj.Processors{ii,2}.Output = sig_r;
% 
%                         mObj.Processors{ii,1}.Dependencies = {dep_proc_l};
%                         mObj.Processors{ii,2}.Dependencies = {dep_proc_r};
%                         dep_sig_l = sig_l;
%                         dep_sig_r = sig_r;
%                         dep_proc_l = mObj.Processors{ii,1};
%                         dep_proc_r = mObj.Processors{ii,2};
% 
%                     end
%                     
%                 else
%                     % Then the processor was not instantiated as the
%                     % request was invalid, exit the for loop
%                     break
%                 end
% 
%                 
%                 % Clear temporary handles to ensure no inconsistencies 
%                 clear sig sig_l sig_r
                
%% Resume
            end
            
            % The mapping at this point is linear
            mObj.Map(n_proc+1:n_proc+n_new_proc) = n_proc+1:n_proc+n_new_proc;
            
            % Provide the user with a pointer to the requested signal
            if nargout>0 && proceed
                if ~isempty(dep_list)
                    if size(mObj.Processors,2)==2
                        if isempty(mObj.Processors{n_proc+n_new_proc,2})
                            out{1} = mObj.Processors{n_proc+n_new_proc,1}.Output{1};
                        else
                            out{1,1} = mObj.Processors{n_proc+n_new_proc,1}.Output{1};
                            out{1,2} = mObj.Processors{n_proc+n_new_proc,2}.Output{1};
                        end
                    else
                        out{1} = mObj.Processors{n_proc+n_new_proc,1}.Output{1};
                    end
                else
                    % Else no new processor was added as the requested one
                    % already existed
                    if size(initProc,2)==2
                        out{1,1} = initProc{1}.Output{1};
                        out{1,2} = initProc{2}.Output{1};
                    elseif size(initProc{1}.Output,2) == 2
                        out{1,1} = initProc{1}.Output{1};
                        out{1,2} = initProc{1}.Output{2};
                    else
                        out{1} = initProc{1}.Output{1};
                    end
                end
            elseif ~proceed
                % The request was invalid, return a empty handle
                out = [];
                
                % And remove the processors added by mistake
                if ~isempty(mObj.Processors{n_proc+1})
                    mObj.Processors{n_proc+1}.remove;
                    mObj.cleanup;
                end
            end
            
        end
        
        function cleanup(mObj)
            %CLEANUP  Clears the list of processors from handles to deleted processors
            
            %N.B.: We cannot use cellfun here as some elements of the .Processors array
            %are empty (e.g. when using binaural processors)
            
            % Loop through all elements to remove invalid handles
            for ii = 1:numel(mObj.Processors)
                if ~isempty(mObj.Processors{ii}) && ~isvalid(mObj.Processors{ii})
                    mObj.Processors{ii} = [];
                end
            end
            
            % Removes whole lines of empty elements from the list
            mObj.Processors( all( cellfun( @isempty, mObj.Processors), 2), : ) = [];
            
        end
        
        function reset(mObj)
            %reset  Resets the internal states of all instantiated processors
            %
            %USAGE:
            %  mObj.reset
            %
            %INPUT ARGUMENTS
            %  mObj : Manager instance
            
            % Is the manager working on a binaural signal?
            if size(mObj.Processors,2)==2
                
                % Then loop over the processors
                for ii = 1:size(mObj.Processors,1)
                   
                    % There should always be a processor for left/mono
                    mObj.Processors{ii,1}.reset;
                    
                    % Though there might not be a right-channel processor
                    if isa(mObj.Processors{ii,2},'Processor')
                        mObj.Processors{ii,2}.reset;
                    end
                        
                end
                
            else
            
                % Loop over the processors
                for ii = 1:size(mObj.Processors,1)
                    
                    mObj.Processors{ii,1}.reset;
                        
                end
            end
            
        end
        
    end
    
    methods (Access = protected)
       
        function [hProc,list] = findInitProc(mObj,request,p)
            %findInitProc   Find an initial compatible processor for a new
            %               request
            %
            %USAGE:
            %         hProc = mObj.findInitProc(request,p)
            %  [hProc,list] = mObj.findInitProc(request,p)
            %
            %INPUT PARAMETERS
            %    mObj : Manager instance
            % request : Requested signal name
            %       p : Parameter structure associated to the request
            %
            %OUTPUT PARAMETERS
            %   hProc : Handle to the highest processor in the processing 
            %           chain that is compatible with the provided
            %           parameters. In case two instances exist for the
            %           processor for a stereo signal, hProc is a cell
            %           array of the form {'leftEarProc','rightEarProc'}
            %    list : List of signal names that need to be computed,
            %           starting from the output of hProc, to obtain the
            %           request
        
            % Input parameter checking
%             if nargin<3 || isempty(p)
%                 % Initialize parameter structure
%                 p = struct;
%             end
%             if ~isfield(p,'fs')
%                 % Add sampling frequency to the parameter structure
%                 p.fs = mObj.Data.input{1}.FsHz;
%             end
%             % Add default values for parameters not explicitly defined in p
%             p = parseParameters(p);
%         
            % Try/Catch to check that the request is valid
%             try
%                 getDependencies(request);
%             catch err
%                 % Buid a list of available signals for display
%                 list = getDependencies('available');
%                 str = [];
%                 for ii = 1:size(list,2)-1
%                     str = [str list{ii} ', ']; %#ok
%                 end
%                 % Return the list
%                 error(['The requested signal, %s is unknown. '...
%                     'Valid names are as follows: %s'],request,str)
%             end
            
            % Get the full list of dependencies corresponding to the request
%             if ~strcmp(request,'time')
%                 dep_list = [request getDependencies(request)];
%             else
%                 % Time is a special case as it is listed as its own dependency
%                 dep_list = getDependencies(request);
%             end
            dep_list = [request ...
                Processor.getDependencyList( ...
                Processor.findProcessorFromRequest(request,p), p)];
            
            
            % Initialization of while loop
            ii = 1;
%             dep = signal2procName(dep_list{ii},p);
            dep = Processor.findProcessorFromRequest(dep_list{ii},p);
            hProc = mObj.hasProcessor(dep,p);
            list = {};
            
            % Looping until we find a suitable processor in the list of
            % dependency
            while hProc == 0 && ii<size(dep_list,2)
                
                % Then we will need to re-compute that signal
                list = [list dep_list{ii}]; %#ok
                
                % Move on to next level of dependency
                ii = ii + 1;
%                 dep = signal2procName(dep_list{ii},p);
                dep = Processor.findProcessorFromRequest(dep_list{ii},p);
                hProc = mObj.hasProcessor(dep,p);
                
            end
            
            if hProc == 0
                % Then all the signals need recomputation, including time
                list = [list dep_list{end}];
                
                % Return a empty handle
                hProc = [];
            end
            
            % If the processor found operates on the left channel of a stereo
            % signal, we need to find its twin processor in charge of the
            % right channel
            if ~isempty(hProc) && numel(hProc.Output) == 1 && ...
                    strcmp(hProc.Output{1}.Channel,'left')
                
                % Then repeat the same loop, but specifying the "other"
                % channel
                Channel = 'right';
                
                % Initialization of while loop
                ii = 1;
                dep = Processor.findProcessorFromRequest(dep_list{ii},p);
%                 dep = signal2procName(dep_list{ii},p);
                hProc2 = mObj.hasProcessor(dep,p,Channel);
                list = {};

                % Looping until we find a suitable processor in the list of
                % dependency
                while hProc2 == 0 && ii<size(dep_list,2)

                    % Then we will need to re-compute that signal
                    list = [list dep_list{ii}];     %#ok

                    % Move on to next level of dependency
                    ii = ii + 1;
%                     dep = signal2procName(dep_list{ii},p);
                    dep = Processor.findProcessorFromRequest(dep_list{ii},p);
                    hProc2 = mObj.hasProcessor(dep,p,Channel);

                end
                
                % Quick check that both found processor have the same task
                % (else there was probably an issue somewhere in channel
                % attribution)
%                 if ~strcmp(class(hProc),class(hProc2))
%                     error('Found different processors for left and right channels.')
%                 end
                
                % Put results in a cell array
                hProc = {hProc hProc2};
                
            else
                if ~isempty(hProc)
                    hProc = {hProc};
                end
            end
            
        end
        
        function newProcessor = addSingleProcessor(mObj,procName,parameters, ...
                                                dependencies,channelNb,index,channelTag)
            %addSingleProcessor     Instantiates a new processor and integrates it to the
            %                       manager instance
            %
            % Note about channelNb: 1 for left or mono, 2 for right. 
            %                       channelTag is 'mono' or 'stereo'
            %
            % The following steps are carried out:
            %   - Instantiate a processor, add a pointer to it in mObj.Processors
            %   - Generate a mutual link to its dependency
            %   - Instantiate a new output signal (possibly multiple)
            %   - Link it/them as output(s) of the processor
            %   - Provide link to the input signal(s)
            
            
            % TODO: test if index is necessary (to make use of preallocation), remove else
            if nargin<5||isempty(index)
                index = size(mObj.Processors,1)+1;
            end
            
            % Instantiate processor and add it to the list
            newProcessor = feval(procName, dependencies{1}.FsHzOut, parameters);
            mObj.Processors{index,channelNb} = newProcessor;
            
            % Labeling channels
            % TODO: Could be more flexible, to allow e.g., multi-channel processors
            if strcmp(channelTag,'mono')
                newProcessor.Channel = 'mono';
            else
                if channelNb == 1
                    newProcessor.Channel = 'left';
                else
                    newProcessor.Channel = 'right';
                end
            end
            
            % Mutual link to dependencies, unless it has none
            % IVO Comment: Maybe get the linked list of processors outside of the
            % processors, e.g. in a separate object/class
            if ~strcmp(newProcessor.getDependency,'input')
                newProcessor.addLowerDependencies(dependencies);
            end
            
            % Finalize processor initialization
            newProcessor.prepareForProcessing;
            
            % Instantiate and integrate new output signal
            output = newProcessor.instantiateOutput(mObj.Data);
            newProcessor.addOutput(output);
            
            % Integrate input signal pointer
            newProcessor.addInput(dependencies);
            
        end
            
            
            
        
    end
    
end