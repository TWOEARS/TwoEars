classdef BlackboardKsWrapper_AnnotationWriter < Core.IdProcInterface
    % Abstract base class for wrapping KS into an emulated blackboard
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        kss;
        bbs;
        afeDataIndexOffset;
        out;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        postproc( obj, afeData, blockAnnotations )
        outputDeps = getKsInternOutputDependencies( obj )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = BlackboardKsWrapper_AnnotationWriter( kss )
            obj = obj@Core.IdProcInterface();
            if ~iscell( kss )
                obj.kss = {kss};
            else
                obj.kss = kss;
            end
            obj.bbs = BlackboardSystem( false );
            for ii = 1 : numel( kss )
                obj.kss{ii}.setBlackboardAccess( obj.bbs.blackboard, obj.bbs );
            end
        end
        %% -------------------------------------------------------------------------------

        function [afeRequests, ksReqHashes] = getAfeRequests( obj )
            afeRequests = [];
            ksReqHashes = [];
            for ii = 1 : numel( obj.kss )
                afeRequests = [afeRequests obj.kss{ii}.requests];
                ksReqHashes = [ksReqHashes obj.kss{ii}.reqHashs];
            end
        end
        %% -------------------------------------------------------------------------------

        function obj = setAfeDataIndexOffset( obj, afeDataIndexOffset )
            obj.afeDataIndexOffset = afeDataIndexOffset;
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            warning( 'off', 'BB:tNotIncreasing' );
            obj.inputProc.sceneId = obj.sceneId;
            inData = obj.loadInputData( wavFilepath, 'blockAnnotations' );
            selfData = obj.loadProcessedData( wavFilepath, 'afeBlocks', 'blockAnnotations' );
            obj.out = struct( 'afeBlocks', {selfData.afeBlocks}, ...
                              'blockAnnotations', {selfData.blockAnnotations} );
            obj.postproc( inData.blockAnnotations );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.v = 1;
            outputDeps.ksProc = obj.getKsInternOutputDependencies();
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( obj, varargin )
            out.afeBlocks = obj.out.afeBlocks;
            out.blockAnnotations = obj.out.blockAnnotations;
        end
        %% -------------------------------------------------------------------------------

    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

