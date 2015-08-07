classdef AbstractKS < handle & matlab.mixin.Heterogeneous

    properties (SetAccess = protected)
        blackboard;
        blackboardSystem;
        attentionalPriority = 0;
        invocationMaxFrequency_Hz = 2;
        lastExecutionTime_s = -inf;
        trigger;                    % struct consisting of elements
                                    % src,tmIdx,eventName
    end
    
    events
        KsFiredEvent
    end
    
    methods (Abstract)
        % find out if the precondition for the expert is met
        % returns whether it can execute at this moment or not,
        % and also, whether it shall remain in the agenda, if not yet
        % executable
        [b, wait] = canExecute(obj) 
        % the function through which an expert performs its action
        % no result is returned, but the contents of the blackboard
        % may be modified
        execute(obj)
    end
    
    methods

        %% Constructor
        function obj = AbstractKS(blackboard)
            if nargin > 0
                obj.blackboard = blackboard;
            end
        end
        
        function setBlackboardAccess( obj, blackboard, blackboardSystem )
            obj.blackboard = blackboard;
            obj.blackboardSystem = blackboardSystem;
        end

        %% Set arguments for execution after triggering
        function setActiveArgument(obj, triggerSrc, triggerTmIdx, eventName)
            obj.trigger.src = triggerSrc;
            obj.trigger.tmIdx = triggerTmIdx;
            obj.trigger.eventName = eventName;
        end
        
        %% Attentional modificators
        function focus( obj )
            obj.attentionalPriority = obj.attentionalPriority + 1;
        end
        
        function unfocus( obj )
            obj.attentionalPriority = obj.attentionalPriority - 1;
        end
        
        function resetFocus( obj )
            obj.attentionalPriority = 0;
        end

        %% timing methods
        function timeStamp( obj )
            obj.lastExecutionTime_s = obj.blackboard.currentSoundTimeIdx;
        end
        
        function executeYet = isMaxInvocationFreqMet( obj )
            timeSinceLastExec = ...
                obj.blackboard.currentSoundTimeIdx - obj.lastExecutionTime_s;
            executeYet = timeSinceLastExec >= (1.0 / obj.invocationMaxFrequency_Hz);
        end
        
        function tmOffset = timeSinceTrigger( obj )
            tmOffset = (obj.blackboard.currentSoundTimeIdx - obj.trigger.tmIdx);
        end
        
        %% utility function for printing the obj
        function s = char( obj )
            mcobj = metaclass( obj );
            s =  mcobj.Name;
        end
        
    end
    
    methods (Sealed)
        
        function e = eq( a, b )
            e = eq@handle( a, b );
        end
    end
    
end
