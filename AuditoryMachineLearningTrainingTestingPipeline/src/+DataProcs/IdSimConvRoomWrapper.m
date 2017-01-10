classdef IdSimConvRoomWrapper < Core.IdProcInterface
    % IdSimConvRoomWrapper wrap the simulator.SimulatorConvexRoom class
    %% -----------------------------------------------------------------------------------
    properties (Access = protected)
        convRoomSim;    % simulation tool of type simulator.SimulatorConvexRoom
        sceneConfig;
        IRDataset;
        reverberationMaxOrder = 5;
        earSout;
        annotsOut;
        srcAzimuth;
        brirSrcPos;
        outFs;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        function obj = IdSimConvRoomWrapper( hrirFile, fs )
            if nargin < 2
                fs = 44100;
            end
            % initialize the simulation tool
            obj = obj@Core.IdProcInterface();
            obj.convRoomSim = simulator.SimulatorConvexRoom();
            set(obj.convRoomSim, ...
                'BlockSize', 4096, ...
                'SampleRate', 44100, ...
                'MaximumDelay', 0.05 ... % for distances up to ~15m
                );
            if ~isempty( hrirFile )
                set( obj.convRoomSim, 'Renderer', @ssr_binaural );
                obj.IRDataset.dir = simulator.DirectionalIR( db.getFile( hrirFile ) );
                obj.IRDataset.fname = hrirFile;
                set( obj.convRoomSim, 'HRIRDataset', obj.IRDataset.dir );
            else
                set( obj.convRoomSim, 'Renderer', @ssr_brs );
            end
            set(obj.convRoomSim, ...
                'Sinks', simulator.AudioSink(2) ...
                );
            set(obj.convRoomSim.Sinks, ...
                'Position' , [0; 0; 1.75], ...
                'Name', 'Head' ...
                );
            set(obj.convRoomSim, 'Verbose', false);
            obj.outFs = fs;
        end
        %% ----------------------------------------------------------------
        
        function delete( obj )
            obj.convRoomSim.set('ShutDown',true);
        end
        %% ----------------------------------------------------------------
        
        function setSceneConfig( obj, sceneConfig )
            obj.sceneConfig = sceneConfig;
        end
        %% ----------------------------------------------------------------

        function fs = getDataFs( obj )
            fs = obj.outFs;
        end
        
        %% ----------------------------------------------------------------

        function process( obj, wavFilepath )
            sceneConfigInst = obj.sceneConfig.instantiate();
            signal = obj.loadSound( sceneConfigInst, wavFilepath );
            obj.setupSceneConfig( sceneConfigInst );
            if isa( sceneConfigInst.sources(1), 'SceneConfig.DiffuseSource' )
                obj.earSout = signal{1};
                t = obj.convRoomSim.BlockSize : obj.convRoomSim.BlockSize : size( signal{1}, 1 );
                t = t / obj.convRoomSim.SampleRate;
                obj.annotsOut.srcAzms = struct( ...
                             't', {single( t )}, ...
                             'srcAzms', {single( repmat( obj.srcAzimuth, numel( t ), 1 ) )} );
            else
                obj.setSourceData( signal{1} );
                obj.simulate();
                obj.earSout = obj.convRoomSim.Sinks.getData();
            end
            obj.earSout = resample( double( obj.earSout ), obj.outFs, obj.convRoomSim.SampleRate );
            obj.earSout = single( obj.earSout );
        end
        %% ----------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.sceneConfig = copy( obj.sceneConfig );
            if ~isempty( outputDeps.sceneConfig )
                outputDeps.sceneConfig.sources(1).data = []; % configs shall not include filename
            end
            outputDeps.SampleRate = obj.convRoomSim.SampleRate;
            outputDeps.outFs = obj.outFs;
            outputDeps.ReverberationMaxOrder = obj.reverberationMaxOrder;
            rendererFunction = functions( obj.convRoomSim.Renderer );
            rendererName = rendererFunction.function;
            outputDeps.Renderer = rendererName;
            persistent hrirHash;
            persistent hrirFName;
            if isempty( obj.IRDataset ) || isfield( obj.IRDataset, 'isbrir' )
                hrirHash = [];
                hrirFName = [];
            elseif isempty( hrirFName ) || ~strcmpi( hrirFName, obj.IRDataset.dir.Filename )
                hrirFName = obj.IRDataset.dir.Filename;
                hrirHash = calcDataHash( audioread( hrirFName ) );
            end
            outputDeps.hrir = hrirHash;
            outputDeps.v = 2;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj, varargin )
            if nargin < 2  || any( strcmpi( 'earSout', varargin ) )
                out.earSout = obj.earSout;
            end
            if nargin < 2  || any( strcmpi( 'annotations', varargin ) )
                out.annotations = obj.annotsOut;
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
        function setSourceData( obj, snd )
            sigLen_s = length( snd ) / obj.convRoomSim.SampleRate;
            obj.convRoomSim.set( 'LengthOfSimulation', sigLen_s );
            obj.convRoomSim.Sinks.removeData();
            obj.convRoomSim.Sources{1}.setData( snd );
        end
        %% ----------------------------------------------------------------
        
        function simulate( obj )
            obj.convRoomSim.set( 'ReInit', true );
            t = 0;
            obj.annotsOut.srcAzms = struct( 't', {[]}, 'srcAzms', {[]} );
            while ~obj.convRoomSim.isFinished()
                obj.convRoomSim.set('Refresh',true);  % refresh all objects
                obj.convRoomSim.set('Process',true);  % processing
                t = t + obj.convRoomSim.BlockSize / obj.convRoomSim.SampleRate;
                obj.annotsOut.srcAzms.srcAzms(end+1,1) = single( obj.srcAzimuth );
                obj.annotsOut.srcAzms.t(end+1) = single( t );
                fprintf( '.' );
            end
        end
        %% ----------------------------------------------------------------

        function setupSceneConfig( obj, sceneConfig )
            obj.convRoomSim.set( 'ShutDown', true );
            if ~isempty(obj.convRoomSim.Sources), obj.convRoomSim.Sources(2:end) = []; end;
            useSimReverb = ~isempty( sceneConfig.room );
            if useSimReverb
                if isempty( obj.IRDataset ) % then BRIRsources are expected
                    error( 'usage of BRIR incompatible with simulating a room' );
                end
                obj.convRoomSim.Room = sceneConfig.room.value; 
                obj.convRoomSim.Room.set( 'ReverberationMaxOrder', ...
                                          obj.reverberationMaxOrder );
            end
            channelMapping = 1;
            if isa( sceneConfig.sources(1), 'SceneConfig.PointSource' ) 
                if useSimReverb
                    obj.convRoomSim.Sources{1} = simulator.source.ISMGroup();
                    obj.convRoomSim.Sources{1}.set( 'Room', obj.convRoomSim.Room );
                else
                    obj.convRoomSim.Sources{1} = simulator.source.Point();
                end
                obj.convRoomSim.Sources{1}.Radius = sceneConfig.sources(1).distance.value;
                obj.srcAzimuth = sceneConfig.sources(1).azimuth.value;
                obj.convRoomSim.Sources{1}.Azimuth = obj.srcAzimuth;
            elseif isa( sceneConfig.sources(1), 'SceneConfig.BRIRsource' ) 
                obj.convRoomSim.Sources{1} = simulator.source.Point();
                brirSofa = SOFAload( ...
                            db.getFile( sceneConfig.sources(1).brirFName ), 'nodata' );
                headOrientIdx = ceil( sceneConfig.brirHeadOrientIdx * size( brirSofa.ListenerView, 1 ));
                headOrientation = SOFAconvertCoordinates( ...
                         brirSofa.ListenerView(headOrientIdx,:),'cartesian','spherical' );
                if isempty( obj.IRDataset ) ...
                   || ~strcmp( obj.IRDataset.fname, sceneConfig.sources(1).brirFName ) ...
                   || (isfield( obj.IRDataset, 'speakerId' ) ~= ~isempty( sceneConfig.sources(1).speakerId ) ) ...
                   || obj.IRDataset.speakerId ~= sceneConfig.sources(1).speakerId
                    if isempty( sceneConfig.sources(1).speakerId )
                        warning( 'off', 'all' ); % avoid messy "SOFA experimental" warning
                        obj.IRDataset.dir = ...
                              simulator.DirectionalIR( sceneConfig.sources(1).brirFName );
                        warning( 'on', 'all' );
                        obj.brirSrcPos = SOFAconvertCoordinates( ...
                            brirSofa.EmitterPosition(1,:) - brirSofa.ListenerPosition, ...
                                                                'cartesian','spherical' );
                    else
                        warning( 'off', 'all' ); % avoid messy "SOFA experimental" warning
                        obj.IRDataset.dir = simulator.DirectionalIR( ...
                                                     sceneConfig.sources(1).brirFName, ...
                                                     sceneConfig.sources(1).speakerId );
                        warning( 'on', 'all' );
                        obj.IRDataset.speakerId = sceneConfig.sources(1).speakerId;
                        obj.brirSrcPos = SOFAconvertCoordinates( ...
                          brirSofa.EmitterPosition(sceneConfig.sources(1).speakerId,:) ...
                                   - brirSofa.ListenerPosition, 'cartesian','spherical' );
                    end
                    obj.IRDataset.isbrir = true;
                    obj.IRDataset.fname = sceneConfig.sources(1).brirFName;
                end
                obj.convRoomSim.Sources{1}.IRDataset = obj.IRDataset.dir;
                obj.convRoomSim.rotateHead( headOrientation(1), 'absolute' );
                obj.srcAzimuth = obj.brirSrcPos(1) - headOrientation(1);
            else % ~is diffuse
                obj.convRoomSim.Sources{1} = simulator.source.Binaural();
                channelMapping = [1 2];
                obj.srcAzimuth = NaN;
            end
            obj.convRoomSim.Sources{1}.AudioBuffer = simulator.buffer.FIFO( channelMapping );
            obj.convRoomSim.set('Init',true);
        end
        %% ----------------------------------------------------------------

        function signal = loadSound( obj, sceneConfig, wavFilepath )
            startOffset = sceneConfig.sources(1).offset.value;
            src = sceneConfig.sources(1).data.value;
            onOffs = [];
            eventType = '';
            if ischar( src ) % then it is a filename
                signal{1} = getPointSourceSignalFromWav( ...
                             src, obj.convRoomSim.SampleRate, startOffset, false, 'max' );
                eventType = IdEvalFrame.readEventClass( wavFilepath );
                if strcmpi( eventType, 'general' )
                    onOffs = zeros(0,2);
                else
                    [onOffs,etypes] = ...
                                IdEvalFrame.readOnOffAnnotations( wavFilepath );
                    onOffs = onOffs + startOffset;
                end
            elseif isfloat( src ) && size( src, 2 ) == 1
                signal{1} = src;
                nZeros = floor( obj.convRoomSim.SampleRate * startOffset );
                zeroOffset = zeros( nZeros, 1 ) + mean( signal{1} );
                signal{1} = [zeroOffset; signal{1}; zeroOffset];
                wavFilepath = 'directData';
            else
                error( 'This was not foreseen.' );
            end
            if isa( sceneConfig.sources(1), 'SceneConfig.DiffuseSource' )
                signal{1} = repmat( signal{1}, 1, 2 );
            end
            obj.annotsOut.srcType = struct( 't', ...
                        struct( 'onset', {[]}, 'offset', {[]} ), 'srcType', {cell(0,1)} );
            for ii = 1 : size( onOffs, 1 )
                obj.annotsOut.srcType.t.onset(end+1) = onOffs(ii,1);
                obj.annotsOut.srcType.t.offset(end+1) = onOffs(ii,2);
                if ~isempty( etypes{ii} )
                    obj.annotsOut.srcType.srcType(end+1,1) = etypes(ii);
                else
                    obj.annotsOut.srcType.srcType(end+1,1) = {eventType};
                end
            end
            if sceneConfig.sources(1).normalize
                sigSorted = sort( abs( signal{1}(:) ) );
                sigSorted(sigSorted<=0.1*mean(sigSorted)) = [];
                if ~isempty(sigSorted)
                    nUpperSigSorted = round( numel( sigSorted ) * 0.01 );
                    sigUpperAbs = median( sigSorted(end-nUpperSigSorted:end) ); % ~0.995 percentile
                    signal{1} = signal{1} * sceneConfig.sources(1).normalizeLevel/sigUpperAbs;
                end
            end
            srcLen_s = size( signal{1}, 1 ) / obj.convRoomSim.SampleRate;
            obj.annotsOut.srcFile = struct( 't', struct( 'onset', {startOffset}, ...
                                                 'offset', {srcLen_s - startOffset} ), ...
                                            'srcFile', {{wavFilepath}} );
        end
        %% ----------------------------------------------------------------

        
    end
    
    
end
