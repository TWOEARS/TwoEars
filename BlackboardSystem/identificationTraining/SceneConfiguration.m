classdef SceneConfiguration < handle

    %% -----------------------------------------------------------------------------------
    properties
        angleSignal;
        distSignal;
        numOverlays;
        angleOverlays;
        distOverlays;
        SNRs;
        typeOverlays;
        fileOverlays;
        offsetOverlays;
        walls;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SceneConfiguration() % creates a "clean" configuration
            obj.angleSignal = ValGen( 'manual', 0 );
            obj.distSignal = ValGen( 'manual', 3 );
            obj.numOverlays = 0;
            obj.walls = ValGen( 'manual', [] );
            obj.angleOverlays = ValGen.empty;
            obj.distOverlays = ValGen.empty;
            obj.SNRs = ValGen.empty;
            obj.typeOverlays = cell(0);
            obj.fileOverlays = ValGen.empty;
            obj.offsetOverlays= ValGen.empty;
        end
        %% -------------------------------------------------------------------------------

        function addOverlay( obj, angle, dist, SNR, type, file, offset_s )
            obj.numOverlays = obj.numOverlays + 1;
            if ~isa( angle, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.angleOverlays(obj.numOverlays) = angle;
            if ~isa( dist, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.distOverlays(obj.numOverlays) = dist;
            if ~isa( SNR, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.SNRs(obj.numOverlays) = SNR;
            if sum( strcmpi( type, {'point', 'diffuse'} ) ) == 0
                error( 'Unknown overlay type' );
            end
            obj.typeOverlays{obj.numOverlays} = type;
            if ~isa( file, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.fileOverlays(obj.numOverlays) = file;
            if ~isa( offset_s, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.offsetOverlays(obj.numOverlays) = offset_s;
        end
        %% -------------------------------------------------------------------------------
        
        function addWalls( obj, walls )
            if ~isa( walls, 'WallsValGen' ), error( 'Use a WallsValGen' ); end;
            obj.walls = walls;
        end
        %% -------------------------------------------------------------------------------

        function confInst = instantiate( obj )
            confInst = SceneConfiguration();
            confInst.angleSignal = ValGen( 'manual', obj.angleSignal.value );
            confInst.distSignal = ValGen( 'manual', obj.distSignal.value );
            confInst.numOverlays = obj.numOverlays;
            confInst.walls = ValGen( 'manual', obj.walls.value );
            for kk = 1:obj.numOverlays
                confInst.angleOverlays(kk) = ValGen( 'manual', obj.angleOverlays(kk).value );
                confInst.distOverlays(kk) = ValGen( 'manual', obj.distOverlays(kk).value );
                confInst.SNRs(kk) = ValGen( 'manual', obj.SNRs(kk).value );
                confInst.typeOverlays{kk} = obj.typeOverlays{kk};
                confInst.fileOverlays(kk) = ValGen( 'manual', obj.fileOverlays(kk).value );
                confInst.offsetOverlays(kk) = ValGen( 'manual', obj.offsetOverlays(kk).value );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj, cObj )
            if ~isequaln( obj.numOverlays, cObj.numOverlays )
                e = false;
                return;
            end
            fileOverlaysAreEqual = true;
            for kk = 1 : obj.numOverlays
                if length( obj.fileOverlays(kk).val ) ~= length( cObj.fileOverlays(kk).val )
                    e = false;
                    return;
                end
                for jj = 1 : length( obj.fileOverlays(kk).val )
                    [bp, fn, fe] = fileparts( obj.fileOverlays(kk).val{jj} );
                    [~, cp, ~] = fileparts( bp );
                    files1{jj} = fullfile( cp, [fn fe] );
                    [bp, fn, fe] = fileparts( cObj.fileOverlays(kk).val{jj} );
                    [~, cp, ~] = fileparts( bp );
                    files2{jj} = fullfile( cp, [fn fe] );
                end
                fileOverlaysAreEqual = ...
                    fileOverlaysAreEqual && ...
                    isequaln( sort( files1 ), sort( files2 ) );
            end
            e = ...
                isequaln( obj.angleSignal, cObj.angleSignal) && ...
                isequaln( obj.distSignal, cObj.distSignal ) && ...
                isequaln( obj.angleOverlays, cObj.angleOverlays ) && ...
                isequaln( obj.distOverlays, cObj.distOverlays ) && ...
                isequaln( obj.SNRs, cObj.SNRs ) && ...
                isequaln( obj.typeOverlays, cObj.typeOverlays ) && ...
                fileOverlaysAreEqual && ...
                isequaln( obj.offsetOverlays, cObj.offsetOverlays ) && ...
                isequaln( obj.walls, cObj.walls );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end
