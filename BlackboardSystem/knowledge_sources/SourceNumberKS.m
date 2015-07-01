classdef SourceNumberKS < AuditoryFrontEndDepKS
    % SourceNumberKS predicts the number of perceived sources.
    %
    % At the moment this is only a dummy implementation that will always return 5.
    %
    % In the long run most probably this function will compare two signals and judge which
    % of the two has higher audio quality

    properties (SetAccess = private)
        auditoryFrontEndParameter;
        blocksize_s;
    end

    methods
        function obj = SourceNumberKS()
            param = genParStruct( ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 20000, ...
                'fb_nERBs', 1);
            requests{1}.name = 'filterbank';
            requests{1}.params = param;
            requests{2}.name = 'time';
            requests{2}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.auditoryFrontEndParameter = param;
            obj.blocksize_s = 0.5;
        end

        function [bExecute, bWait] = canExecute(obj)
            afeData = obj.getAFEdata();
            timeSObj = afeData('time');
            bExecute = hasSignalEnergy(timeSObj, obj.blocksize_s, obj.timeSinceTrigger);
            bWait = false;
        end

        function execute(obj)
            numberOfSources = 1;
            warning('SourceNumberKS functionality has to be implemented.');
            obj.blackboard.addData('sourceNumberHypotheses', numberOfSources, false, ...
                obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
