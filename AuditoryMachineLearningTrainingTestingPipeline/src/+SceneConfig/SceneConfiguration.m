classdef SceneConfiguration < matlab.mixin.Copyable
% SceneConfiguration Configure a scene by room, SNR and sources
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        sources; 
        SNRs;
        snrRefs; % TODO: there should only be one scene-wide SNRref.
        loopSrcs; % 'no','self','randomSeq'
        room;
        brirHeadOrientIdx;
        lenRefType; % 'source', 'time'
        lenRefArg; % srcId, time in s
        minLen; % time in s
        normalize;
        normalizeLevel;
    end

    %% --------------------------------------------------------------------
    methods
        
        function obj = SceneConfiguration()
            % creates a "clean" configuration
            obj.room = SceneConfig.RoomValGen.empty;
            obj.SNRs = SceneConfig.ValGen.empty;
            obj.sources = SceneConfig.SourceBase.empty;
            obj.loopSrcs = {};
            obj.snrRefs = [];
            obj.brirHeadOrientIdx = 1;
            obj.lenRefType = 'source';
            obj.lenRefArg = 1;
            obj.minLen = 0;
            obj.normalize = false;
            obj.normalizeLevel = 1.0;
        end
        %% ----------------------------------------------------------------
        
        function addSource( obj, source, varargin )
            ip = inputParser;
            ip.addOptional( 'snr', SceneConfig.ValGen( 'manual', 0 ) );
            ip.addOptional( 'snrRef', 1 );
            ip.addOptional( 'loop', 'no' );
            obj.sources(end+1) = source;
            ip.parse( varargin{:} );
            obj.SNRs(end+1) = ip.Results.snr;
            obj.snrRefs(end+1) = ip.Results.snrRef;
            obj.loopSrcs{end+1} = ip.Results.loop;
        end
        %% -------------------------------------------------------------------------------
        
        function addRoom( obj, room )
            obj.room = room;
        end
        %% -------------------------------------------------------------------------------
        
        function setBRIRheadOrientation( obj, brirHeadOrientIdx )
            obj.brirHeadOrientIdx = brirHeadOrientIdx;
            for ii = 1:numel( obj.sources )
                if isa( obj.sources(ii), 'SceneConfig.BRIRsource' )
                    obj.sources(ii).calcAzimuth( brirHeadOrientIdx );
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function setSceneNormalization( obj, normalize, normalizeLevel )
            obj.normalize = normalize;
            obj.normalizeLevel = normalizeLevel;
        end
        %% -------------------------------------------------------------------------------

        function setLengthRef( obj, refType, refArg, varargin )
            ip = inputParser;
            ip.addOptional( 'min', 0 );
            ip.parse( varargin{:} );
            obj.lenRefType = refType;
            obj.lenRefArg = refArg;
            obj.minLen = ip.Results.min;
        end
        %% -------------------------------------------------------------------------------

        function confInst = instantiate( obj )
            confInst = SceneConfig.SceneConfiguration();
            confInst.room = obj.room.instantiate();
            for kk = 1 : numel( obj.sources )
                confInst.sources(kk) = obj.sources(kk).instantiate();
                confInst.SNRs(kk) = obj.SNRs(kk).instantiate();
            end
            confInst.snrRefs = obj.snrRefs;
            confInst.loopSrcs = obj.loopSrcs;
            confInst.brirHeadOrientIdx = obj.brirHeadOrientIdx;
            confInst.lenRefType = obj.lenRefType;
            confInst.lenRefArg = obj.lenRefArg;
            confInst.minLen = obj.minLen;
            confInst.normalizeLevel = obj.normalizeLevel;
            confInst.normalize = obj.normalize;
        end
        %% -------------------------------------------------------------------------------

        function singleConfig = getSingleConfig( obj, srcIdx )
            singleConfig = SceneConfig.SceneConfiguration();
            singleConfig.room = obj.room;
            singleConfig.sources = obj.sources(srcIdx);
            singleConfig.SNRs = SceneConfig.ValGen( 'manual', 0 );
            singleConfig.snrRefs = 1;
            singleConfig.loopSrcs = {'no'};
            singleConfig.brirHeadOrientIdx = obj.brirHeadOrientIdx;
            singleConfig.lenRefType = 'source';
            singleConfig.lenRefArg = 1;
            singleConfig.minLen = 0;
            singleConfig.normalizeLevel = obj.normalizeLevel;
            singleConfig.normalize = obj.normalize;
        end
        %% -------------------------------------------------------------------------------

        function e = isequal( obj1, obj2 )
            e = false;
            if isempty( obj1 ) && isempty( obj2 ), e = true; return; end
            if isempty( obj1 ) || isempty( obj2 ), return; end
            if numel( obj1.sources ) ~= numel( obj2.sources ), return; end
            if obj1.brirHeadOrientIdx ~= obj2.brirHeadOrientIdx, return; end
            if obj1.normalizeLevel ~= obj2.normalizeLevel, return; end
            if obj1.normalize ~= obj2.normalize, return; end
            if ~strcmpi(obj1.lenRefType, obj2.lenRefType), return; end
            if obj1.lenRefArg ~= obj2.lenRefArg, return; end
            if obj1.minLen ~= obj2.minLen, return; end
            if ~(iscell( obj1.loopSrcs ) && iscell( obj2.loopSrcs )), return; end
            obj2srcsInCmpIdxs = ones( size( obj2.sources ) );
            for kk = 1 : numel( obj1.sources )
                sequal = SceneConfig.SourceBase.isequalHetrgn( ...
                                     obj1.sources(kk), obj2.sources ) & obj2srcsInCmpIdxs;
                if ~any( sequal ), return; 
                else
                    ssequal = sequal & isequal( obj1.SNRs(kk), obj2.SNRs ) & ...
                                            (obj1.snrRefs(kk) == obj2.snrRefs) & ...
                                            (strcmpi( obj1.loopSrcs{kk}, obj2.loopSrcs ));
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
            csc = SceneConfig.SceneConfiguration();
            for ii = 1 : numel( obj.sources )
                csc.sources(ii) = copy( obj.sources(ii) );
                csc.SNRs(ii) = copy( obj.SNRs(ii) );
            end
            csc.snrRefs = obj.snrRefs;
            csc.loopSrcs = obj.loopSrcs;
            csc.room = copy( obj.room );
            csc.brirHeadOrientIdx = obj.brirHeadOrientIdx;
            csc.lenRefType = obj.lenRefType;
            csc.lenRefArg = obj.lenRefArg;
            csc.minLen = obj.minLen;
            csc.normalizeLevel = obj.normalizeLevel;
            csc.normalize = obj.normalize;
        end
        %% -------------------------------------------------------------------------------
    end

end
