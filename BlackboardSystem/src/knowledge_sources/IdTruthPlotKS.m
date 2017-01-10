classdef IdTruthPlotKS < AuditoryFrontEndDepKS

    properties (SetAccess = private)
        fig;
        subplots;
        labels;
        onOffsets;
        ylim_timSignal;
    end

    methods
        function obj = IdTruthPlotKS(labels,onOffsets)
            requests{1}.name = 'time';
            requests{1}.params = genParStruct();
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.invocationMaxFrequency_Hz = inf;
            obj.fig = figure('Name','Identification: Truth vs Model');
            set( obj.fig, 'ButtonDownFcn', @IdTruthPlotKS.pauseToggle );
            obj.subplots(1) = subplot(3,1,1,'Parent',obj.fig);
            obj.subplots(2) = subplot(3,1,[2,3],'Parent',obj.fig);
            clear plotIdentificationScene;
            obj.labels = labels;
            obj.onOffsets = onOffsets;
            obj.invocationMaxFrequency_Hz = 2;
            obj.ylim_timSignal = [];
        end

        function delete(obj)
        end

        function [b, wait] = canExecute(obj)
            b = true;
            wait = false;
        end
        
        function setYLimTimeSignal(obj, ylim)
            obj.ylim_timSignal = ylim;
        end

        function execute(obj)
            afeData = obj.getAFEdata();
            timeSig = afeData(1);
            timeRange(2) = obj.blackboard.currentSoundTimeIdx;
            timeLen = double(length( timeSig{1}.Data )) / timeSig{1}.FsHz;
            timeRange(1) = timeRange(2) - timeLen;
            idHyps = obj.blackboard.getDataBlock( 'identityHypotheses', timeLen );
%            figure( obj.fig );
            timeSig{1}.plot( obj.subplots(1), ...
                genParStruct('fsize_label',8,'fsize_title',8,'fsize_axes',8) );
            if ~isempty(obj.ylim_timSignal)
                set( gca, 'YLim', obj.ylim_timSignal );
            end
            set( gca, 'XTick', [] );
            plotIdentificationScene( obj.subplots(2), ...
                obj.labels, obj.onOffsets, idHyps, timeRange );
            drawnow;
        end
        
    end
    
    methods (Static)
        function pauseToggle(src,~)
            pause
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
