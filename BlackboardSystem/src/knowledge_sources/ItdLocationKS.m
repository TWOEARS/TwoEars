classdef ItdLocationKS < AuditoryFrontEndDepKS
    % ItdLocationKS calculates posterior probabilities for each azimuth angle and
    % generates a SourcesAzimuthsDistributionHypothesis when provided with spatial
    % observation

    properties (SetAccess = private)
        icThreshold = 0.98;    % use only ITD values with a interaural coherence (IC)
                               % greater than this threshold, compare Dietz (2011)
        angles = 0:1:359;      % All azimuth angles to be considered
        dataPath = fullfile('learned_models','ItdLocationKS');
        blocksizeSec = 0.5;    % Signal block length processed by ItdLocationKS
    end

    methods
        function obj = ItdLocationKS()
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 1400, ...
                'fb_nERBs', 1, ...
                'rm_decaySec', 0, ...
                'rm_wSizeSec', 20E-3, ...
                'rm_hSizeSec', 10E-3, ...
                'cc_wSizeSec', 20E-3, ...
                'cc_hSizeSec', 10E-3);
            requests{1}.name = 'itd';
            requests{1}.params = param;
            requests{2}.name = 'time';
            requests{2}.params = param;
            requests{3}.name = 'ic';
            requests{3}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.invocationMaxFrequency_Hz = 2;
        end

        function [bExecute, bWait] = canExecute(obj)
            afeData = obj.getAFEdata();
            timeObj = afeData(2);
            bExecute = hasSignalEnergy(timeObj, obj.blocksizeSec, obj.timeSinceTrigger);
            bWait = false;
        end

        function phi = itdToAngle(obj, itd, lookupTable)
            %itdToAngle(itd, lookupTable) converts the given ITD values into azimuth angles
            %using the provided lookup table.
            phi = zeros(size(itd));
            for n = 1:size(itd, 2)
                % by calling the output S and MU, phi is z-scored, thus improving the
                % fitting
                phi(:,n) = polyval(lookupTable.p(:,n), itd(:,n), lookupTable.S{n}, ...
                                   lookupTable.MU(:,n));
            end
            % neglect angles > 95°
            phi(abs(phi)>95) = NaN;
        end

        function execute(obj)
            % Get ITDs and ICs
            afeData = obj.getAFEdata();
            itdObj = afeData(1);
            itd = itdObj.getSignalBlock(obj.blocksizeSec, obj.timeSinceTrigger)' .* 1000;
            icObj = afeData(3);
            ic = icObj.getSignalBlock(obj.blocksizeSec, obj.timeSinceTrigger)';
            % Load lookup table
            lookupTable = load(xml.dbGetFile(fullfile(obj.dataPath, 'default_lookup.mat')));
            % Convert ITDs to azimuth angles
            phi = obj.itdToAngle(itd',lookupTable);
            % Calculate the median over time for every frequency channel of the azimuth
            for n = 1:size(phi,2)
                % Applay IC threshold, compare eq. 9 in Dietz (2011)
                idx = ic(:,n)>obj.icThreshold & [diff(ic(:,n))>0; 0];
                angle = phi(idx,n);
                idx = ~isnan(angle);
                if size(angle(idx),1)==0
                    azimuth(n) = NaN;
                else
                    azimuth(n) = median(angle(idx));
                end
            end
            % Calculate the median over frequency channels
            % remove NaN
            azimuth = azimuth(~isnan(azimuth));
            % remove outliers more than 30deg away from median
            if length(azimuth)>0
                azimuth = azimuth(abs(azimuth-median(azimuth))<30);
            end
            % Calculate final azimuth value
            phi = round(wrapTo360(median(azimuth)));

            % Make two peaks in the posteriors distribution for the two possible
            % directions (front-back confusion)
            sourcesDistribution = zeros(size(obj.angles));
            % Use the value in the horizontal plane
            if phi>95 & phi<265
                phi = wrapTo360(phi+180);
            end
            %phi2 = NaN;
            if ~isnan(phi)
                sourcesDistribution(wrapTo360(phi)+1) = 1;
                %% Get front-back confusion
                %if phi<=180
                %    phi2 = phi + 2*(90-phi);
                %else
                %    phi2 = phi + 2*(270-phi);
                %end
                %idx = [wrapTo360(phi-1:phi+1)+1 wrapTo360(phi2-1:phi2+1)+1];
                %sourcesDistribution(idx) = [0.25 1.0 0.25 0.25 1.0 0.25];
            end

            % We simply take the average of posterior distributins across all the
            % samples for this block
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            aziHyp = SourcesAzimuthsDistributionHypothesis( ...
                currentHeadOrientation, obj.angles, sourcesDistribution);
            obj.blackboard.addData( ...
                'sourcesAzimuthsDistributionHypotheses', aziHyp, false, obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
        end

        function obj = generateLookupTable(obj, sceneDescription)
            %generateLookupTable(obj, sceneFile) extracts ITDs from a signal generated by
            %the Binaural Simulator after the given scene description file for all given
            %directions. The ITDs are then related to the azimuth angles and stored as a
            %lookup table.
            %
            isargfile(sceneDescription);
            mkdir('.', obj.dataPath);
            copyfile(sceneDescription, fullfile(obj.dataPath, sceneDescription), 'f');
            % Start simulator with corresponding localisation scene
            sim = simulator.SimulatorConvexRoom(sceneDescription);
            sim.Verbose = false;
            sim.Init = true;
            % Generate binaural cues
            angles = -90:90;
            for n = 1:length(angles)
                fprintf('----- Calculating ITDs for %.1f degrees\n', angles(n));
                sim.Sources{1}.set('Azimuth', angles(n));
                sim.ReInit = true;
                sig = sim.getSignal(10*sim.SampleRate);
                % Compute binaural cues using the Auditory Front End
                data = dataObject(sig, sim.SampleRate);
                auditoryFrontEnd = manager(data);
                auditoryFrontEnd.addProcessor(obj.requests{1}.name, ... % ITDs
                                              obj.requests{1}.params);
                auditoryFrontEnd.processSignal();
                % Save binaural cues
                itd(n,1:16) = median(data.itd{1}.Data(:)',2) * 1000; % convert to ms
            end
            sim.ShutDown = true;
            % Fit the lookup data
            for n = 1:size(itd,2)
                [p(:,n), S{n}, MU(:,n)] = polyfit(itd(:,n), angles', 12); % 12
            end
            % Save lookup table in database
            save(fullfile(obj.dataPath, ...
                          strcat(sceneDescription(1:end-4), '_lookup.mat')), ...
                 'p', 'MU', 'S');
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
