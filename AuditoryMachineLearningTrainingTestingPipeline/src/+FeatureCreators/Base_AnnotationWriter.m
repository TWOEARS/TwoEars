classdef Base_AnnotationWriter < Core.IdProcInterface
    % Base Abstract base class for specifying features sets with which features
    % are extracted.
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        x;
        blockAnnotations;
        afeData;                    % current AFE signals used for vector construction
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        afeRequests = getAFErequests( obj )
        outputDeps = getFeatureInternOutputDependencies( obj )
        x = constructVector( obj ) % has to return a cell, first item the feature vector, 
                                   % second item the features description.
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = Base_AnnotationWriter()
            obj = obj@Core.IdProcInterface();
        end
        %% -------------------------------------------------------------------------------
        
        function setAfeData( obj, afeData )
            obj.afeData = afeData;
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            obj.inputProc.sceneId = obj.sceneId;
            inData = obj.loadInputData( wavFilepath, 'blockAnnotations' );
            obj.blockAnnotations = inData.blockAnnotations;
            selfData = obj.loadProcessedData( wavFilepath, 'x' );
            obj.x = selfData.x;
        end
        %% -------------------------------------------------------------------------------
        
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            [tmpOut, outFilepath] = loadProcessedData@Core.IdProcInterface( ...
                                                     obj, wavFilepath );
            obj.x = tmpOut.x;
            if nargin < 3  || any( strcmpi( 'blockAnnotations', varargin ) )
                if isfield( tmpOut, 'blockAnnotations' ) % new version
                    obj.blockAnnotations = tmpOut.blockAnnotations;
                else % old version; ba was saved in blockCreator cache
                    obj.inputProc.sceneId = obj.sceneId;
                    inData = obj.loadInputData( wavFilepath, 'blockAnnotations' );
                    obj.blockAnnotations = inData.blockAnnotations;
                    obj.save( wavFilepath );
                end
            end
            out = obj.getOutput( varargin{:} );
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function save( obj, wavFilepath, ~ )
            out.x = obj.x;
            out.blockAnnotations = obj.blockAnnotations;
            save@Core.IdProcInterface( obj, wavFilepath, out ); 
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.v = 4;
            outputDeps.featureProc = obj.getFeatureInternOutputDependencies();
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( obj, varargin )
            if nargin < 2  || any( strcmpi( 'blockAnnotations', varargin ) )
                out.blockAnnotations = obj.blockAnnotations;
            end
            if nargin < 2  || any( strcmpi( 'x', varargin ) )
                out.x = obj.x;
            end
        end
        
    end
    %% -----------------------------------------------------------------------------------
        
end

        

