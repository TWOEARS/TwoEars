classdef IntegrateSegregatedIdentitiesKS < AbstractKS
    
    properties (SetAccess = private)
        maxObjectsAtLocation;
        classThresholds;
        generalThreshold;
        integratedMap; % absolute
        integratedNsrcs;
        leakFactor;
        hypSpread;
        npdf;
        maxnpdf;
    end

    methods
        function obj = IntegrateSegregatedIdentitiesKS( leakFactor, hypSpread, maxObjectsAtLocation, classThresholds, generalThreshold )
            obj@AbstractKS();
            obj.setInvocationFrequency(inf);
            if nargin < 1 || isempty( leakFactor )
                leakFactor = 0.5; 
            end
            if nargin < 2 || isempty( hypSpread )
                hypSpread = 15; 
            end
            x = -3*hypSpread : 1 : 3*hypSpread;
            npdf = normpdf( x, 0, hypSpread );
            if nargin < 3 || isempty( maxObjectsAtLocation )
                maxObjectsAtLocation = inf; 
            end
            if nargin < 4 || isempty( classThresholds )
                classThresholds = struct();
            end
            if nargin < 5 || isempty( generalThreshold )
                generalThreshold = 0.5;
            end
            obj.leakFactor = leakFactor;
            obj.hypSpread = hypSpread;
            obj.maxObjectsAtLocation = maxObjectsAtLocation;
            obj.classThresholds = classThresholds;
            obj.generalThreshold = generalThreshold;
            obj.integratedNsrcs = 0;
            obj.integratedMap = struct();
            obj.npdf = npdf;
            obj.maxnpdf = max( npdf );
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
            uniqueLocs = unique( locs );
            % get headOrientation and nSrcs estimate
            headOrientation = obj.blackboard.getData( ...
                                         'headOrientation', obj.trigger.tmIdx );
            headOrientation = headOrientation.data;
%             nsrcsHypos = obj.blackboard.getData( ...
%                                'NumberOfSourcesHypotheses', obj.trigger.tmIdx );
%             assert( numel( nsrcsHypos.data ) == 1 );
%             numSrcs = nsrcsHypos.data.n;
            numSrcs = numel( uniqueLocs );
            % leaky integrate nSrcs
            obj.integratedNsrcs = obj.leakFactor * numSrcs + ...
                                  (1 - obj.leakFactor) * obj.integratedNsrcs;
            % create current map
            currentMap = struct();
            absLocs = wrapTo360( locs + round( headOrientation ) );
            absLocs(absLocs == 0) = 360;
            for ii = 1 : numel( labels )
                if ~isfield( currentMap, labels{ii} )
                    currentMap.(labels{ii}) = zeros( 1, 360 );
                end
                x = absLocs(ii) - 3*obj.hypSpread : 1 : absLocs(ii) + 3*obj.hypSpread;
                x = wrapTo360( x );
                x(x == 0) = 360;
                p = obj.npdf * ps(ii);
                currentClassMap = currentMap.(labels{ii}); 
                currentClassMap(x) = currentClassMap(x) + p;
                currentMap.(labels{ii}) = currentClassMap;
            end
            % leaky integrate map
            currentClasses = fieldnames( currentMap );
            for ii = 1 : numel( currentClasses )
                if ~isfield( obj.integratedMap, currentClasses{ii} )
                    obj.integratedMap.(currentClasses{ii}) = currentMap.(currentClasses{ii});
                else
                    obj.integratedMap.(currentClasses{ii}) = ...
                        obj.leakFactor * currentMap.(currentClasses{ii}) + ...
                        (1 - obj.leakFactor) * obj.integratedMap.(currentClasses{ii});
                end
            end
            % integrate source map
            allClasses = fieldnames( obj.integratedMap );
            integratedSourceMap = zeros( 1, 360 );
            for ii = 1 : numel( allClasses )
                integratedSourceMap = integratedSourceMap + ...
                                             obj.integratedMap.(allClasses{ii});
            end
            % determine source locations
            [locPeaks, locPeaksIdxs] = findpeaks( ...
                [integratedSourceMap(end) ...
                 integratedSourceMap ...
                 integratedSourceMap(1)] );
            locPeaksIdxs = locPeaksIdxs - 1;
            assert( all( locPeaksIdxs > 0 ) && ...
                    all( locPeaksIdxs <= numel( integratedSourceMap ) ) );
            [~, locPeaksSortIdxs] = sort( locPeaks, 'descend' );
            locPeakAzms = locPeaksIdxs(locPeaksSortIdxs);
            locPeakAzms(round( obj.integratedNsrcs )+1:end) = [];
            % sort into bins per location
            nLocations = min( round( obj.integratedNsrcs ), numel( locPeakAzms ) );
            locBinnedObjects = cell( 1, nLocations );
            for ll = 1 : nLocations 
                locPs = zeros( numel( allClasses ), 1 );
                for ii = 1 : numel( allClasses )
                    curClassMap = obj.integratedMap.(allClasses{ii});
                    locPs(ii) = curClassMap(locPeakAzms(ll));
                end
                [locPs, locPsSortIdxs] = sort( locPs, 'Descend' );
                ds = obj.applyClassSpecificThresholds( allClasses(locPsSortIdxs), locPs );
                loc = wrapTo180( locPeakAzms(ll) - headOrientation );
                locBinnedObjects{ll} = struct( ...
                    'loc', {loc},...
                    'labels', {allClasses(locPsSortIdxs)},...
                    'ps', {locPs},...
                    'ds', {ds} );
            end
            % only allow n objects per location
            locMaxedObjects = obj.onlyAllowNobjectsPerLocation( locBinnedObjects );
            % create objectHypotheses
            for ll = 1 : numel( locMaxedObjects )
                locObjs = locMaxedObjects{ll};
                for oo = 1 : numel( locObjs.labels )
                    newProb = locObjs.ps(oo) / obj.maxnpdf;
                    if newProb > 1
                        newProb = 1;
                    end
                    objectHyp = SingleBlockObjectHypothesis( ...
                        locObjs.labels{oo}, ...
                        locObjs.loc, ...
                        newProb, ...
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
                    'singleBlockObjectHypotheses', obj.trigger.tmIdx);
                if isempty( idloc )
                    obj.blackboardSystem.locVis.setLocationIdentity(...
                        {}, {}, {}, {});
                else
                    idloc = idloc.data;
                    obj.blackboardSystem.locVis.setLocationIdentity(...
                        {idloc(:).label}, {idloc(:).p}, {idloc(:).d}, {idloc(:).loc});
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
                if ps(ii) >= thr* obj.maxnpdf
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
    end % static methods
end
