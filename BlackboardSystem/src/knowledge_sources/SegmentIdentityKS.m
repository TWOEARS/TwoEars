classdef SegmentIdentityKS < AbstractAMLTTPKS
    
    properties (SetAccess = private)
%         label_added = false;
    end

    methods
        function obj = SegmentIdentityKS( modelName, modelDir, ppRemoveDc )
            obj@AbstractAMLTTPKS( modelName, modelDir, ppRemoveDc );
            obj.setInvocationFrequency(inf);
        end
            
        % Visualisation
        function visualise(obj)

%             if ~isempty(obj.blackboardSystem.locVis)
%                 idloc = obj.blackboard.getData( ...
%                     'segIdentityHypotheses', obj.trigger.tmIdx);
%                 if isempty( idloc )
%                     obj.blackboardSystem.locVis.setLocationIdentity(...
%                         {}, {}, {}, {});
%                 else
%                     idloc = idloc.data;
%                     obj.blackboardSystem.locVis.setLocationIdentity(...
%                         {idloc(:).label}, {idloc(:).p}, {idloc(:).d}, {idloc(:).loc});
%                 end
%             end
            
        end
    end
    
    methods (Access = protected)        
        function amlttpExecute( obj, afeBlock )
            mask = obj.blackboard.getLastData('segmentationHypotheses', ...
                obj.trigger.tmIdx);
            % create masked copy of afeData
            d = [];
            score = {};
            estSrcAzm = [];
            for ii = 1 : numel(mask.data)
                afeBlock_masked = SegmentIdentityKS.maskAFEData( afeBlock, ...
                    mask.data(ii).softMask, ...
                    mask.data(ii).cfHz, ...
                    mask.data(ii).hopSize );
                
                obj.featureCreator.setAfeData( afeBlock_masked );
                x = obj.featureCreator.constructVector();
                [d, score] = obj.model.applyModel( x{1} );
                estSrcAzm = mask.data(ii).refAzm;
                bbprintf(obj, '[SegmentIdentitiyKS:] source %i at %i deg azm: %s with %i%% score.\n', ...
                     ii, estSrcAzm, obj.modelname, int16(score(1)*100) );
                identHyp = IdentityHypothesis( obj.modelname, ...
                         score(1), d, obj.blockCreator.blockSize_s, estSrcAzm );
                obj.blackboard.addData( 'segIdentityHypotheses', ...
                     identHyp, true, obj.trigger.tmIdx );
            end
        end
    end
    
    methods (Static)
        % mask should be of [time x frequency]
        function afeBlock = maskAFEData( afeData, mask, cfHz, maskHopSize )
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = afeData.keys
                afeSignal = afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    for ii = 1 : numel( afeSignal )
                        if isa( afeSignal{ii}, 'TimeFrequencySignal' ) || ...
                                isa( afeSignal{ii}, 'CorrelationSignal' ) || ...
                                isa( afeSignal{ii}, 'ModulationSignal' )
                            afeSignalExtract{ii} = ...
                                   afeSignal{ii}.maskSignalCopy( mask, cfHz, maskHopSize );
                        else
                            afeSignalExtract{ii} = afeSignal{ii};
                        end
                    end
                else
                    if isa( afeSignal, 'TimeFrequencySignal' ) || ...
                            isa( afeSignal, 'CorrelationSignal' ) || ...
                            isa( afeSignal, 'ModulationSignal' )
                        afeSignalExtract = ...
                                      afeSignal.maskSignalCopy( mask, cfHz, maskHopSize );
                    else
                        afeSignalExtract = afeSignal;
                    end
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
                clear afeSignalExtract;
            end
        end
    end % static methods
end
