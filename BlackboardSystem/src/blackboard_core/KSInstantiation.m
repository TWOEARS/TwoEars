classdef KSInstantiation < handle
    
    properties (SetAccess = private)
        ks;            % Triggered knowledge source
        triggerSndTimeIdx;
        triggerSrc;
        eventName;
    end
    
    methods
        function obj = KSInstantiation( ks, triggerSoundTimeIdx, triggerSource, eventName )
            obj.ks = ks;
            obj.triggerSndTimeIdx = triggerSoundTimeIdx;
            obj.triggerSrc = triggerSource;
            obj.eventName = eventName;
        end
    end
    
end
