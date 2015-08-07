classdef LocationKS < AuditoryFrontEndDepKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation

    properties (SetAccess = private)
        name;                  % Name of LocationKS
        gmtkLoc;               % GMTK engine
        angles;                % All azimuth angles to be considered
        tempPath;              % A path for temporary files
        dataPath = ['learned_models' filesep 'LocationKS' filesep];
        angularResolution = 1; % Default angular resolution is 1deg
        bTrain = false;        % Start in training mode
        blocksize_s;
    end

    methods
        function obj = LocationKS(gmName, angularResolution, bTrain)
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 8000, ...
                'fb_nChannels', 32, ...
                'rm_decaySec', 0, ...
                'ild_wSizeSec', 20E-3, ...
                'ild_hSizeSec', 10E-3, ...
                'rm_wSizeSec', 20E-3, ...
                'rm_hSizeSec', 10E-3, ...
                'cc_wSizeSec', 20E-3, ...
                'cc_hSizeSec', 10E-3);
            requests{1}.name = 'ild';
            requests{1}.params = param;
            requests{2}.name = 'itd';
            requests{2}.params = param;
            requests{3}.name = 'time';
            requests{3}.params = param;
            requests{4}.name = 'ic';
            requests{4}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.blocksize_s = 0.5;
            obj.name = gmName;
            if nargin>2
                obj.bTrain = bTrain;
            end
            if nargin>1
                obj.angularResolution = angularResolution;
            end
            obj.angles = 0:obj.angularResolution:(360-obj.angularResolution);
            obj.invocationMaxFrequency_Hz = 2;
            dimFeatures = param.map('fb_nChannels') * 2; % ITD + ILD
            % The following creates an GMTK object that is used for localization
            % For GMTK (Graphical Models Toolkit) see:
            % http://melodi.ee.washington.edu/gmtk/
            obj.gmtkLoc = gmtkEngine(gmName, dimFeatures, obj.dataPath, obj.bTrain);
            % The GMTK construction also creates a tmp dir under your system temporary
            % folder which will contain tmp files GMTK needs for its processing. Those
            % files will be deleted when this knowledge source is deconstructed (see
            % delete() method).
            obj.tempPath = obj.gmtkLoc.tempPath;
        end

        function delete(obj)
            % Clean up after ending this knowledge source
            rmdir(obj.tempPath, 's');
        end

        function [bExecute, bWait] = canExecute(obj)
            afeData = obj.getAFEdata();
            timeSObj = afeData(3);
            bExecute = hasSignalEnergy(timeSObj, obj.blocksize_s, obj.timeSinceTrigger);
            bWait = false;
        end

        function execute(obj)
            afeData = obj.getAFEdata();
            ildsSObj = afeData(1);
            ilds = ildsSObj.getSignalBlock(obj.blocksize_s, obj.timeSinceTrigger)';
            itdsSObj = afeData(2);
            itds = itdsSObj.getSignalBlock(obj.blocksize_s, obj.timeSinceTrigger)' .* ...
                1000;
            icsSObj = afeData(4);
            ics = icsSObj.getSignalBlock(obj.blocksize_s, obj.timeSinceTrigger)';

            % Check if the trained data has the correct angular resolution
            % The angular resolution of the trained data can be found in the corresponding
            % *.str file. We first extract it from that file and compare it then to the
            % angular resolution of the running LocationKS
            strFile = xml.dbGetFile(fullfile(obj.gmtkLoc.workPath, [obj.name, '.str']));
            fid = fopen(strFile,'r');
            strText = fscanf(fid,'%s');
            fclose(fid);
            % Find the position of the stored angular resolution and return number of
            % stored angular values
            nAngles = str2double(regexpi(strText, ...
                'discretehiddencardinality([0-9]+);', 'tokens', 'once'));
            trainedAngularResolution = 360/nAngles;
            if trainedAngularResolution~=obj.angularResolution
                error(['Your current angular resolution (%.1f) mismatches the ', ...
                       'learned resolution (%.1f).'], obj.angularResolution, ...
                       trainedAngularResolution);
            end

            % Generate a temporary feature flist for GMTK
            featureBlock = [itds; ilds];
            if sum(sum(isnan(featureBlock) + isinf(featureBlock))) > 0
                warning('LocationKS: NaNs or Infs in feature block; aborting inference');
                return;
            end
            % FIXME: the following is a workaround, as the tmp dir is deleted at the
            % moment after every execution of LocationKS, but only created once at the
            % instanciation of the gmtkEngine. In the long run it should only
            % be deleted at the end of the Blackboard execution, when the agenda of the
            % Blackboard is empty.
            if ~exist(obj.tempPath, 'dir')
                mkdir(obj.tempPath);
            end
            [~,tmpfn] = fileparts(tempname);
            tmpfn = fullfile(obj.tempPath, tmpfn);
            htkfn = strcat(tmpfn, '.htk');
            writehtk(htkfn, featureBlock);
            flist = strcat(tmpfn, '.flist');
            fidFlist = fopen(flist, 'w');
            fprintf(fidFlist, '%s\n', htkfn);
            fclose(fidFlist);

            % Calculate posteriors of clique 0 (which contains RV:location)
            obj.gmtkLoc.infer(flist, 0);

            % Now if successful, posteriors are written in output files 
            % with an appendix of _0 for the first utterance
            post = load(strcat(obj.gmtkLoc.outputCliqueFile, '_0'));

            % We simply take the average of posteriors across all the
            % samples for this block
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            locHyp = LocationHypothesis(currentHeadOrientation, obj.angles, mean(post,1));
            obj.blackboard.addData('locationHypotheses', ...
                locHyp, false, obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ));
        end

        function obj = generateTrainingData(obj, sceneDescription)
            %generateTrainingData(obj, sceneFile) extracts ITDs and ILDs from using
            %signals created by the HRTFs and source material specified in sceneFile.
            %This data can then be used to train the GMTK localisation model with train().
            %
            if ~obj.bTrain
                error(['LocationKS has to be initiated in training mode to allow ', ...
                       'for this functionality.']);
            end
            if nargin<2
                sceneDescription = [obj.name '.xml'];
            end
            isargfile(sceneDescription);
            copyfile(sceneDescription,fullfile(obj.dataPath,[obj.name '.xml']),'f');
            % Start simulator with corresponding localisation scene
            sim = simulator.SimulatorConvexRoom(sceneDescription);
            sim.Verbose = false;
            sim.Init = true;
            % Create data path
            dataFilesPath = fullfile(obj.gmtkLoc.workPath, 'data');
            mkdir(dataFilesPath);
            % Generate binaural cues
            obj.angles = 0:obj.angularResolution:(360-obj.angularResolution);
            for n = 1:length(obj.angles)
                fprintf('----- Calculating ITDs and ILDs at %.1f degrees\n', ...
                        obj.angles(n));
                sim.Sources{1}.set('Azimuth', obj.angles(n));
                sim.ReInit = true;
                sig = sim.getSignal(10*sim.SampleRate);
                % Compute binaural cues using the Auditory Front End
                data = dataObject(sig, sim.SampleRate);
                auditoryFrontEnd = manager(data);
                for z = 1:length(obj.requests)
                    auditoryFrontEnd.addProcessor(obj.requests{z}.name, ...
                                                  obj.requests{z}.params);
                end
                auditoryFrontEnd.processSignal();
                % Save binaural cues
                itd = data.itd{1}.Data(:)' .* 1000; % convert to ms
                ild = data.ild{1}.Data(:)';
                fileName = fullfile(dataFilesPath, ...
                                    sprintf('spatial_cues_angle%05.1f', obj.angles(n)));
                writehtk(strcat(fileName, '.htk'), [itd; ild]);
                fprintf('\n');
            end
            sim.ShutDown = true;
        end

        function obj = removeTrainingData(obj)
            %removeTrainingData(obj) deletes all the data that was locally created by
            %generateTrainingData(obj).
            if ~obj.bTrain
                error(['LocationKS has to be initiated in training mode to allow ', ...
                       'for this functionality.']);
            end
            if exist(fullfile(obj.gmtkLoc.workPath, 'data'),'dir')
                rmdir(fullfile(obj.gmtkLoc.workPath, 'data'), 's');
            end
            if exist(fullfile(obj.gmtkLoc.workPath, 'flists'),'dir')
                rmdir(fullfile(obj.gmtkLoc.workPath, 'flists'), 's');
            end
            delete(fullfile(obj.gmtkLoc.workPath, '*command'));
            delete(fullfile(obj.gmtkLoc.workPath, '*_train*'));
            delete(fullfile(obj.gmtkLoc.workPath, '*0.gmp'));
            delete(fullfile(obj.gmtkLoc.workPath, '*1.gmp'));
            delete(fullfile(obj.gmtkLoc.workPath, '*2.gmp'));
        end

        function obj = train(obj)
            %train(obj) trains the locationKS using extracted ITDs and ILDs which are
            %stored in the Two!Ears database under learned_models/locationKS/ and GMTK

            if ~obj.bTrain
                error(['LocationKS has to be initiated in training mode to allow ', ...
                       'for this functionality.']);
            end

            % Configuration
            featureExt = 'htk';
            labelExt = 'lab';

            % Generate GMTK parameters
            % Now need to create GM structure files (.str) and generate relevant GMTK
            % parameters, either manually or with generateGMTKParameters.
            % Finally, perform model triangulation.
            generateGmtkParameters(obj.gmtkLoc, numel(obj.angles));
            obj.gmtkLoc.triangulate;
            % Estimate GM parameters
            flistPath = fullfile(obj.gmtkLoc.workPath, 'flists');
            if ~exist(flistPath, 'dir')
                mkdir(flistPath);
            end
            trainFeatureList = fullfile(flistPath, 'train_features.flist');
            trainLabelList = fullfile(flistPath, 'train_labels.flist');
            fidObsList = fopen(trainFeatureList, 'w');
            fidLabList = fopen(trainLabelList, 'w');
            for n = 1:numel(obj.angles)
                baseFileName = fullfile(obj.gmtkLoc.workPath, 'data', ...
                      sprintf('spatial_cues_angle%05.1f', obj.angles(n)));
                featureFileName = sprintf('%s.%s', baseFileName, featureExt);
                fprintf(fidObsList, '%s\n', fullfile(pwd, featureFileName));
                labelFileName = sprintf('%s.%s', baseFileName, labelExt);
                fprintf(fidLabList, '%s\n', fullfile(pwd, labelFileName));
                % Generate and save feature labels for each angle
                ftr = readhtk(featureFileName);
                fid = fopen(labelFileName, 'w');
                fprintf(fid, '%d\n', repmat(n-1,1,size(ftr,2)));
                fclose(fid);
            end
            fclose(fidObsList);
            fclose(fidLabList);
            obj.gmtkLoc.train(trainFeatureList, trainLabelList);
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
