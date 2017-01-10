classdef LocIdKsWrapper < DataProcs.BlackboardKsWrapper
    % Wrapping the DnnLocationKS and IdentityKss
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        dnnHash;
        nfHash;
        dnnLocKs;
        idKss;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = LocIdKsWrapper( idModelpathes, useCaffe, gpuIdx )
            if nargin < 2, useCaffe = false; end
            if nargin < 3, gpuIdx = 0; end
            wrappedKss = {};
            if useCaffe
                dnnLocKs = DnnLocationCaffeKS();
                CaffeModel.setMode(1,gpuIdx);
            else
                dnnLocKs = DnnLocationKS();
            end
            dnnHash = calcDataHash( dnnLocKs.DNNs );
            nfHash = calcDataHash( dnnLocKs.normFactors );
            wrappedKss{end+1} = dnnLocKs;
            idKss = {};
            mnames = {};
            for ii = 1 : numel( idModelpathes )
                [mdir, mname] = fileparts( idModelpathes{ii} );
                [~, mnames{ii}] = fileparts( mname );
                idKss{ii} = IdentityKS( mnames{ii}, mdir, false );
            end
            [~,idSort] = sort( mnames );
            idKss = idKss(idSort);
            wrappedKss = [wrappedKss idKss];
            obj = obj@DataProcs.BlackboardKsWrapper( wrappedKss );
            obj.dnnHash = dnnHash;
            obj.nfHash = nfHash;
            obj.dnnLocKs = dnnLocKs;
            obj.idKss = idKss;
        end
        %% -------------------------------------------------------------------------------
        
        function procBlock = preproc( obj, blockAnnotations )
            procBlock = true;
            warning( 'off', 'BBS:badBlockTimeRequest' );
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj, afeData, blockAnnotations )
            locHypos = obj.bbs.blackboard.getLastData( 'locationHypothesis' );
            if ~isempty( locHypos )
                assert( numel( locHypos.data ) == 1 );
                obj.out.afeBlocks{end+1,1} = DataProcs.DnnLocKsWrapper.addLocDecisionData( afeData, locHypos.data );
            else
                % fall back on raw localisation data
                locHypos = obj.bbs.blackboard.getLastData( 'sourcesAzimuthsDistributionHypotheses' );
                assert( numel( locHypos.data ) == 1 );
                obj.out.afeBlocks{end+1,1} = DataProcs.DnnLocKsWrapper.addLocData( afeData, locHypos.data );
            end
            idHypos = obj.bbs.blackboard.getLastData( 'identityHypotheses' );
            assert( numel( idHypos.data ) == numel( obj.idKss ) );
            idData.names = {};
            idData.scores = [];
            for ii = 1 : numel( obj.idKss )
                idData.names{ii} = idHypos.data(ii).label;
                idData.scores(ii) = idHypos.data(ii).p;
            end
            [idData.names,idSort] = sort( idData.names );
            idData.scores = idData.scores(idSort);
            obj.out.afeBlocks{end} = DataProcs.LocIdKsWrapper.addIdData( ...
                                                obj.out.afeBlocks{end},idData );
            if isempty(obj.out.blockAnnotations)
                obj.out.blockAnnotations = blockAnnotations;
            else
                obj.out.blockAnnotations(end+1,1) = blockAnnotations;
            end
            warning( 'on', 'BBS:badBlockTimeRequest' );
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getKsInternOutputDependencies( obj )
            outputDeps.v = 1;
            [~,outputDeps.afeHashs] = obj.getAfeRequests();
            for ii = 1 : numel( obj.idKss )
                outputDeps.(['id' num2str( ii ) '_name']) = obj.idKss{ii}.modelname;
                classInfo = metaclass( obj.idKss{ii}.model );
                [classname1, classname2] = strtok( classInfo.Name, '.' );
                if isempty( classname2 ), modeltype = classname1;
                else modeltype = classname2(2:end); end
                outputDeps.(['id' num2str( ii ) '_type']) = modeltype;
                classInfo = metaclass( obj.idKss{ii}.featureCreator );
                [classname1, classname2] = strtok( classInfo.Name, '.' );
                if isempty( classname2 ), fctype = classname1;
                else fctype = classname2(2:end); end
                outputDeps.(['id' num2str( ii ) '_fctype']) = fctype;
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
        function afeData = addIdData( afeData, idData )
            idFakeAFEsignal = struct();
            idFakeAFEsignal.Data = idData.scores;
            idFakeAFEsignal.Name = 'ObjectIdentities';
            idFakeAFEsignal.Types = idData.names;
            afeData(afeData.Count+1) = idFakeAFEsignal;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

