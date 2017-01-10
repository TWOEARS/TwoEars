classdef AbstractAMLTTPKS < AuditoryFrontEndDepKS
    
    properties (SetAccess = protected)
        modelname;
        model;                 % classifier model
        featureCreator;
        blockCreator;
    end
    
    methods (Abstract, Access = protected)
        % a method through which the derived classes implement application
        % of features to the internal model instance given an AFE data block
        amlttpExecute( obj, afeBlock )
    end
    
    methods
        function obj = AbstractAMLTTPKS( modelName, modelDir, ppRemoveDc )
            modelFileName = [modelDir filesep modelName];
            v = load( db.getFile( [modelFileName '.model.mat'] ) );
            if ~isa( v.featureCreator, 'FeatureCreators.Base' )
                error( 'Loaded model''s featureCreator must implement FeatureCreators.Base.' );
            end
            afeRequests = v.featureCreator.getAFErequests();
%             if nargin > 2 && pp_bNormalizeRMS
%                 for ii = 1 : numel( afeRequests )
%                     afeRequests{ii}.params.replaceParameters( ...
%                                    genParStruct( 'pp_bNormalizeRMS', pp_bNormalizeRMS ) );
%                 end
%             end
            if nargin > 2 && ppRemoveDc
                for ii = 1 : numel( afeRequests )
                    afeRequests{ii}.params.replaceParameters( ...
                                   genParStruct( 'pp_bRemoveDC', ppRemoveDc ) );
                end
            end
            obj = obj@AuditoryFrontEndDepKS( afeRequests );
            obj.featureCreator = v.featureCreator;
            obj.initBlockCreator(v);
            obj.initModel(v);
            obj.modelname = modelName;
            obj.setInvocationFrequency(4);
        end
        
        function initBlockCreator(obj, inputContent)
            if isfield(inputContent, 'blockCreator')
                if ~isa( inputContent.blockCreator, 'BlockCreators.Base' )
                    error( 'Loaded model''s block creator must implement BeatureCreators.Base.' );
                end
            elseif isfield(inputContent, 'blockSize_s')
                inputContent.blockCreator = ...
                    BlockCreators.StandardBlockCreator( inputContent.blockSize_s, 0.5/3 );
            else
                % for models missing a block creator instance
                inputContent.blockCreator = ...
                    BlockCreators.StandardBlockCreator( 0.5, 0.5/3 );
            end
            obj.blockCreator = inputContent.blockCreator;
        end
        
        function initModel(obj, inputContent)
            if ~isa( inputContent.model, 'Models.Base' )
                error( 'Loaded internal model must implement Models.Base.' );
            end
            obj.model = inputContent.model;
        end
        
        function setInvocationFrequency( obj, newInvocationFrequency_Hz )
            obj.invocationMaxFrequency_Hz = newInvocationFrequency_Hz;
        end
        
        %% utility function for printing the obj
        function s = char( obj )
            s = [char@AuditoryFrontEndDepKS( obj ), '[', obj.modelname, ']'];
        end
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute( obj )
            % calls KS-specific execute imeplementations and notifies the blackboard system 
            afeBlock = obj.cutAFEBlock();
            obj.amlttpExecute( afeBlock );
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
        
        function delete( obj )
        end
    end
    
    methods (Access = protected)
        function afeData = cutAFEBlock( obj )
            %% cut and retrieve most recent block of AFE data
            afeData = obj.getAFEdata();
            afeData = obj.blockCreator.cutDataBlock( afeData, obj.timeSinceTrigger );
        end
    end
end
