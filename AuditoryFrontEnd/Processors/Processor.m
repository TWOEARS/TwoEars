classdef Processor < handle
%PROCESSOR Superclass for the auditory front-end (AFE) framework processors.
%   This abstract class defines properties and methods that are shared among all processor
%   classes of the AFE.
%
%   PROCESSOR properties:
%       Type          - Describes briefly the processing performed
%       Input         - Handle to input signal
%       Output        - Handle to output signal
%       FsHzIn        - Sampling frequency of input (i.e., prior to processing)
%       FsHzOut       - Sampling frequency of output (i.e., resulting from processing)
%       Dependencies  - Handle to the processor that generated this processor's input
%       isBinaural    - Flag indicating the need for two inputs
%       hasTwoOutputs - Flag indicating the need for two outputs
%
%   PROCESSOR abstract methods (implemented by each subclasses):
%       processChunk  - Returns the output from the processing of a new chunk of input
%       reset         - Resets internal states of the processor, if any
%       hasParameters - Returns true if the processor uses the parameters passed as input
%
%   PROCESSOR methods:
%       getDependentParameter - Returns the value of a parameter used in a dependency
%       getCurrentParameters  - Returns the parameter values used by this processor
%
%   See also Processors (folder)

    properties
        Type
    end
    
    properties (Hidden = true)
        Input = {};
        Output = {};
        isBinaural = false;
        hasTwoOutputs = false;
        FsHzIn
        FsHzOut
        UpperDependencies = {};
        LowerDependencies = {};
        Channel
        parameters
    end

    properties (GetAccess = private)
        bHidden = 0;
        listenToModify = [];
        listenToDelete = [];
    end
    
%     properties (GetAccess = protected)
%         parameters
%     end
    
    events
        hasChanged;
        isDeleted;
    end

    methods (Abstract = true)
        out = processChunk(pObj,in)
            % This method should implement the way the processing is
            % handled in the children classes.
        
        reset(pObj)    
            % This method is called any time a change of parameter implying
            % incompatibility with the stored states of the processor is
            % carried out. The method should reset the states of all
            % filters, and reinitialize components of the processor.
            %
            % TO DO: This might take additional input arguments. TBD
            
            
    end
    
    methods
        function pObj = Processor(fsIn,fsOut,procName,parObj)
            %Super-constructor
            
            if nargin>0
            
            % Store specific parameters only
            pObj.parameters = parObj.getProcessorParameters(procName);
            
            % Populate properties
            pInfo = feval([procName '.getProcessorInfo']);
            pObj.Type = pInfo.name;
            pObj.FsHzIn = fsIn;
            pObj.FsHzOut = fsOut;
