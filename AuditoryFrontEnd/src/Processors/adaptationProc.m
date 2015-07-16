classdef adaptationProc < Processor
%ADAPTATIONPROC Adaptation loop processor.
%   The Adaptation loop models corresponds to the adaptive response of 
%   the auditory nerve fibers, in which abrupt changes in the input 
%   result in emphasised overshoots followed by gradual decay to 
%   compressed steady-state level. This is a chain of feedback
%   loops in series, each of which consists of a low-pass filter and a
%   division operator [1,2]. The input to the processor is a time-frequency signal
%   from the inner hair cell, and the output is a time-frequency signal.
%
%   ADAPTATIONPROC properties:
%       overshootLimit      - a limit to the overshoot caused by the loops
%       minLeveldB          - the lowest audible threshhold of the signal (dB)
%       tau                 - Time constants of the loops
%
%   See also: Processor, ihcProc
%
%   Reference:
%   [1] Puschel, D. (1988). Prinzipien der zeitlichen Analyse beim H?ren. University of G?ttingen.
%   [2] Dau, T., Puschel, D., & Kohlrausch, A. (1996). 
%       A quantitative model of the "effective" signal processing 
%       in the auditory system. I. Model structure. 
%       The Journal of the Acoustical Society of America, 99(6), 3615?3622. 
    
    properties (Dependent = true)
     overshootLimit      % limit to the overshoot of the output
     minLeveldB          % the lowest audible threshhold of the signal 
     tau                 % time constants involved in the adaptation loops 
                         % the number of adaptation loops is determined
                         % by the length of tau
    end

    properties (GetAccess = private)
     stateStore         % cell to store previous output
                        % each element has the same length as tau
                        % # of elements depends on the freq. channels
     minLevel           % minLevel converted from dB to signal value

    end
     
    methods
        function pObj = adaptationProc(fs,parObj)
        %adaptationProc   Construct an adaptation loop processor
        %
        % USAGE:
        %   pObj = adaptationProc(fs, parObj)
        %
        % INPUT ARGUMENTS:
        %     fs : Input sampling frequency (Hz)
        % parObj : Parameter object instance
        %
        % OUTPUT ARGUMENTS:
        %   pObj : Processor instance
        %
        % NOTE: Parameter object instance, parObj, can be generated using genParStruct.m
        % User-controllable parameters for this processor and their default values can be
        % found by browsing the script parameterHelper.m
        %
        % See also: genParStruct, parameterHelper, Processor
        
        % TODO: Restore the ability to choose parameters from documented models.
        % Corresponding code with kept here and commented out
        %
        %   model : implementation model as in various related studies
        %
        %     'adt_dau'        Choose the parameters as in the Dau 1996 and 1997
        %                      models. This consists of 5 adaptation loops with
        %                      an overshoot limit of 10 and a minimum level of
        %                      1e-5. This is a correction in regard to the model
        %                      described in Dau et al. (1996a), which did not use 
        %                      overshoot limiting. The adaptation loops have an 
        %                      exponential spacing. This flag is the default.
        %
        %     'adt_puschel'    Choose the parameters as in the original Puschel 1988
        %                      model. This consists of 5 adaptation loops without
        %                      overshoot limiting. The adapation loops have a linear spacing.
        %
        %     'adt_breebaart'  As 'puschel', but with overshoot limiting.
        % 

        if nargin<2||isempty(parObj); parObj = Parameters; end
        if nargin<1; fs = []; end

        % Call super-constructor
        pObj = pObj@Processor(fs,fs,'adaptationProc',parObj);

        % Prepare to convert minLeveldB following level convention
        % convention: 100 dB SPL corresponds to rms 1
        % calibration factor (see Jepsen et al. 2008)
        dBSPLCal = 100;         % signal amplitude 1 should correspond to max SPL 100 dB
        ampCal = 1;             % signal amplitude to correspond to dBSPLRef

        pObj.minLevel = ampCal*10.^((pObj.minLeveldB-dBSPLCal)/20);

        % initialise the stateStore cell
        % the sizes are unknown at this point - determined by the
        % length of cf (given from the input time-frequency signal)
        pObj.stateStore = {};

        % Previous constructor
        %             % check input arguments and set default values
        %             narginchk(2, 4) % support 2 to 4 input arguments
        % 
        %             numVarargs = length(varargin);
        %             
        %             % Default arguments: lim = 0(CASP) vs 10(AMT), min = 1e-5(CASP) vs 0 dB (AMT), 
        %             % tau = [0.005 0.050 0.129 0.253 0.500]
        %             % set default optional arguments
        %             optArgs = {10 0 [0.005 0.050 0.129 0.253 0.500]};
        %             
        %             % overwrite the arguments as specified in varargin
        %             if ischar(varargin(1))      
        %                 % specific model is given
        %                 model = varargin(1);
        %                 switch (model)
        %                     case 'adt_dau'
        %                         % this is the default - optArgs does not change
        %                     case 'adt_puschel'
        %                         % 5 adaptation loops, no overshoot limiting, 
        %                         % linear tau spacing
        %                         optArgs = {0 0 linspace(0.005,0.5,5)};
        %                     case 'adt_breebaart'
        %                         % 5 adaptation loops, with [default] overshoot limiting,
        %                         % linear tau spacing
        %                         optArgs = {10 0 linspace(0.005,0.5,5)};
        %                     otherwise
        %                         % not supported
        %                         error('%s: Unsupported adaptation loop model',upper(mfilename));
        %                 end
        %             else
        %                 % numbers (or something other than string) are given
        %                 % simply overwrite the arguments
        %                 optArgs(1:numVarargs) = varargin;
        %             end
        %             [lim, mindB, taus] = optArgs{:};
        %             
        %             if ~isnumeric(taus) || ~isvector(taus) || any(taus<=0)
        %                 error('%s: "tau" must be a vector with positive values.',upper(mfilename));
        %             end
        % 
        %             if ~isnumeric(mindB) || ~isscalar(mindB)
        %                 error('%s: "mindB" must be a scalar.',upper(mfilename));
        %             end
        % 
        %             if ~isnumeric(lim) || ~isscalar(lim) 
        %                 error('%s: "lim" must be a scalar.',upper(mfilename));
        %             end 
        %                      
        %             % Prepare to convert minLeveldB following level convention
        %             % convention: 100 dB SPL corresponds to rms 1
        %             % calibration factor (see Jepsen et al. 2008)
        %             dBSPLCal = 100;         % signal amplitude 1 should correspond to max SPL 100 dB
        %             ampCal = 1;             % signal amplitude to correspond to dBSPLRef
        % 
        %             % Populate the object's properties
        %             % 1- Global properties
        %             populateProperties(pObj,'Type','Adaptation loop processor',...
        %                  'Dependencies',getDependencies('adaptation'),...
        %                  'FsHzIn',fs,'FsHzOut',fs);
        %             % 2- Specific properties
        %             pObj.overshootLimit = lim;
        %             pObj.minLeveldB = mindB;
        %             % if mindB is given in dB SPL
        %             % convert min dB SPL to numerical value (AMT)
        %             pObj.minLevel = ampCal*10.^((pObj.minLeveldB-dBSPLCal)/20);
        %             pObj.tau = taus;           
        %             % initialise the stateStore cell
        %             % the sizes are unknown at this point - determined by the
        %             % length of cf (given from the input time-frequency signal)
        %             pObj.stateStore = {};

        end
         
        function out = processChunk(pObj,in)
            % On-line chunk-based processing is considered
            % in: time-frequency signal (time (row) x frequency (column))
            % The input level is assumed to follow the "convention" that
            % 100 dB SPL corresponds to signal amplitude of 1
            % To allow for flexibility, configuration should be possible
            % at the beginning...

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % for DRNL - CASP2008: needs some additional steps between IHC and adaptation when
            % DRNL is used (not needed when gammatone filterbank is used)
            % Check whether drnlProc is in the dependency list
            if strcmp(pObj.LowerDependencies{1}.LowerDependencies{1}.Type, ...
                    'drnl filterbank')
                % linear gain to fit ADloop operating point
                in = in*10^(50/20);
                % expansion
                in = in.^2;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            sigLen=size(in, 1);         % signal length = column length
            nChan = size(in, 2);        % # of frequency channels
            nLoops = length(pObj.tau);  % number of loops 

            % If stateStore is not defined yet (for the very
            % first chunk of signal)
            % then preallocate storage space
            if isempty(pObj.stateStore)
                pObj.stateStore = cell(1, nChan);
            end

            % b0 from RC-lowpass recursion relation y(n)=b0*x(n)+a1*y(n-1)
            % a1 coefficient of the upper IIR-filter
            b0 = 1./(pObj.tau*pObj.FsHzIn);
            a1 = exp(-b0);
            b0 = 1-a1;

            % to get a range from 0 to 100 model units
            % corr and mult are fixed throughout the loops
            % (do not vary along frequency channels)
            corr = pObj.minLevel^(1/(2^nLoops));		
            mult = 100/(1-corr);

            % Apply minimum level to the input
            out = max(in, pObj.minLevel);       % dimension same as in

            % Determine steady-state levels. The values are repeated to fit the
            % number of input signals.
            state = pObj.minLevel.^(1./(2.^((1:nLoops))));    

            % Back up the value, because state is overwritten
            stateinit=state;

            if pObj.overshootLimit <=1 
            % No overshoot limitation
                for ch=1:nChan
                    state=stateinit;
                    % If there are state values stored from previous call
                    % of the function, overwrite the starting values with
                    % the stored values
                    if ~isempty(pObj.stateStore{ch})
                        state = pObj.stateStore{ch};
                    end
                    for ii=1:sigLen
                        tmp1=out(ii,ch);
                        % Compute the adaptation loops
                        for jj=1:nLoops
                            tmp1=tmp1/state(jj);
                            state(jj) = a1(jj)*state(jj) + b0(jj)*tmp1;         
                        end   
                        % store the result
                        out(ii,ch)=tmp1;
                    end
                    % Now back up the last state (per freq channel)
                    pObj.stateStore{ch} = state;
                end

            else 
            % Overshoot Limitation

                % Max. possible output value
                maxvalue = (1 - state.^2) * pObj.overshootLimit - 1;
                % Factor in formula to speed it up 
                factor = maxvalue * 2; 			
                % Exponential factor in output limiting function
                expfac = -2./maxvalue;
                offset = maxvalue - 1;

                for ch=1:nChan
                    state=stateinit;
                    % If there are state values stored from previous call
                    % of the function, overwrite the starting values with
                    % the stored values
                    if ~isempty(pObj.stateStore{ch})
                        state = pObj.stateStore{ch};
                    end
                    for ii=1:sigLen
                        tmp1=out(ii,ch);
                        for jj=1:nLoops
                            tmp1=tmp1/state(jj);
                            if ( tmp1 > 1 )
                                tmp1 = factor(jj)/(1+exp(expfac(jj)*(tmp1-1)))-offset(jj);
                            end
                            state(jj) = a1(jj)*state(jj) + b0(jj)*tmp1;
                        end
                    % store the result
                    out(ii,ch)=tmp1;    
                    end
                    % Now back up the last state (per freq channel)
                    pObj.stateStore{ch} = state;                    
                end
            end
            % Scale to model units
            out = (out-corr)*mult;

        end
         
        function reset(pObj)
             %reset     Resets the internal states 
             %
             %USAGE
             %      pObj.reset
             %
             %INPUT ARGUMENTS
             %  pObj : adaptation processor instance
             
             % empty the stateStore cell
            if(~isempty(pObj.stateStore))
                pObj.stateStore = {};
            end
        end
         
     end
     
     % "Getter" methods
     methods
         function limit = get.overshootLimit(pObj)
             limit = pObj.parameters.map('adpt_lim');
         end
         
         function minLeveldB = get.minLeveldB(pObj)
             minLeveldB = pObj.parameters.map('adpt_mindB');
         end
         
         function tau = get.tau(pObj)
             tau = pObj.parameters.map('adpt_tau');
         end
     end
     
     methods (Static)
         function dep = getDependency()
             dep = 'innerhaircell';
         end
         
         function [names, defaultValues, descriptions] = getParameterInfo()
            %getParameterInfo   Returns the parameter names, default values
            %                   and descriptions for that processor
            %
            %USAGE:
            %  [names, defaultValues, description] =  ihcProc.getParameterInfo;
            %
            %OUTPUT ARGUMENTS:
            %         names : Parameter names
            % defaultValues : Parameter default values
            %  descriptions : Parameter descriptions
            
            
            names = {'adpt_lim',...
                     'adpt_mindB',...
                     'adpt_tau'};
            
            descriptions = {'Adaptation loop overshoot limit',...
                            'Adaptation loop lowest signal level (dB)',...
                            'Adaptation loop time constants (s)'};
            
            defaultValues = {10,...
                             0,...
                             [0.005 0.05 0.129 0.253 0.5]};
                
          end
         
          function pInfo = getProcessorInfo
            
             pInfo = struct;
             
             pInfo.name = 'Adaptation loop';
             pInfo.label = 'Neural adaptation model';
             pInfo.requestName = 'adaptation';
             pInfo.requestLabel = 'Adaptation loop output';
             pInfo.outputType = 'TimeFrequencySignal';
             pInfo.isBinaural = 0;
             
         end
         
     end
     
 end