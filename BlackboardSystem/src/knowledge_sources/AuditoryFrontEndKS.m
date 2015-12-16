classdef AuditoryFrontEndKS < AbstractKS
    % AuditoryFrontEndKS Aquires the current ear signals and puts them through
    % Two!Ears Auditory Front-End processing. This is basically a simulator of
    % functionality thatmay (partially) be outside the blackboard on the
    % deployment system

    properties (SetAccess = private)
        managerObject;                  % Two!Ears Auditory Front-End manager object -
                                        % holds the signal buffer (data obj)
        robotInterfaceObj;              % Scene simulator object
        timeStep = (512.0 / 44100.0);   % basic time step, i.e. update rate
        bufferSize_s = 10;              % 
        afeFs = 44100;                  % sample rate of AFE. If different from 
                                        % robotInterfaceObj.SampleRate, resampling is done
    end

    methods (Static)
        function regHash = getRequestHash( request )
            regHash = calcDataHash( request );
        end

        function plotSignalBlocks(bb, evnt)
            sigBlock = bb.signalBlocks{evnt.data};
            subplot(4, 4, [15, 16])
            plot(sigBlock.signals(:,1));
            axis tight; ylim([-1 1]);
            xlabel('k');
            title(sprintf('Block %d, head orientation: %d deg, left ear waveform', ...
                sigBlock.blockNo, sigBlock.headOrientation), 'FontSize', 12);
            subplot(4, 4, [13, 14])
            plot(sigBlock.signals(:,2));
            axis tight; ylim([-1 1]);
            xlabel('k');
            title(sprintf('Block %d, head orientation: %d deg, right ear waveform', ...
                sigBlock.blockNo, sigBlock.headOrientation), 'FontSize', 12);
        end
    end

    methods
        %% constructor
        function obj = AuditoryFrontEndKS(robotInterfaceObj,afeFs)
            obj = obj@AbstractKS();
            if nargin < 2 
                obj.afeFs = robotInterfaceObj.SampleRate; 
            else
                obj.afeFs = afeFs;
            end
            dataObj = dataObject([], obj.afeFs, ...
                obj.bufferSize_s, 2);  % Last input (2) indicates a stereo signal
            obj.managerObject = manager(dataObj);
            obj.robotInterfaceObj = robotInterfaceObj;
            obj.timeStep = obj.robotInterfaceObj.BlockSize / ...
                obj.robotInterfaceObj.SampleRate;
            obj.invocationMaxFrequency_Hz = inf;
        end

        %% KS logic
        function [bExecute, bWait] = canExecute(obj)
            bExecute = ~obj.robotInterfaceObj.isFinished();
            bWait = false;
        end

        function obj = execute(obj)
            % Two!Ears Binaural Simulator processing
            [signalFrame, processedTime] = obj.robotInterfaceObj.getSignal(obj.timeStep);
            if obj.afeFs ~= obj.robotInterfaceObj.SampleRate
                signalFrame = single( resample(...
                        double(signalFrame),obj.afeFs,obj.robotInterfaceObj.SampleRate) );
            end
            % Two!Ears Auditory Front-End Processing
            % process new data, append (as indicated by 1)
            obj.managerObject.processChunk(double(signalFrame), 1);
            obj.blackboard.advanceSoundTimeIdx(processedTime);
            obj.blackboard.addData('headOrientation', ...
                mod(obj.robotInterfaceObj.getCurrentHeadOrientation(), 360));
            % Trigger event
            notify(obj, 'KsFiredEvent');
        end

        %% KS utilities
        function createProcsForDepKS(obj, auditoryFrontEndDepKs)
            for z = 1:length( auditoryFrontEndDepKs.requests )
                obj.addProcessor( auditoryFrontEndDepKs.requests{z} );
            end
        end

        function obj = addProcessor( obj, request )
            reqSignal = obj.managerObject.addProcessor( request.name, request.params );
            % Provide compability between old and new AFE version
            if iscell(reqSignal) && length(reqSignal)==1
                reqSignal = reqSignal{1};
            end
            reqHash = AuditoryFrontEndKS.getRequestHash( request );
            obj.blackboard.addSignal(reqHash, reqSignal);
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