%             pObj.Dependencies = feval([procName '.getDependency']);
            
            pObj.extendParameters;
            pObj.verifyParameters;
            
            end
            
        end
        
        function  parValue = getDependentParameter(pObj,parName)
            %getDependentParameter   Finds the value of a parameter in the
            %                        list of dependent processors
            %
            %USAGE:
            %  parValue = pObj.getDependentParameter(parName)
            %
            %INPUT PARAMETERS:
            %      pObj : Processor instance
            %   parName : Parameter name
            %
            %OUTPUT PARAMETERS:
            %  parValue : Value for that parameter. Returns an empty output
            %             if no parameter with the provided name was 
            %             found in the list of dependent processors.
            
            %TODO: Will have to be changed for processors with multiple
            %dependencies
            
            if nargin<2 || isempty(parName)
                warning('%s: No parameter name was specified',mfilename)
                parValue = [];
                return
            end
            
            % Initialization
            parValue = [];
            proc = pObj;
            
            while isempty(parValue)
                
                if proc.parameters.map.isKey(parName)
                    parValue = proc.parameters.map(parName);
                else
                    if numel(proc.LowerDependencies) == 0 ...
                            ||  isempty(proc.LowerDependencies{1})
                        break
                    end
                    proc = proc.LowerDependencies{1};
                end
                
            end
            
        end
        
        function propValue = getDependentProperty(pObj,propName)
            %getDependentParameter   Finds the value of a property in the
            %                        list of dependent processors
            %
            %USAGE:
            %  parValue = pObj.getDependentProperty(propName)
            %
            %INPUT PARAMETERS:
            %      pObj : Processor instance
            %  propName : Property name
            %
            %OUTPUT PARAMETERS:
            % propValue : Value for that property. Returns an empty output
            %             if no property with the provided name was 
            %             found in the list of dependent processors.
            
            if nargin<2 || isempty(propName)
                propValue = [];
                return
            end
            
            % Initialization
            propValue = [];
            proc = pObj.LowerDependencies{1};
            
            while isempty(propValue)
                
                if isprop(proc,propName)
                    propValue = proc.(propName);
                else
                    if numel(proc.LowerDependencies) == 0 ...
                            ||  isempty(proc.LowerDependencies{1})
                        break
                    end
                    proc = proc.LowerDependencies{1};
                end
                
            end
            
            
        end
        
        function parObj = getCurrentParameters(pObj,bRecursiveList)
            %getCurrentParameters  This methods returns a list of parameter
            %values used by a given processor.
            %
            %USAGE:
            %   parObj = pObj.getCurrentParameters
            %   parObj = pObj.getCurrentParameters(full_list)
            %
            %INPUT PARAMETERS:
            %           pObj : Processor object instance
            % bRecursiveList : Set to true to return also the parameter values
            %                  used by parent processors.
            %
            %OUTPUT PARAMETERS:
            %   parObj : Parameter object instance
            
            % TODO: Will have to be modified when introducing processors
            % with multiple parents.
            
            if nargin<2||isempty(bRecursiveList)
                bRecursiveList = 0;
            end
            
            % Make a copy of the processor parameter
            parObj = pObj.parameters.copy;
            
            % Add dependencies if necessary
            if bRecursiveList && ~isempty(pObj.Dependencies{1})
                while 1
                    if ~isempty(pObj.Dependencies{1})
                        pObj = pObj.Dependencies{1};
                    else
                        break
                    end
                    parObj.appendParameters(pObj.parameters)
                end
            end
            
            
        end
        
        function hp = hasParameters(pObj,parObj)
            %TODO: Write h1
            
%             % Extract the parameters related to this processor only
%             testParameters = parObj.getProcessorParameters(class(pObj));
%             
%             % Extend it with the default values for this processor
%             testParameters.updateWithDefault(class(pObj))

            % Instantiate a dummy processor
            dummyProc = feval(class(pObj),1,parObj);

            % Compare them with current processor parameters
