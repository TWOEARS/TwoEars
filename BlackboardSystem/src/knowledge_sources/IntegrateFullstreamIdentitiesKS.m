classdef IntegrateFullstreamIdentitiesKS < AbstractKS
    
    properties (SetAccess = private)
        maxObjects;
        classThresholds;
        generalThreshold;
        integratedProbs;
        integratedNsrcs;
        leakFactor;
    end

    methods
        function obj = IntegrateFullstreamIdentitiesKS( leakFactor, maxObjects, classThresholds, generalThreshold )
            obj@AbstractKS();
            obj.setInvocationFrequency(inf);
            if nargin < 1 || isempty( leakFactor )
                leakFactor = 0.5; 
            end
            if nargin < 2 || isempty( maxObjects )
                maxObjects = inf; 
            end
            if nargin < 3 || isempty( classThresholds )
                classThresholds = struct();
            end
            if nargin < 4 || isempty( generalThreshold )
                generalThreshold = 0.5;
            end
            obj.leakFactor = leakFactor;
            obj.maxObjects = maxObjects;
            obj.classThresholds = classThresholds;
            obj.generalThreshold = generalThreshold;
            obj.integratedNsrcs = 0;
            obj.integratedProbs = struct();
        end
        
        function setInvocationFrequency( obj, newInvocationFrequency_Hz )
            obj.invocationMaxFrequency_Hz = newInvocationFrequency_Hz;
        end
        
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute(obj)
            % get all identityHypotheses
            idloc = obj.blackboard.getData( ...
                                  'identityHypotheses', obj.trigger.tmIdx).data;
            labels = {idloc.label};
            ps = [idloc.p]; 
            ds = [idloc.d];
%             % get nSrcs estimate
%             nsrcsHypos = obj.blackboard.getData( ...
%                                'NumberOfSourcesHypotheses', obj.trigger.tmIdx );
%             assert( numel( nsrcsHypos.data ) == 1 );
%             numSrcs = nsrcsHypos.data.n;
%             % leaky integrate nSrcs
%             obj.integratedNsrcs = obj.leakFactor * numSrcs + ...
%                                   (1 - obj.leakFactor) * obj.integratedNsrcs;
            % create current map
            currentProbs = struct();
            for ii = 1 : numel( labels )
                if ~isfield( currentProbs, labels{ii} )
                    currentProbs.(labels{ii}) = 0;
                end
                p = ps(ii);
                currentProbs.(labels{ii}) = currentProbs.(labels{ii}) + p;
            end
            % leaky integrate map
            currentClasses = fieldnames( currentProbs );
            for ii = 1 : numel( currentClasses )
                if ~isfield( obj.integratedProbs, currentClasses{ii} )
                    obj.integratedProbs.(currentClasses{ii}) = currentProbs.(currentClasses{ii});
                else
                    obj.integratedProbs.(currentClasses{ii}) = ...
                        obj.leakFactor * currentProbs.(currentClasses{ii}) + ...
                        (1 - obj.leakFactor) * obj.integratedProbs.(currentClasses{ii});
                end
            end
            % sort
            allClasses = fieldnames( obj.integratedProbs );
            intPs = zeros( numel( allClasses ), 1 );
            for ii = 1 : numel( allClasses )
                intPs(ii) = obj.integratedProbs.(allClasses{ii});
            end
            [intPs, intPsSortIdxs] = sort( intPs, 'Descend' );
            ds = obj.applyClassSpecificThresholds( allClasses(intPsSortIdxs), intPs );
            objects = struct( ...
                'loc', {nan},...
                'labels', {allClasses(intPsSortIdxs)},...
                'ps', {intPs},...
                'ds', {ds} );
            % only allow n objects
            maxedObjects = obj.onlyAllowNobjectsPerLocation( objects );
            % create objectHypotheses
            for oo = 1 : numel( maxedObjects.labels )
                newProb = maxedObjects.ps(oo);
                if newProb > 1
                    newProb = 1;
                end
                objectHyp = IdentityHypothesis( ...
                    maxedObjects.labels{oo}, ...
                    newProb, ...
                    maxedObjects.ds(oo), ...
                    idloc(1).concernsBlocksize_s, ...
                    nan );
                obj.blackboard.addData( 'integratedIdentityHypotheses', ...
                    objectHyp, true, obj.trigger.tmIdx );
            end
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
            
        % Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                idloc = obj.blackboard.getData( ...
                    'integratedIdentityHypotheses', obj.trigger.tmIdx);
                if isempty( idloc )
                    obj.blackboardSystem.locVis.setIdentity(...
                        {}, {}, {});
                else
                    idloc = idloc.data;
                    obj.blackboardSystem.locVis.setIdentity(...
                        {idloc(:).label}, {idloc(:).p}, {idloc(:).d});
                end
            end
        end
    end
    
    methods (Access = protected)        

        function ds = applyClassSpecificThresholds( obj, labels, ps )
            ds = zeros( size( ps ) );
            for ii = 1 : numel( labels )
                if isfield( obj.classThresholds, labels{ii} )
                    thr = obj.classThresholds.(labels{ii});
                else
                    thr = obj.generalThreshold;
                end
                if ps(ii) >= thr
                    ds(ii) = 1;
                else
                    ds(ii) = -1;
                end
            end
        end

        function maxedObjects = onlyAllowNobjectsPerLocation( obj, objects )
            objects.labels(obj.maxObjects+1:end) = [];
            objects.ps(obj.maxObjects+1:end) = [];
            objects.ds(obj.maxObjects+1:end) = [];
            maxedObjects = objects;
        end
        
    end
    
    methods (Static)
    end % static methods
end
