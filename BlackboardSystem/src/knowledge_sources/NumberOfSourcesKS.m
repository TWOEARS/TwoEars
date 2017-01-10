classdef NumberOfSourcesKS < AbstractAMLTTPKS
    
    properties (SetAccess = private)
        locDataKey; % 'locationHypothesis'(default) or 'sourcesAzimuthsDistributionHypotheses'
        useIdModels;
    end

    methods
        function obj = NumberOfSourcesKS( modelName, modelDir, ppRemoveDc, varargin )
            obj@AbstractAMLTTPKS( modelName, modelDir, ppRemoveDc );
            obj.setInvocationFrequency(inf);
            ip = inputParser();
            ip.addOptional( 'locDataKey', 'locationHypothesis' );
            ip.addOptional( 'useIdModels', false );
            ip.parse( varargin{:} );
            obj.locDataKey = ip.Results.locDataKey;
            obj.useIdModels = ip.Results.useIdModels;
        end
        
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                nSrcsHyp = obj.blackboard.getData( ...
                    'NumberOfSourcesHypotheses', obj.trigger.tmIdx).data;
                obj.blackboardSystem.locVis.setNumberOfSourcesText(nSrcsHyp.n);
            end
        end
    end
    
    methods (Access = protected)        
        function amlttpExecute( obj, afeBlock )
            locHypos = [];
            if strcmp( obj.locDataKey, 'locationHypothesis' )
                % use more robust localisationDecision output -- recommended
                locHypos = obj.blackboard.getLastData( 'locationHypothesis' );
                if ~isempty( locHypos )
                    assert( numel( locHypos.data ) == 1 );
                    afeBlock = DataProcs.DnnLocKsWrapper.addLocDecisionData( afeBlock, locHypos.data );
                end
            end
            if strcmp( obj.locDataKey, 'sourcesAzimuthsDistributionHypotheses' ) ...
                    || isempty( locHypos )
                % fall back on raw localisation data
                locHypos = obj.blackboard.getLastData( 'sourcesAzimuthsDistributionHypotheses' );
                assert( numel( locHypos.data ) == 1 );
                afeBlock = DataProcs.DnnLocKsWrapper.addLocData( afeBlock, locHypos.data );
            end
            if obj.useIdModels
                idHypos = obj.blackboard.getLastData( 'identityHypotheses' );
                idData.names = {};
                idData.scores = [];
                for ii = 1 : numel( idHypos.data )
                    idData.names{ii} = idHypos.data(ii).label;
                    idData.scores(ii) = idHypos.data(ii).p;
                end
                [idData.names,idSort] = sort( idData.names );
                idData.scores = idData.scores(idSort);
                afeBlock = DataProcs.LocIdKsWrapper.addIdData( afeBlock, idData );
            end
            
            obj.featureCreator.setAfeData( afeBlock );
            
            x = obj.featureCreator.constructVector();
            [d, score] = obj.model.applyModel( x{1} );
            d = round( d(1) + 0.3 );
            bbprintf(obj, '[NumberOfSourcesKS:] %s detecting %i sources.\n', ...
                     obj.modelname, int16(d) );
            identHyp = NumberOfSourcesHypothesis( ...
                obj.modelname, score(1), d, obj.blockCreator.blockSize_s );
            obj.blackboard.addData( 'NumberOfSourcesHypotheses', identHyp, true, obj.trigger.tmIdx );
        end
    end
end
