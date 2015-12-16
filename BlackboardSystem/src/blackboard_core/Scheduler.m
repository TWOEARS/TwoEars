classdef Scheduler < handle
    
    properties (SetAccess = {?BlackboardSystem})
        monitor;          % Blackboard monitor
    end
    
    
    events
        AgendaEmpty
    end
    
    methods
        function obj = Scheduler(monitor)
            obj.monitor = monitor;
        end
        
        %% utility function for printing the obj
        function s = char( obj )
            mcobj = metaclass ( obj );
            s = mcobj.Name;
        end
        
        %% main scheduler loop
        %   processes all agenda items that are executable
        %   executes in order of attentional priority
        function processAgenda(obj)
            while ~isempty( obj.monitor.agenda )
                agendaOrder = obj.generateAgendaOrder();
                [exctdKsi,cantExctKsis,~] = ...
                    obj.executeFirstExecutableAgendaOrderItem( agendaOrder );
                if isempty(exctdKsi)
                    % rm the non-executable and non-waiting KSIs
                    obj.monitor.agenda(cantExctKsis) = []; 
                    break; 
                    % if no KSi was executable, leave this processing round
                end;
                obj.monitor.pastAgenda(end+1) = obj.monitor.executing;
                obj.monitor.executing = [];
            end
        end

        %% inner scheduler loop
        %   processes the first item on the prioritized agenda list that's 
        %   executable
        %   
        %   exctdKsi:   true if a KSi has been executed <=> false if no KSi
        %               was executable
        function [exctdKsi,cantExctKsis,cantExctYetKsis] = executeFirstExecutableAgendaOrderItem( obj, agendaOrder )
            exctdKsi = [];
            cantExctKsis = [];
            cantExctYetKsis = [];
            for ai = agendaOrder
                nextKsi = obj.monitor.agenda(ai);
                if nextKsi.ks.isMaxInvocationFreqMet()
                    nextKsi.ks.setActiveArgument( nextKsi.triggerSrc, nextKsi.triggerSndTimeIdx, nextKsi.eventName );
                    [canExec, waitForExec] = nextKsi.ks.canExecute();
                    if canExec
                        bbprintf(obj.monitor, '[Executing KS:] %s\n', char(nextKsi.ks));
                        nextKsi.ks.timeStamp();
                        exctdKsi = ai;
                        obj.monitor.executing = obj.monitor.agenda(exctdKsi);
                        obj.monitor.agenda(exctdKsi) = []; % take out of agenda before executing
                        nextKsi.ks.execute();
                        break;
                    elseif ~waitForExec
                        cantExctKsis(end+1) = ai;
                    end
                else
                    cantExctYetKsis(end+1) = ai;
                end
            end
        end

        %% generate a prioritized list of agenda items
        % at the moment, the list is only considering the attentional
        % priorities
        function agendaOrder = generateAgendaOrder( obj )
            attendPrios = obj.getAgendaAttentionalPriorities();
            agendaOrder = attendPrios(2,:);
        end
        
        %% function attendPrios = getAgendaAttentionalPriorities( obj )
        %   get a list of agenda items sorted by their attentional
        %   priorities, from high to low
        %   
        %   attendPrios(1,:):   the priority values
        %   attendPrios(2,:):   the respective index of the item in the
        %                       agenda
        function attendPrios = getAgendaAttentionalPriorities( obj )
            attendPrios = arrayfun( @(x)(x.ks.attentionalPriority), obj.monitor.agenda );
            [attendPrios, apIx] = sort( attendPrios, 'descend' );
            attendPrios = [attendPrios; apIx];
        end
        
        %% function triggerTimes = getAgendaTriggerTimes( obj )
        %   get a list of agenda items sorted by the time they have been
        %   added to the agenda, from earlier to later
        %   
        %   triggerTimes(1,:):  the triggering times
        %   triggerTimes(2,:):	the respective index of the item in the
        %                       agenda
        function triggerTimes = getAgendaTriggerTimes( obj )
            triggerTimes = arrayfun( @(x)(x.triggerSndTimeIdx), obj.monitor.agenda );
            [triggerTimes, ttIx] = sort( triggerTimes, 'ascend' );
            triggerTimes = [triggerTimes; ttIx];
        end
        
    end
end

