classdef AcousticCuesKS < AbstractKS
    % ACOUSTICCUES
    
    properties (Access = public)
        dataObject;               % WP2 data object
    end
    
    methods
        function obj = AcousticCuesKS(blackboard, dataObject)
            obj = obj@AbstractKS(blackboard);
            obj.dataObject = dataObject;
        end
        
        function b = canExecute(obj)
            b = false;
            
            numPeripherySignals = obj.blackboard.getNumPeripherySignals;
            
            if numPeripherySignals == 0
                return
            else
                b = true;
            end
        end
        
        function execute(obj)
            if length(obj.blackboard.peripherySignals) < 1
                return
            else
                % Get current periphery signals
                peripherySignals = obj.blackboard.peripherySignals{1};

                % Compute acoustic cues from WP2 data object
                % as [numChannels x numFrames]
                ic = obj.dataObject.ic_xcorr{1}.Data(:)';
                % Convert ITD unit from s to ms
                itds = obj.dataObject.itd_xcorr{1}.Data(:)' .* 1000;
                ilds = obj.dataObject.ild{1}.Data(:)';
                ratemap = obj.dataObject.ratemap_power{1}.Data(:)';
                
                % Compute new acoustic cues data structure
                acousticCues = AcousticCues(peripherySignals.blockNo, ...
                    peripherySignals.headOrientation, itds, ilds, ...
                    ic, ratemap );
                
                % Remove old acoustic cues from the bb
                if obj.blackboard.getNumAcousticCues > 0
                    obj.blackboard.removeAcousticCues();
                end
                
                % Add acoustic cues to the blackboard
                idx = obj.blackboard.addAcousticCues(acousticCues);
                
                if obj.blackboard.verbosity > 0
                    % Display that KS has fired
                    fprintf('-------- AcousticCuesKS has fired.\n');
                end
                
                % Trigger event
                notify(obj.blackboard, 'NewAcousticCues', ...
                    BlackboardEventData(idx));
            end
        end
    end
end
