classdef SegmentKsWrapper_AnnotationWriter < DataProcs.BlackboardKsWrapper_AnnotationWriter
    % Wrapping the SegmentationKS
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        varAzmSigma;
        azmsGroundTruth;
        segSrcAssignmentMethod;
        dnnHash;
        nfHash;
        useDnnLocKs = false;
        useNsrcsKs = false;
        segmentKs;
        dnnLocKs;
        nsrcsKs;
        idKss;
        energeticBaidxs;
        nsrcsBias;
        nsrcsRndPlusMinusBias;
        isNsrcsFixed;
        isAzmFixedUniform;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SegmentKsWrapper_AnnotationWriter( paramFilepath, varargin )
            fprintf( 'Building SegmentKsWrapper...' );
            ip = inputParser();
            ip.addOptional( 'useDnnLocKs', false );
            ip.addOptional( 'useNsrcsKs', false );
            ip.addOptional( 'nsrcsParams', {} );
            ip.addOptional( 'segSrcAssignmentMethod', 'minDistance' );
            ip.addOptional( 'varAzmSigma', 0 );
            ip.addOptional( 'nsrcsBias', 0 );
            ip.addOptional( 'nsrcsRndPlusMinusBias', 0 );
            ip.parse( varargin{:} );
            segmentKs = StreamSegregationKS( paramFilepath ); 
            fprintf( '.' );
            wrappedKss = {};
            if ip.Results.useDnnLocKs
                dnnLocKs = DnnLocationKS();
                dnnHash = calcDataHash( dnnLocKs.DNNs );
                nfHash = calcDataHash( dnnLocKs.normFactors );
                wrappedKss{end+1} = dnnLocKs;
            else
                dnnLocKs = [];
                dnnHash = [];
                nfHash = [];
            end
            fprintf( '.' );
            idKss = [];
            if ip.Results.useDnnLocKs && ip.Results.useNsrcsKs
                ipns = inputParser();
                ipns.addOptional( 'modelPath', './nsrcs.model.mat' );
                ipns.addOptional( 'useIdModels', false );
                ipns.addOptional( 'idModelpathes', {} );
                ipns.parse( ip.Results.nsrcsParams{:} );
                if ipns.Results.useIdModels
                    idKss = {};
                    mnames = {};
                    for ii = 1 : numel( ipns.Results.idModelpathes )
                        [mdir, mname] = fileparts( ipns.Results.idModelpathes{ii} );
                        [~, mnames{ii}] = fileparts( mname );
                        idKss{ii} = IdentityKS( mnames{ii}, mdir, false ); 
                        fprintf( '.' );
                    end
                    [~,idSort] = sort( mnames );
                    idKss = idKss(idSort);
                    wrappedKss = [wrappedKss idKss];
                end
                [mdir, mname] = fileparts( ipns.Results.modelPath );
                [~, mname] = fileparts( mname );
                nsrcsKs = NumberOfSourcesKS( mname, mdir, false, 'useIdModels', ipns.Results.useIdModels );
                fprintf( '.' );
                wrappedKss{end+1} = nsrcsKs;
            else
                nsrcsKs = [];
            end
            wrappedKss{end+1} = segmentKs;
            obj = obj@DataProcs.BlackboardKsWrapper_AnnotationWriter( wrappedKss );
            obj.varAzmSigma = ip.Results.varAzmSigma;
            obj.azmsGroundTruth = [];
            obj.segSrcAssignmentMethod = ip.Results.segSrcAssignmentMethod;
            obj.dnnHash = dnnHash;
            obj.nfHash = nfHash;
            obj.useDnnLocKs = ip.Results.useDnnLocKs;
            obj.useNsrcsKs = ip.Results.useNsrcsKs;
            if obj.useNsrcsKs && ~obj.useDnnLocKs
                error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                       ['nSrcs model employment only supported if also using ' ...
                        'location model.'] );
            end
            obj.segmentKs = segmentKs;
            obj.dnnLocKs = dnnLocKs;
            obj.idKss = idKss;
            obj.nsrcsKs = nsrcsKs;
            obj.energeticBaidxs = [];
            obj.isNsrcsFixed = false;
            obj.isAzmFixedUniform = false;
            obj.nsrcsBias = ip.Results.nsrcsBias;
            if obj.useNsrcsKs && (obj.nsrcsBias ~= 0)
                error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                       ['nSrcs bias only supported if using ' ...
                        'nSrcs ground truth.'] );
            end
            if ischar( obj.nsrcsBias ) 
                if strfind( obj.nsrcsBias, 'fixed' ) == 1
                    obj.isNsrcsFixed = true;
                    obj.nsrcsBias = str2double( obj.nsrcsBias(6:end) );
                else
                    error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                          ['unrecognized nSrcs bias flag.'] );
                end
            end
            obj.nsrcsRndPlusMinusBias = ip.Results.nsrcsRndPlusMinusBias;
            if obj.useNsrcsKs && (obj.nsrcsRndPlusMinusBias ~= 0)
                error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                       ['nSrcs random bias only supported if using ' ...
                        'nSrcs ground truth.'] );
            end
            if ischar( obj.varAzmSigma ) 
                if strfind( obj.varAzmSigma, 'fixedUniform' ) == 1
                    obj.isAzmFixedUniform = true;
                else
                    error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                          ['unrecognized azm bias flag.'] );
                end
            end
            fprintf( '.\n' );
        end
        %% -------------------------------------------------------------------------------
                
        function postproc( obj, blockAnnotations )
            blockAnnotations = rmfield( blockAnnotations, {'srcType','srcFile','mixEnergy','oneVsAllAvgSnrs','nSrcs_sceneConfig','nActivePointSrcs'} );
            newBAfields = fieldnames( blockAnnotations );
            for ii = 1 : numel( obj.out.blockAnnotations )
                if isempty( obj.out.blockAnnotations(ii).srcAzms ), continue; end
                bon = obj.out.blockAnnotations(ii).blockOnset;
                bof = obj.out.blockAnnotations(ii).blockOffset;
                newBAidx = find( abs( [blockAnnotations.blockOnset] - bon ) <= 0.05 & ...
                                 abs( [blockAnnotations.blockOffset] - bof ) <= 0.05 );
                if numel( newBAidx ) ~= 1
                    error( ['newBAidx == ' num2str( newBAidx ) ', bon == ' num2str( bon ) ...
                            ', bof == ' num2str( bof )] );
                end
                bazms = obj.out.blockAnnotations(ii).srcAzms;
                newBA_srcIdxs = arrayfun( ...
                         @(a)( find( a == blockAnnotations(newBAidx).srcAzms ) ), ...
                         bazms, 'UniformOutput', false );
                newBA_srcIdxs = [newBA_srcIdxs{:}];
                assert( numel( newBA_srcIdxs ) == numel( bazms ) ); 
                maskedNewBA = obj.maskBA( blockAnnotations(newBAidx), newBA_srcIdxs );
                for jj = 1 : numel( newBAfields )
                    obj.out.blockAnnotations(ii).(newBAfields{jj}) = maskedNewBA.(newBAfields{jj});
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getKsInternOutputDependencies( obj )
            outputDeps.v = 15;
            outputDeps.useDnnLocKs = obj.useDnnLocKs;
            outputDeps.useNsrcsKs = obj.useNsrcsKs;
            outputDeps.useIdModels = ~isempty( obj.idKss );
            outputDeps.params = obj.kss{end}.observationModel.trainingParameters;
            [~,outputDeps.afeHashs] = obj.getAfeRequests();
            outputDeps.varAzmSigma = obj.varAzmSigma;
            outputDeps.segSrcAssignmentMethod = obj.segSrcAssignmentMethod;
            outputDeps.nsrcsBias = obj.nsrcsBias;
            outputDeps.nsrcsRndPlusMinusBias = obj.nsrcsRndPlusMinusBias;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        %% -------------------------------------------------------------------------------
        
        function blockAnnotations = maskBA( ~, blockAnnotations, srcIdxs )
            rSrcIdxs = 1:max( srcIdxs );
            rSrcIdxs(srcIdxs) = 1:numel(srcIdxs);
            baFields = fieldnames( blockAnnotations );
            for ff = 1 : numel( baFields )
                if isstruct( blockAnnotations.(baFields{ff}) )
                    baSrcs = blockAnnotations.(baFields{ff}).(baFields{ff})(:,2);
                    baIsSrcIdEq = cellfun( @(x)( any( x == srcIdxs) ), baSrcs );
                    blockAnnotations.(baFields{ff}).t.onset(~baIsSrcIdEq) = [];
                    blockAnnotations.(baFields{ff}).t.offset(~baIsSrcIdEq) = [];
                    blockAnnotations.(baFields{ff}).(baFields{ff})(~baIsSrcIdEq,:) = [];
                    blockAnnotations.(baFields{ff}).(baFields{ff})(:,2) = ...
                        cellfun( @(x)(rSrcIdxs(x)), ...
                        blockAnnotations.(baFields{ff}).(baFields{ff})(:,2), ...
                                                       'UniformOutput', false );
                elseif ~strcmpi('mixEnergy',baFields{ff}) && ...
                        (iscell( blockAnnotations.(baFields{ff}) ) ...
                        || numel( blockAnnotations.(baFields{ff}) ) > 1)
                    baIsSrcIdEq = false( size( blockAnnotations.(baFields{ff}) ) );
                    baIsSrcIdEq(srcIdxs) = true;
                    blockAnnotations.(baFields{ff})(~baIsSrcIdEq) = [];
                end
            end
%             blockAnnotations.mixEnergy = blockAnnotations.srcEnergy{1};
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