%             hp = (pObj.parameters == testParameters);
            hp = (pObj.parameters == dummyProc.parameters);
            
            
        end
        
        function modifyParameter(pObj,parName,newValue)
            %MODIFYPARAMETER Requests a change of value of one parameter
            %
            % USAGE:
            %   pObj.modifyParameter('name',value)
            %
            % INPUT ARGUMENTS
            %   pObj : Processor instance
            % 'name' : Parameter name
            %  value : New parameter value
            %
            % SEE ALSO: parameterHelper.m
            
            
            if ~ismember(parName,Processor.blacklistedParameters) 
                
                % Check that parName is a parameter of this processor
                if pObj.parameters.map.isKey(parName)
                
                    % Change the parameter value
                    pObj.parameters.map(parName) = newValue;
                    
                    % Solve parameter conflicts and update internal values
                    pObj.verifyParameters;
                    pObj.prepareForProcessing;
                    
                    % Reset the processor internal states and notify listeners
                    pObj.reset;
                    notify(pObj,'hasChanged');
                
                else
                    warning(['Parameter ' parName ' is not a parameter '...
                        'of this processor'])
                end
                
            else
                % This specific parameter is blacklisted for modification due to technical
                % limitations
                warning(['Cannot modify ' parName '. Consider making a new request.'])
            end

        end
        
    end
    
    methods (Access=protected)
        
        function extendParameters(pObj)
            %extendParameters   Add missing parameters in a processor
            
            if ~isprop(pObj,'parameters') || isempty(pObj.parameters)
                pObj.parameters = Parameters;
            end
            
            pObj.parameters.updateWithDefault(class(pObj));
            
        end
        
        function verifyParameters(~)
            % This method is called at setup of a processor parameters, to verify that the
            % provided parameters are valid, and correct conflicts if needed.
            % Not needed by many processors, hence is not made abstract, but need to be
            % overriden in processors where it is needed.
        end
        
    end
    
    methods (Hidden = true)
        
        function addUpperDependencies(pObj,dependentProcs)
            %ADDUPPERDEPENDENCIES   Populate link to higher processors relying on this one
            
            pObj.UpperDependencies = [pObj.UpperDependencies dependentProcs];
            
        end
        
        function removeUpperDependency(pObj,upperProc)
            %REMOVEUPPERDEPENDENCY   Removes a processor from the upper dependency list
            
            for ii = 1:size(pObj.UpperDependencies,2)
                if pObj.UpperDependencies{ii} == upperProc
                    pObj.UpperDependencies{ii} = [];
                end
            end
            
            % Clean up empty elements
            pObj.UpperDependencies = ...
                pObj.UpperDependencies( ~cellfun( @isempty, pObj.UpperDependencies ));
            
        end
        
        function addLowerDependencies(pObj,dependentProcs)
            %ADDLOWERDEPENDENCIES   Populate link to lower processors this one relies on.
            % Likewise, will will add the current processor as an upper dependency in
            % those processors.
            % This method will also attach a listener to the current processor that
            % listens to changes in the lower-dependent processor.
            
            pObj.LowerDependencies = [pObj.LowerDependencies dependentProcs];
            for ii = 1:size(dependentProcs,2)
                dependentProcs{ii}.addUpperDependencies({pObj});
            end
            
            % Temporary fix for single dependencies
            proc = dependentProcs{1};
            
            % Add modify and delete listeners to the lower dependent processor
            pObj.listenToModify = addlistener(proc,'hasChanged',@pObj.update);
            pObj.listenToModify = addlistener(proc,'isDeleted',@pObj.remove);
            
            
            
        end
        
        function removeHandleInLowerDependencies(pObj)
            %REMOVEHANDLEINLOWERDEPENDENCY  Removes the processor from the upper
            %dependencies list of its dependencies
            
            try
                for ii = 1:size(pObj.LowerDependencies,2)
                    if isvalid(pObj.LowerDependencies{ii})
                        pObj.LowerDependencies{ii}.removeUpperDependency(pObj);
                    end
                end
            catch
                disp(['Processor ' pObj.Type ' is causing trouble!'])
            end
            
        end
        
        function addInput(pObj,dependency)
            %ADDINPUT   Adds a signal to the list of input of the processor
            % Will consider that the input signal is the output of the dependency. If
            % the dependency has a left- and right-channel output, will pick the suitable
            % one.
            % Three cases are implemented here:
            % 1- single dependency with single output
            % 2- two dependencies (left and right channels) with each single output
            % 3- single dependency with left and right outputs (e.g., pre-processor)
            
            % Should the input attribution works in any other way for a given processor,
            % this method should be overloaded for that specific children processor.
            
            % NB: 'dependency' should be a cell array with a handle to a single processor,
            % with a single output, or maximally one output per channel.
            
            returnError = 0;
            
            % Return error if trying to have multiple inputs
            if ~isempty(pObj.Input)
                returnError = 1;
            end
            
            if numel(dependency) == 1
                if numel(dependency{1}.Output) == 1
                    % Case 1: single-channel processor
                    pObj.Input{1} = dependency{1}.Output{1};
                    
                elseif size(dependency{1}.Output,2) == 2
                    % Case 3: Dependency is a multi-channel processor
                    % TODO: They should be already be ordered, the following check should be
                    % removed after testing and is here for debugging only.
                    if strcmp(pObj.Channel,'left')
                        pObj.Input{1} = dependency{1}.Output{1};
                    else
                        pObj.Input{1} = dependency{1}.Output{2};
                    
