classdef AudioplayKS < AuditoryFrontEndDepKS

    properties (SetAccess = private)
    end

    methods
        function obj = AudioplayKS()
            requests{1}.name = 'time';
            requests{1}.params = genParStruct();
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.invocationMaxFrequency_Hz = 0.25;
        end

        function delete(obj)
        end

        function [b, wait] = canExecute(obj)
            b = true;
            wait = false;
        end

        function execute(obj)
            afeData = obj.getAFEdata();
            timeSig = afeData(1);
            sig = timeSig{1}.getSignalBlock( 6, 0 );
            sig(:,2) = timeSig{2}.getSignalBlock( 6, 0 );
            soundsc( sig, 44100 );
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
