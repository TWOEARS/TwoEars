classdef ColorationKS < AuditoryFrontEndDepKS
    % ColorationKS predicts the coloration of a signal compared ...

    properties (SetAccess = private)
        auditoryFrontEndParameter;
        blocksize_s;
    end

    methods
        function obj = ColorationKS()
            obj.blocksize_s = 0.5;
            param = genParStruct( ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 20000, ...
                'fb_nERBs', 1)
            requests{1}.name = 'filterbank';
            requests{1}.params = param;
            requests{2}.name = 'adaptation';
            requests{2}.params = param;
            requests{3}.name = 'time';
            requests{3}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.auditoryFrontEndParameter = param;
        end

        function [bExecute, bWait] = canExecute(obj)
            afeData = obj.getAFEdata();
            timeSObj = afeData(3);
            bExecute = hasSignalEnergy(timeSObj, obj.blocksize_s, obj.timeSinceTrigger);
            bWait = false;
        end

        function execute(obj)
            %TODO:
            % In order to implement this KS the following prolbem has to be solved in
            % order to allow a comparison between the actual test signal and a reference
            % signal:
            % * two instances of the Binaural Simulator and the AFE has to be running in
            %   parallel
            % * both of them have to get the same commands for turning their head etc.
            error('ColorationKS functionality has to be implemented.');
            obj.blackboard.addData('colorationHypotheses', colorationValue, false, ...
                obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