%                     if strcmp(dependency{1}.Output{1}.Channel,'left') && ...
%                             strcmp(dependency{1}.Output{2}.Channel,'right')
%                         pObj.Input{1,1} = dependency{1}.Output{1};
%                         pObj.Input{1,2} = dependency{1}.Output{2};
%                     elseif strcmp(dependency{1}.Output{1}.Channel,'right') && ...
%                             strcmp(dependency{1}.Output{2}.Channel,'left')
%                         pObj.Input{1,1} = dependency.Output{2};
%                         pObj.Input{1,2} = dependency.Output{1};
%                         warning('Outputs of dependent processors were incorrectly ordered, consider investigating.')
%                     else
%                         error('Something is wrong with the outputs of the dependent processor, investigate.')
                    end
                    
                else
                    returnError = 1;
                end
            elseif size(dependency,2) == 2
                % Case 2: Binaural input processor
                % TODO: Remove the following check once tested
                if numel(dependency{1}.Output) == 1 && numel(dependency{2}.Output) == 1
                    pObj.Input{1,1} = dependency{1}.Output{1};
                    pObj.Input{1,2} = dependency{2}.Output{1};
                else
                    error('Something is wrong with the outputs of the dependent processor, investigate.')
                end
            else
                returnError = 1;
            end
            
            if returnError
                error(['Cannot add input for that specific processor. Consider ' ...
                    'overloading this method in the children processor class '...
                    'definition.'])
            end
            
%             % Number of already existing inputs
%             ii = size(pObj.Input,2);
%             
%             if size(dependency.Output,2) == 1
%                 % Then it is a single output -> single input scenario
%                 pObj.Input{ii+1,1} = dependency.Output{1};
%                 
%             else
%                 % Then the dependency has two outputs corresponding to two channels
%                 
%                 % TODO: They should be already be ordered, the following check should be
%                 % removed after testing and is here for debugging only.
%                 if strcmp(dependency.Output{1}.Channel,'left') && ...
%                         strcmp(dependency.Output{2}.Channel,'right')
%                     pObj.Input{ii+1,1} = dependency.Output{1};
%                     pObj.Input{ii+1,2} = dependency.Output{2};
%                 elseif strcmp(dependency.Output{1}.Channel,'right') && ...
%                         strcmp(dependency.Output{2}.Channel,'left')
%                     pObj.Input{ii+1,1} = dependency.Output{2};
%                     pObj.Input{ii+1,2} = dependency.Output{1};
%                     warning('Outputs of dependent processors were incorrectly ordered, consider investigating.')
%                 else
%                     error('Something is wrong with the outputs of the dependent processor, investigate.')
%                 end
%             end
            
        end
        
        function addOutput(pObj,sObj)
            %ADDOUTPUT  Adds a signal to the list of output of the processor
            
            if iscell(sObj)
                % Then there are multiple outputs, pseudo-recursive call
                for ii = 1:numel(sObj)
                    pObj.addOutput(sObj{ii});
                end
            else
                if isempty(pObj.Output)
                    pObj.Output{1} = sObj;
                elseif numel(pObj.Output) == 1
                    if strcmp(pObj.Output{1}.Channel,'left') ...
                            && strcmp(sObj.Channel,'right')
                        pObj.Output{2} = sObj;
                    elseif strcmp(pObj.Output{1}.Channel,'right') ...
                            && strcmp(sObj.Channel,'left')
                        % Then need to reverse the output order
                        pObj.Output{2} = pObj.Output{1};
                        pObj.Output{1} = sObj;
                    else
                        error('Something was wrong in the outputs of this processor')
                    end
                else
                    error(['Cannot add multiple output to this processor. Consider ' ...
                        'overloading the addOutput method in that case'])
                end
                
