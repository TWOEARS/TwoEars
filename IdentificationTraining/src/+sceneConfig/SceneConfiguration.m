classdef SceneConfiguration < matlab.mixin.Copyable

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        sources; % sources(1) is the main source, data will be from pipeline data
        SNRs; % SNRs(1) is always interpreted as 0
              % all others are in relation to sources(1)
              % length(sources) must be == length(SNRs)
        room;
        loop; % loop sources that are shorter than the main source
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SceneConfiguration() % creates a "clean" configuration
            obj.room = sceneConfig.RoomValGen.empty;
            obj.SNRs = sceneConfig.ValGen.empty;
            obj.sources = sceneConfig.SourceBase.empty;
            obj.loop = [];
        end
        %% -------------------------------------------------------------------------------
        
        function addSource( obj, source, snr, loop )
            obj.sources(end+1) = source;
            if numel( obj.SNRs ) == 0  || nargin < 3
                obj.SNRs(end+1) = sceneConfig.ValGen( 'manual', 0 );
            else
                obj.SNRs(end+1) = snr;
            end
            if numel( obj.loop ) == 0  || nargin < 4
                obj.loop(end+1) = false;
            else
                obj.loop(end+1) = loop;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function addRoom( obj, room )
            obj.room = room;
        end
        %% -------------------------------------------------------------------------------

        function confInst = instantiate( obj )
            confInst = sceneConfig.SceneConfiguration();
            confInst.room = obj.room.instantiate();
            for kk = 1 : numel( obj.sources )
                confInst.sources(kk) = obj.sources(kk).instantiate();
                confInst.SNRs(kk) = obj.SNRs(kk).instantiate();
            end
            confInst.loop = obj.loop;
        end
        %% -------------------------------------------------------------------------------

        function singleConfig = getSingleConfig( obj, srcIdx )
            singleConfig = sceneConfig.SceneConfiguration();
            singleConfig.room = obj.room;
            singleConfig.sources = obj.sources(srcIdx);
            singleConfig.SNRs = sceneConfig.ValGen( 'manual', 0 );
            singleConfig.loop = false; % there is only one source
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            e = false;
            if isempty( obj1 ) && isempty( obj2 ), e = true; return; end
            if isempty( obj1 ) || isempty( obj2 ), return; end
            if numel( obj1.sources ) ~= numel( obj2.sources ), return; end
            if numel( obj1.loop ) ~= numel( obj2.loop ), return; end
            if obj1.loop ~= obj2.loop, return; end
            obj2srcsInCmpIdxs = ones( size( obj2.sources ) );
            for kk = 1 : numel( obj1.sources )
                sequal = sceneConfig.SourceBase.isequalHetrgn( obj1.sources(kk), obj2.sources ) & obj2srcsInCmpIdxs;
                if ~any( sequal ), return; 
                else
                    ssequal = isequal( obj1.SNRs(kk), obj2.SNRs ) & sequal;
                    if ~any( ssequal ), return; 
                    else
                        sseFirstIdx = find( ssequal == 1, 1, 'first' );
                        obj2srcsInCmpIdxs(sseFirstIdx) = 0;
                    end
                end
            end
            e = isequal( obj1.room, obj2.room );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    methods (Access = protected)
        
        function csc = copyElement( obj )
            csc = sceneConfig.SceneConfiguration();
            for ii = 1 : numel( obj.sources )
                csc.sources(ii) = copy( obj.sources(ii) );
                csc.SNRs(ii) = copy( obj.SNRs(ii) );
            end
            csc.room = copy( obj.room );
            csc.loop = obj.loop;
        end
        %% -------------------------------------------------------------------------------
    end

end
