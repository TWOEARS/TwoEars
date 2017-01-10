classdef DnnLocKsWrapper < DataProcs.BlackboardKsWrapper
    % Wrapping the DnnLocationKS
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        dnnHash;
        nfHash;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = DnnLocKsWrapper( useCaffe, gpuIdx )
            if nargin < 1, useCaffe = false; end
            if nargin < 2, gpuIdx = 0; end
            wrappedKss = {};
            if useCaffe
                dnnLocKs = DnnLocationCaffeKS();
                CaffeModel.setMode(1,gpuIdx);
            else
                dnnLocKs = DnnLocationKS();
            end
            obj = obj@DataProcs.BlackboardKsWrapper( dnnLocKs );
            obj.dnnHash = calcDataHash( dnnLocKs.DNNs );
            obj.nfHash = calcDataHash( dnnLocKs.normFactors );
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
            outputDeps.bs = obj.kss{1}.blockSize;
            outputDeps.nc = obj.kss{1}.nChannels;
            outputDeps.fr = obj.kss{1}.freqRange;
            outputDeps.dn = obj.dnnHash;
            outputDeps.nf = obj.nfHash;
            outputDeps.an = obj.kss{1}.angles;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
        function afeData = addLocData( afeData, locData )
            % assumes location data is raw DnnLocationKS output
            locFakeAFEsignal = struct();
            locFakeAFEsignal.Data = locData.sourcesDistribution(:)';
            locFakeAFEsignal.Name = 'DnnLocationDistribution';
            locFakeAFEsignal.azms = locData.azimuths(:)';
            afeData(afeData.Count+1) = locFakeAFEsignal;
        end
        
        function afeData = addLocDecisionData( afeData, locDecisionData )
            % assumes location data has been refined by LocalisationDecisionKS
            locFakeAFEsignal = struct();
            locFakeAFEsignal.Data = locDecisionData.sourcesPosteriors(:)';
            locFakeAFEsignal.Name = 'DnnLocationDistribution';
            locFakeAFEsignal.azms = locDecisionData.sourceAzimuths(:)';
            afeData(afeData.Count+1) = locFakeAFEsignal;
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

