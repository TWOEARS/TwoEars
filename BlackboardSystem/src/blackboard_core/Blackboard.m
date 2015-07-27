classdef Blackboard < handle
    %Blackboard   A blackboard that solves the stage 1 task
    %   Detailed explanation goes here
    
    properties (SetAccess = {?BlackboardSystem})
        KSs = {};                       % List of all KSs
        signals = [];                   % Layer 1a-2: _handles_ to  requested signals from Two!Ears Auditory Front-End
        data = [];                      % general data storage Map, with currentSoundTimeIdx as key
        dataLabels = {};                % list of data labels
        verbosity = 0;                  % Verbosity of 0 switches off screen output
        currentSoundTimeIdx = 0;        % the current "sound time". 
                                        % Has to be set when a new signal
                                        % chunk arrives
    end
    
    methods
        %% Class constructor
        function obj = Blackboard(verbosity)
            if exist('verbosity', 'var')
                obj.verbosity = verbosity;
            end
            obj.data = containers.Map( 'KeyType', 'double', 'ValueType', 'any' );
        end
        
        %% utility function for printing the obj
        function s = char( obj )
            mcobj = metaclass ( obj );
            s = mcobj.Name;
        end
        
        %% Set currentSoundTimeIdx
        function obj = setSoundTimeIdx( obj, newSoundTimeIdx )
            if newSoundTimeIdx <= obj.currentSoundTimeIdx
                error( 'time has to be monotonically increasing.' );
            end
            obj.currentSoundTimeIdx = newSoundTimeIdx;
        end

        function obj = advanceSoundTimeIdx( obj, addSoundTimeIdx )
            obj.currentSoundTimeIdx = obj.currentSoundTimeIdx + addSoundTimeIdx;
        end

        %% Add general signal from Two!Ears Auditory Front-End
        function obj = addSignal( obj, regHash, regSignal )
            if isempty( obj.signals )
                obj.signals = containers.Map();
            end
            obj.signals(regHash) = regSignal;
        end

        %% Add new data to blackboard
        % [append]: 	save more than one date per timestep,
        %                   for example several identity hypotheses
        % [tmIdx]:      save at particular timeIdx instead of current one
        function addData( obj, dataLabel, data, append, tmIdx )
            if nargin < 4, append = 0; end;
            if nargin < 5, tmIdx = obj.currentSoundTimeIdx; end;
            if obj.data.isKey( tmIdx ) 
                curData = obj.data(tmIdx);
            else
                curData = [];
            end
            if append && isfield( curData, dataLabel )
                curData.(dataLabel) = [curData.(dataLabel), data];
            else
                curData.(dataLabel) = data;
            end
            obj.data(tmIdx) = curData;
            if ~any( strcmp( obj.dataLabels, dataLabel ) )
                obj.dataLabels{end+1} = dataLabel;
            end
        end
        
        
        %% get data from blackboard
        %   dataLabel:  the label of the data needed
        %   [reqSndTimeIdxs]:	Array of time indexes requested.
        %                       if not given, all time indexes available are used
        function requestedData = getData( obj, dataLabel, reqSndTimeIdxs )
            if nargin < 3
                reqSndTimeIdxs = sort( cell2mat( keys( obj.data ) ) );
            end
            k = 1;
            requestedData = [];
            for sndTmIdx = reqSndTimeIdxs
                if ~isfield( obj.data(sndTmIdx), dataLabel ), continue; end;
                requestedData(k).sndTmIdx = sndTmIdx;
                dtmp = obj.data(sndTmIdx);
                requestedData(k).data = dtmp.(dataLabel);
                k = k + 1;
            end
        end
        
        %% get last data from blackboard
        %   dataLabel:  the label of the data needed
        %   [tmIdx]:    a point in time from which on the last data is requested
        %               default is end of recorded data
        function requestedData = getLastData( obj, dataLabel, tmIdx )
            sndTimeIdxs = sort( cell2mat( keys( obj.data ) ), 'descend' );
            if nargin < 3, tmIdx = sndTimeIdxs(1); end
            requestedData = [];
            for sndTmIdx = sndTimeIdxs(sndTimeIdxs<=tmIdx)
                requestedData = obj.getData( dataLabel, sndTmIdx );
                if ~isempty( requestedData ), break; end;
            end
        end
        
        %% get next data from blackboard
        %   dataLabel:  the label of the data needed
        %   tmIdx:      a point in time from which on the next data is requested
        function requestedData = getNextData( obj, dataLabel, tmIdx )
            sndTimeIdxs = sort( cell2mat( keys( obj.data ) ), 'ascend' );
            requestedData = [];
            for sndTmIdx = sndTimeIdxs(sndTimeIdxs>=tmIdx)
                requestedData = obj.getData( dataLabel, sndTmIdx );
                if ~isempty( requestedData ), break; end;
            end
        end
        
        %% get a block of data from blackboard
        %   dataLabel:  the label of the data needed
        %   blockSize_s:	the length of the block in seconds. The block
        %                   ends at the current time.
        function requestedData = getDataBlock( obj, dataLabel, blockSize_s )
            sndTimeIdxs = sort( cell2mat( keys( obj.data ) ) );
            sndTimeIdxs = sndTimeIdxs( sndTimeIdxs(end) - sndTimeIdxs <= blockSize_s );
            requestedData = obj.getData( dataLabel, sndTimeIdxs );
        end
        
    end
    
end