%                 % Which column in the cell array should the signal go?
%                 if strcmp(sObj.Channel,'right')
%                     jj = 2;
%                 elseif strcmp(sObj.Channel,'left') || strcmp(sObj.Channel,'mono')
%                     jj = 1;
%                 else    % NB: Will be removed after testing
%                     error('Need to specify a channel for output signal')
%                 end
% 
%                 ii = max(size(pObj.Output,1),1);
% 
%                 if isempty(pObj.Output) || size(pObj.Output,2)<jj ...
%                                         || isempty(pObj.Output{ii,jj})
%                     pObj.Output{ii,jj} = sObj;
%                 else
%                     % Then sObj is an additional output and should be put on another line
%                     pObj.Output{ii+1,jj} = sObj;
%                 end
            end
            
        end
        
        function output = instantiateOutput(pObj,dObj)
            %INSTANTIATEOUTPUT  Instantiate the output signal for this processor
            %
            %NB: This method can be overloaded in children processor where output differs
            %from standard (e.g., multiple output or additional inputs to the signal
            %constructor).
            
            sig = feval(pObj.getProcessorInfo.outputType, ...
                        pObj, ...
                        dObj.bufferSize_s, ...
                        pObj.Channel);
            
            dObj.addSignal(sig);
            
            output = {sig};
            
        end
        
        function initiateProcessing(pObj)
            %INITIATEPROCESSING    Wrapper calling the processChunk method and routing I/O
            % Main purpose is to allow overloading of I/O routing in processors with
            % "unusual" number of input/outputs.
            
            % Two cases considered here, monaural and binaural processors producing single
            % outputs. In other cases, the method should be overloaded in the particular
            % processor.
            
            if size(pObj.Input,1) > 1 || numel(pObj.Output) > 1
                % Then it is a multiple-input processor, return an error
                error(['Cannot initiate the processing for this ' ...
                    'processor. Consider overloading this method in the children ' ... 
                    'class definition.'])
            
            elseif size(pObj.Input,2) == 1
                % Then monaural processor
                pObj.Output{1}.appendChunk( ...
                    pObj.processChunk( pObj.Input{1}.Data('new')));
                
            elseif size(pObj.Input,2) == 2
                % Then binaural processor
                pObj.Output{1}.appendChunk( ...
                    pObj.processChunk( ...
                        pObj.Input{1}.Data('new'), pObj.Input{2}.Data('new')));
                
                
            else
                % TODO: Remove after testing
                error('Something is wrong with the inputs of this processor, investigate.')
            end
            
        end
        
        function bInBranch = isSuitableForRequest(~)
            %ISSUITABLEFORREQUEST: Tests if a processor is compatible with a request. Used
            %in cases where multiple alternatives exist for a given processing step (e.g.,
            %Gammatone filterbank vs. DRNL). 
            %This method should be overridden in the class definition of such processors,
            %to return a boolean indicating if said processor should or not be used in the
            %processing chain.
            %
            %USAGE
            %  bInBranch = pObj.isSuitableForRequest
            %
            %INPUT ARGUMENTS:
            %   pObj : Processor instance. Usually a dummy (empty) processor is used, as
            %          static methods cannot be overridden.
            %
            %OUTPUT ARGUMENTS:
            % bInBranch : Boolean indicating if the processor should be included in the
            %             processing branch or not.
            
            bInBranch = true;
            
        end
        
        function update(pObj,procRequestingUpdate,~)
            %UPDATE Update the processor in response to a change notification
            % This method is called when a lower-dependent processor has been modified, or
            % updated itself. Usually, update means only resetting, but this method can be
            % overloaded in children class definitions.
            
            % Display a message for testing purpose
            %disp([pObj.Type ' was reseted due to an update in ' procRequestingUpdate.Type])
            
            % Update means reset
            pObj.reset;
            
            % Notify possible listeners that there was a modification
            notify(pObj,'hasChanged');
            
        end
        
        function remove(pObj,~,~)
            %REMOVE Prepares for deleting the processor
            % REMOVE will remove all the processor references in the framework, which
            % terminates the scope of the handle therefore calling the processor .delete
            % method.
            %
            %N.B.: If the user has stored an additional handle to this processor, then the
            %processor won't be deleted as it will not go out of scope. Is there a
            %solution to this?
            
            % Remove the reference from any dependency list
            
            % Upper dependencies will be removed as well, so no need for cleanup there
            pObj.removeHandleInLowerDependencies;
            
            % NB: Having the notification sent in an overridden (augmented) delete method
            % will cause errors when clearing the workspace. Possibly due to the order in
            % which Matlab calls all destructors when clearing up.
            notify(pObj,'isDeleted');
            
            % Delete the processor
            pObj.delete();
            
            
            
        end
        
        function prepareForProcessing(~)
            %PREPAREFORPROCESSING  Sets up properties depending on outside factors and
            % internal properties that are not parametrized.
            %
            % USAGE:
            %  pObj.prepareForProcessing;
            %
            % This method is called after instantiating and inter-linking the processors
            % into a processing chain, in order to finalize initialization steps which
            % depend on outside factors (such as dependent processors) than processor pObj
            %
            % It is also called after a processor parameter update. Some processors
            % include intermediate parameters that could need to be recomputed.
            %
            % It is left blank here as many processors do not need this additional step.
            % If needed, the method should be overriden in specific processors class
            % definitions.
            
        end

        
    end

    methods (Static)
       
        function pList = processorList()
            %Processor.processorList    Returns a list of valid processor object names
            %
            %USAGE:
            %  pList = Processor.processorList
            %
            %OUTPUT ARGUMENT:
            %  pList : Cell array of valid processor names
            
            % Processors directory
            processorDir = mfilename('fullpath');
            
            % Get file information
            fileList = listFiles(processorDir(1:end-10),'*.m',-1);
            
            % Extract name only
            pList = cell(size(fileList));
            for ii = 1:size(fileList)
                % Get file name
                [~,fName] = fileparts(fileList(ii).name);
                
                % Check if it is a valid processor
                try
                    p = feval(str2func(fName));
                    if isa(p,'Processor') && ~p.bHidden
                        pList{ii} = fName;
                    else
                        pList{ii} = [];
                    end
                catch   % In case fName is not executable without inputs
                    pList{ii} = [];
                end
                
            end
                
            % Remove empty elements
            pList = pList(~cellfun('isempty',pList));
             
        end
        
        function list = requestList()
            %Processor.requestList  Returns a list of supported request names
            %
            %USAGE:
            %   rList = Processor.requestList
            %
            %OUTPUT ARGUMENT:
            %   rList : Cell array of valid requests
            
            % Get a list of processor
            procList = Processor.processorList;
            
            list = cell(size(procList,1),1);
            
            for ii = 1:size(list,1)
                pInfo = feval([procList{ii} '.getProcessorInfo']);
                list{ii} = pInfo.requestName;
            end
            
        end
        
        function procName = findProcessorFromParameter(parameterName,no_warning)
            %Processor.findProcessorFromParameter   Finds the processor that uses a given parameter
            %
            %USAGE:
            %   procName = Processor.findProcessorFromParameter(parName)
            %   procName = Processor.findProcessorFromParameter(parName,no_warning)
            %
            %INPUT ARGUMENT:
            %   parName : Name of the parameter
            %no_warning : Set to 1 (default: 0) to suppress warning message
            %
            %OUTPUT ARGUMENT:
            %  procName : Name of the processor using that parameter

            if nargin<2||isempty(no_warning); no_warning = 0; end
            
            % Get a list of processor
            procList = Processor.processorList;

            % Loop over each processor
            for ii = 1:size(procList,1)
                try
                    procParNames = feval([procList{ii} '.getParameterInfo']);
                    
                    if ismember(parameterName,procParNames)
                        procName = procList{ii};
                        return
                    end
                    
                catch
                    % Do not return a warning here, as this is called in a loop
                end

            end

            % If still running, then we haven't found it
            if ~no_warning
            warning('Could not find a processor which uses parameter ''%s''',...
                    parameterName)
            end
            procName = [];

        end
        
        function procName = findProcessorFromSignal(signalName)
            %Processor.findProcessorFromSignal Finds the processor that generates a signal
            %
            %USAGE:
            %   procName = Processor.findProcessorFromSignal(signalName)
            %
            %INPUT ARGUMENT:
            %   signalName : Name of the signal
            %
            %OUTPUT ARGUMENT:
            %     procName : Name of the processor generating that signal
            
            % TODO: Should be able to return multiple procNames, should there be
            % alternative processors (e.g. Gammatone vs. DRNL)
            
            procList = Processor.processorList;
            procName = cell(0);
            
            for ii = 1:size(procList,1)
                pInfo = feval([procList{ii} '.getProcessorInfo']);
                currentName = pInfo.requestName;
                if strcmp(currentName,signalName)
                    procName = [procName; procList{ii}]; %#ok<AGROW>
                end
            end
            
            % Change to string if single output
            if size(procName,1) == 1
                procName = procName{1};
            end
            
            
            
        end
        
        function procName = findProcessorFromRequest(signalName,parObj)
            %Processor.findProcessorFromRequest Finds the processor name that generates a
            %signal given specific parameters.
            % This method does the same as .findProcessorFromSignal, with the only
            % addition that it will look into the request parameters if multiple
            % processors can generate the signal to find which one should be returned
            
            procName = Processor.findProcessorFromSignal(signalName);
            
            if size(procName,1)>1
                procName = Processor.chooseAlternativeProcessor(procName,parObj);
            end
            
        end
        
        function procName = chooseAlternativeProcessor(procList,parObj,bThrowError)
            % Chooses which processor in a list of alternatives should be used given a
            % request parameters
            
            if nargin<3 || isempty(bThrowError)
                bThrowError = true;
            end
            
            if ~iscell(procList) || size(procList,1)==1
                error('Incorrect input argument. Expecting a list of processor names')
            end
            
            procName = {};
            
            for ii = 1:size(procList,1)
                % Instantiate a dummy processor (suitability checking is not static)
                dummyProc = feval(procList{ii},[],parObj);
                % Check if it is suitable
                if dummyProc.isSuitableForRequest
                    procName = [procName;procList{ii}]; %#ok<AGROW>
                end
            end
            
            if size(procName,1) > 1 
                if bThrowError
                    error(['Processors ' strjoin(procName.',' and ') ' are conflicting.'...
                            ' Check their .isSuitableForRequest methods.'])
                end
            else
                procName = procName{1};
            end
            
        end
        
        function depList = getDependencyList(procName,parObj)
           %getDependencyList   Returns a list of processor names a given processor needs
           
           depList = cell(0);
           
           %TODO: Add a possibility for branching (e.g. Gammatone vs. DRNL) here in the
           %loop, e.g. via a test on the size of procName. Then call a processor-specific
           %method that decides based on a parameter object which one should be
           %instantiated.
           
           if iscell(procName)
               % Multiple processor are possible for that request, find a suitable one
               
               for ii = 1:size(procName,1)
%                    parCopy = parObj.copy;
%                    parCopy.updateWithDefault(procName{ii});
                   dummyProc = feval(procName{ii},[],parObj);
                   if dummyProc.isSuitableForRequest
                       procName = procName{ii};
                       break
                   end
               end
               if iscell(procName)
                   error(['Processors ' strjoin(procName.',' and ') ' are conflicting.'...
                       ' Check their isSuitableForRequest methods.'])
               end
               
           end
           
           
           while ~strcmp(feval([procName '.getDependency']), 'input')
               % Do something here if procName is more than one element. 
               
               depList = [depList feval([procName '.getDependency'])]; %#ok<AGROW>
               procName = Processor.findProcessorFromSignal( ...
                            feval([procName '.getDependency']));
               
               if iscell(procName)
                   % Multiple processor are possible for that request, find a suitable one
                   for ii = 1:size(procName,1)
%                        parCopy = parObj.copy;
%                        parCopy.updateWithDefault(procName{ii});
                       dummyProc = feval(procName{ii},[],parObj);
                       if dummyProc.isSuitableForRequest
                           procName = procName{ii};
                           break
                       end
                   end
                   if iscell(procName)
                       error(['Processors ' strjoin(procName.',' and ') ' are conflicting.'...
                           ' Check their isSuitableForRequest methods.'])
                   end
               end
                        
           end
            
        end
        
        function blackList = blacklistedParameters()
            % Returns the list of parameters that cannot be affected in real-time. Most
            % (all) of them cannot be modified as they involve a change in dimension of
            % the output signal. A work-around allowing changes in dimension might be
            % implemented in the future but remains a technical challenge at the moment.
            %
            % To modify one of these parameters, the corresponding processor should be
            % deleted and a new one, with the new parameter value, instantiated via a 
            % user request.
            
            
            blackList = {   'fb_type',...   % Cannot change auditory filterbank on the fly
                            'fb_lowFreqHz',...
                            'fb_highFreqHz',...
                            'fb_nERBs',...
                            'fb_cfHz'};
            
        end
        
        
    end
    
    
end