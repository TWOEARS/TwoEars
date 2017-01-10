classdef CollectSegmentIdentityKS < AbstractKS
    
    properties (SetAccess = private)
        maxObjectsAtLocation;
        classThresholds;
        generalThreshold;
    end

    methods
        function obj = CollectSegmentIdentityKS( maxObjectsAtLocation, classThresholds, generalThreshold )
            obj@AbstractKS();
            obj.setInvocationFrequency(inf);
            if nargin < 1 || isempty( maxObjectsAtLocation )
                maxObjectsAtLocation = inf; 
            end
            if nargin < 2 || isempty( classThresholds )
                classThresholds = struct();
            end
            if nargin < 3 || isempty( generalThreshold )
                generalThreshold = 0.5;
            end
            obj.maxObjectsAtLocation = maxObjectsAtLocation;
            obj.classThresholds = classThresholds;
            obj.generalThreshold = generalThreshold;
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
                                  'segIdentityHypotheses', obj.trigger.tmIdx).data;
            labels = {idloc.label};
            ps = [idloc.p]; 
            ds = [idloc.d];
            locs = [idloc.loc];
            [ps,maxorder] = sort( ps, 'Descend' );
            labels = labels(maxorder);
            ds = ds(maxorder);
            locs = locs(maxorder);
            % apply class-specific thresholds
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
            % sort into bins per location
            uniqueLocs = unique( locs );
            locMaxedObjects = cell( size( uniqueLocs ) );
            for ll = 1 : numel( uniqueLocs )
                hypsAtLoc = locs == uniqueLocs(ll);
                locMaxedObjects{ll} = struct( ...
                    'loc', {uniqueLocs(ll)},...
                    'labels', {labels(hypsAtLoc)},...
                    'ps', {ps(hypsAtLoc)},...
                    'ds', {ds(hypsAtLoc)} );
            end
            % only allow n objects per location
            for ll = 1 : numel( locMaxedObjects )
                locObjs = locMaxedObjects{ll};
                locObjs.labels(obj.maxObjectsAtLocation+1:end) = [];
                locObjs.ps(obj.maxObjectsAtLocation+1:end) = [];
                locObjs.ds(obj.maxObjectsAtLocation+1:end) = [];
                locMaxedObjects{ll} = locObjs;
            end
            % create objectHypotheses
            for ll = 1 : numel( locMaxedObjects )
                locObjs = locMaxedObjects{ll};
                for oo = 1 : numel( locObjs.labels )
                    objectHyp = SingleBlockObjectHypothesis( ...
                        locObjs.labels{oo}, ...
                        locObjs.loc, ...
                        locObjs.ps(oo), ...
                        locObjs.ds(oo), ...
                        idloc(1).concernsBlocksize_s );
                    obj.blackboard.addData( 'singleBlockObjectHypotheses', ...
                        objectHyp, true, obj.trigger.tmIdx );
                end
            end
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
            
        % Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                idloc = obj.blackboard.getData( ...
                    'singleBlockObjectHypotheses', obj.trigger.tmIdx).data;
                obj.blackboardSystem.locVis.setLocationIdentity(...
                    {idloc(:).label}, {idloc(:).p}, {idloc(:).d}, {idloc(:).loc});
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

        function locMaxedObjects = onlyAllowNobjectsPerLocation( obj, locMaxedObjects )
            for ll = 1 : numel( locMaxedObjects )
                locObjs = locMaxedObjects{ll};
                locObjs.labels(obj.maxObjectsAtLocation+1:end) = [];
                locObjs.ps(obj.maxObjectsAtLocation+1:end) = [];
                locObjs.ds(obj.maxObjectsAtLocation+1:end) = [];
                locMaxedObjects{ll} = locObjs;
            end
        end
        
    end
    
    methods (Static)

        function locMaxedObjects = sortIntoBinsPerLocation( locs, labels, ps, ds )
            uniqueLocs = unique( locs );
            locMaxedObjects = cell( size( uniqueLocs ) );
            for ll = 1 : numel( uniqueLocs )
                hypsAtLoc = locs == uniqueLocs(ll);
                locMaxedObjects{ll} = struct( ...
                    'loc', {uniqueLocs(ll)},...
                    'labels', {labels(hypsAtLoc)},...
                    'ps', {ps(hypsAtLoc)},...
                    'ds', {ds(hypsAtLoc)} );
            end
        end
        
    end % static methods
end
