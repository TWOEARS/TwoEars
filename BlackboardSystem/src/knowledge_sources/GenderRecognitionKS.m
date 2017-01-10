classdef GenderRecognitionKS < AuditoryFrontEndDepKS
    % GENDERECOGNITIONKS Performs gender recognition (male/female).
    %
    % AUTHOR:
    %   Copyright (c) 2016      Christopher Schymura
    %                           Cognitive Signal Processing Group
    %                           Ruhr-Universitaet Bochum
    %                           Universitaetsstr. 150
    %                           44801 Bochum, Germany
    %                           E-Mail: christopher.schymura@rub.de
    %
    % LICENSE INFORMATION:
    %   This program is free software: you can redistribute it and/or
    %   modify it under the terms of the GNU General Public License as
    %   published by the Free Software Foundation, either version 3 of the
    %   License, or (at your option) any later version.
    %
    %   This material is distributed in the hope that it will be useful,
    %   but WITHOUT ANY WARRANTY; without even the implied warranty of
    %   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    %   GNU General Public License for more details.
    %
    %   You should have received a copy of the GNU General Public License
    %   along with this program. If not, see <http://www.gnu.org/licenses/>

    properties ( Access = private )
        basePath                % Path where extracted features and trained
                                % classifiers should be stored.
        pathToDataset           % Path to audio data for training and test.
        pathToModels
        classificationModel
        modelType = 'lda';
    end
    
    properties ( Constant, Hidden )
        BLOCK_SIZE_SEC = 0.5;   % This KS works with a constant block size
                                % of 500ms.
    end
    
    methods ( Static, Hidden )
        function downloadGridCorpus()
            % DOWNLOADGRIDCORPUS Automatically downloads the endpointed 
            %   audio files of the GRID audiovisual sentence corpus from
            %   http://spandh.dcs.shef.ac.uk/gridcorpus/.
            
            % Check if folder for storing the GRID corpus exists and create
            % one if not.
            pathToGridCorpus = fullfile( db.path(), 'sound_databases', ...
                'grid_corpus' );
            
            if ~exist( pathToGridCorpus, 'dir' )
                mkdir( pathToGridCorpus );
            end
            
            % Number of speakers in GRID corpus is fixed to 34.
            NUM_SPEAKERS = 34;
            
            for speakerIdx = 1 : NUM_SPEAKERS
                % Check if files for current speaker have been downloaded.
                if ~exist( fullfile(pathToGridCorpus, ...
                        ['s', num2str(speakerIdx)]), 'dir' )
                    
                    disp(['GridCorpus::Downloading files for speaker ', ...
                        num2str(speakerIdx), ' ...']);
                    
                    % Assemble download URL for current speaker.
                    url = ['http://spandh.dcs.shef.ac.uk/gridcorpus/s', ...
                        num2str(speakerIdx), '/audio/s', num2str(speakerIdx), '.tar'];
                    
                    % Download and unpack audio files for current speaker.
                    untar( url, pathToGridCorpus );
                    
                    % Get path to audio files and perform sampling rate
                    % conversion.
                    pathToSpeakerFiles = fullfile(pathToGridCorpus, ...
                        ['s', num2str(speakerIdx)]);                    
                    fileList = getFiles( pathToSpeakerFiles, 'wav' );
                    
                    for file = fileList
                        info = audioinfo( fullfile(pathToSpeakerFiles, file{:}) );
                        
                        % Resample if necessary
                        if info.SampleRate ~= 44100
                            disp(['GenderRecognitionKS::Processing file ', file{:}, ...
                                ' for speaker ', num2str(speakerIdx), ' ...']);
                            
                            [signal, fs] = audioread( fullfile(pathToSpeakerFiles, file{:}) );
                            signal = resample( signal, 44100, fs );
                            
                            % Get number of replicates.
                            numReplicates = ceil( 44100 / length(signal) );
                            
                            % Replicate signal and truncate to desired
                            % length of 1s.
                            signal = repmat( signal(:), numReplicates, 1 );
                            signal = signal( 1 : 44100 );
                            
                            audiowrite( fullfile(pathToSpeakerFiles, file{:}), ...
                                signal, 44100 );
                        end
                    end
                end
            end
        end
        
        function features = processBlock( ratemap, pitch, spectralFeatures )
            % PROCESSBLOCK
            
            % Compute formant map.
            formantMap = zeros( size(ratemap) );
            formantMap(:, 2 : end - 1) = 0.5 .* (ratemap(:, 3 : end) - ...
                ratemap(:, 1 : end - 2));
            formantMap(:, 1) = ratemap(:, 2) - ratemap(:, 1);
            formantMap(:, end) = ratemap(:, end) - ratemap(:, end - 1);
            
            rawFeatures = [formantMap, pitch(:, 2), ...
                spectralFeatures(:, 1 : 5), spectralFeatures(:, 7 : end)];
            
            % Compute statistical parameters of the extracted features.
            features = [mean(rawFeatures), std(rawFeatures), ...
                skewness(rawFeatures), kurtosis(rawFeatures)];
        end
        
        function [features, labels] = getFeatureSet( pathToFeatures )
            % GETFEATURESET
            
            filesFeaturesMale = fullfile( 'male', getFiles( ...
                fullfile(pathToFeatures, 'male'), 'mat' ) );
            filesFeaturesFemale = fullfile( 'female', getFiles( ...
                fullfile(pathToFeatures, 'female'), 'mat' ) );
            numFeatures = [length( filesFeaturesMale ), ...
                length( filesFeaturesFemale )];
            featureFiles = [filesFeaturesMale, filesFeaturesFemale];
            
            features = zeros(2 * sum(numFeatures), 312);
            labels = [zeros(2 * numFeatures(1), 1); ...
                ones(2 * numFeatures(2), 1)];
            
            for fileIdx = 1 : sum(numFeatures)
                % Load current file.
                f = load( fullfile(pathToFeatures, ...
                    featureFiles{fileIdx}) );
                
                startIdx = (fileIdx - 1) * 2 + 1;
                endIdx = startIdx + 1;
                features(startIdx : endIdx, :) = f.features;
            end
        end
    end

    methods ( Access = public )
        function obj = GenderRecognitionKS()
            % GENDERECOGNITIONKS Method for class instantiation.
            %   Automaticlly handles classifier training if trained models
            %   are not available at instantiation. This KS is using a
            %   fixed set of parameters for feature extraction and
            %   classification, which cannot be changed by the user.
            
            % Generate AFE parameter structure. All parameters are fixed
            % and cannot be changed by the user.
            afeParameters = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'ihc_method', 'halfwave', ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 50, ...
                'fb_highFreqHz', 5000, ...
                'fb_nChannels', 64, ...
                'rm_wSizeSec', 0.02, ...
                'rm_hSizeSec', 0.01, ...
                'rm_wname', 'hann', ...
                'p_pitchRangeHz', [50, 600] );

            % Set AFE requests and instantiate AFE.
            requests{1}.name = 'ratemap';
            requests{1}.params = afeParameters;
            requests{2}.name = 'pitch';
            requests{2}.params = afeParameters;
            requests{3}.name = 'spectralFeatures';
            requests{3}.params = afeParameters;
            obj = obj@AuditoryFrontEndDepKS( requests );
            
            % Get path to stored features and models. If such a directory
            % does not exist, it will be created.
            obj.basePath = fullfile( db.tmp(), 'learned_models', ...
                'GenderRecognitionKS' );
            
            if ~exist( obj.basePath, 'dir' )
                mkdir( obj.basePath );
            end
            
            % Get paths where audio files and models are stored.
            obj.pathToDataset = fullfile( obj.basePath, 'data' );
            obj.pathToModels = fullfile( obj.basePath, 'models' );
            
            if ~exist( obj.pathToDataset, 'dir' )
                mkdir( obj.pathToDataset );
            end
            
            if ~exist( obj.pathToModels, 'dir' )
                mkdir( obj.pathToModels );
            end            
            
            % Check if model has already been trained. If not, training is
            % executed automatically.
            try
                switch obj.modelType
                    case 'gmm_logistic'
                        modelName = 'model_gmm_logistic.mat';
                    case 'lda'
                        modelName = 'model_lda.mat';
                end
                
                pathToBestModel = db.getFile( ...
                    ['learned_models/GenderRecognitionKS/models/', ...
                    modelName] );
                
                file = load( pathToBestModel );
                obj.classificationModel = file.model;
            catch
                obj.downloadGridCorpus();
                obj.generateDataset();
                obj.train();
            end
        end

        function [bExecute, bWait] = canExecute( obj )
            bExecute = obj.hasEnoughNewSignal( obj.BLOCK_SIZE_SEC );
            bWait = false;
        end

        function execute( obj )
            % Get features for current signal block.
            ratemap = obj.getNextSignalBlock( 1, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );
            pitch = obj.getNextSignalBlock( 2, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );
            spectralFeatures = obj.getNextSignalBlock( 3, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );

            % Assemble feature vector and perform dimensionality reduction.
            features = obj.processBlock(ratemap{1}, pitch{1}, ...
                spectralFeatures{1});
            features = features * obj.classificationModel.pcaMatrix;

            % Compute activations and perform classification.
            switch obj.modelType
                case 'gmm_logistic'
                    activations = obj.classificationModel.gmm.posterior( features );
                    [label, probabilities] = ...
                        obj.classificationModel.classifier.predict( activations );
                case 'lda'
                    [label, probabilities] = ...
                        obj.classificationModel.classifier.predict( features );
            end

%                 disp(['GenderRecognitionKS [Male: ', ...
%                     num2str(probabilities(1)), '% / Female: ', ...
%                     num2str(probabilities(2)), '%]']);

            genderHyp = GenderHypothesis( label, probabilities );
            obj.blackboard.addData( 'genderHypotheses', ...
                genderHyp, true, obj.trigger.tmIdx );
            notify( obj, 'KsFiredEvent', ...
                BlackboardEventData(obj.trigger.tmIdx) );

            % Visualisation
            if ~isempty(obj.blackboardSystem.genderVis)
                obj.blackboardSystem.genderVis.draw(genderHyp);
            end
        end
    end
    
    methods ( Access = private )
        function train( obj )
            % TRAIN
            
            disp('GenderRecognitionKS::Training classifiers ...');
            
            % Get datasets for training and validation.
            pathToTrainingData = fullfile( obj.pathToDataset, 'train' );
            [featuresTraining, labelsTraining] = ...
                obj.getFeatureSet( pathToTrainingData );
            
            pathToTestData = fullfile( obj.pathToDataset, 'test' );
            [featuresValidation, labelsValidation] = ...
                obj.getFeatureSet( pathToTestData );
            
            switch obj.modelType
                case 'gmm_logistic'
                    % Initialize parameter grid-search.
                    [pcaExplainedVariance, gmmNumMixtures] = ...
                        ndgrid(0.65 : 0.05 : 0.75, 4 : 24);
                    modelParameters = [pcaExplainedVariance(:), gmmNumMixtures(:)];
                    numParameters = size(modelParameters, 1);
                    
                    validationErrors = zeros( size(modelParameters, 2), 1 );
                    models = cell( size(modelParameters, 2), 1 );
                    
                    for parameterIdx = 1 : numParameters
                        % Check if model has already been trained.
                        modelName = ['mdl_gmm_logistic_', ...
                            num2str(modelParameters(parameterIdx, 1)), ...
                            '_', num2str(modelParameters(parameterIdx, 2)), '.mat'];
                        if ~exist( fullfile(obj.pathToModels, modelName), 'file' );
                            
                            % Perform dimensionality reduction with PCA.
                            [lambda, eigenVectors] = pca( featuresTraining );
                            
                            explainedVariance = cumsum(lambda) ./ max(cumsum(lambda));
                            [~, maxIdx] = ...
                                max( explainedVariance > modelParameters(parameterIdx, 1) );
                            
                            model.pcaMatrix = eigenVectors(:, 1 : maxIdx);
                            
                            transformedFeaturesTraining = featuresTraining * model.pcaMatrix;
                            transformedFeaturesValidation = featuresValidation * model.pcaMatrix;
                            
                            try
                                model.gmm = fitgmdist( transformedFeaturesTraining, ...
                                    modelParameters(parameterIdx, 2), ...
                                    'RegularizationValue', 1E-3, ...
                                    'options', statset('MaxIter', 250));
                                
                                activationsTraining = ...
                                    model.gmm.posterior( transformedFeaturesTraining );
                                
                                model.classifier = fitclinear( ...
                                    activationsTraining, labelsTraining, ...
                                    'Learner', 'logistic', ...
                                    'Regularization', 'lasso', ...
                                    'BatchSize', 128 );
                                
                                % Evaluate model.
                                activationsValidation = ...
                                    model.gmm.posterior( transformedFeaturesValidation );
                                
                                predictedLabels = predict( model.classifier, activationsValidation );
                                
                                currentValidationError = ...
                                    100 * (1 - (sum(predictedLabels == labelsValidation) / ...
                                    size(transformedFeaturesValidation, 1)));
                                
                                model.validationError = currentValidationError;
                            catch
                                model.pcaMatrix = [];
                                model.gmm = [];
                                model.classifier = [];
                                model.validationError = NaN;
                            end
                            
                            models{parameterIdx} = model;
                            validationErrors(parameterIdx) = model.validationError;
                            
                            save( fullfile(obj.pathToModels, modelName), 'model', '-v7.3' );
                        else
                            file = load( fullfile(obj.pathToModels, modelName) );
                            model = file.model;
                            
                            models{parameterIdx} = model;
                            validationErrors(parameterIdx) = file.model.validationError;
                        end
                        
                        disp([ '[', num2str(parameterIdx), '/', num2str(numParameters), ']', ...
                            ' P: ', ...
                            num2str(100 * modelParameters(parameterIdx, 1)), ...
                            ' % explained variance, ', ...
                            num2str(modelParameters(parameterIdx, 2)), ...
                            ' mixtures ::', ' Validation error ', ...
                            num2str(model.validationError), '%']);
                    end
                    
                    % Get best performing model.
                    [~, bestIdx] = min(validationErrors);
                    model = models{bestIdx};
                    save( fullfile(obj.pathToModels, 'model_gmm_logistic.mat'), 'model', '-v7.3' );
                case 'lda'
                    pcaExplainedVariance = 0.1 : 0.01 : 0.99;
                    numParameters = length( pcaExplainedVariance );
                    
                    validationErrors = zeros( numParameters, 1 );
                    models = cell( numParameters, 1 );
                    
                    for parIdx = 1 : numParameters
                        modelName = ['mdl_lda_', ...
                            num2str(pcaExplainedVariance(parIdx)), '.mat'];
                        
                        if ~exist( fullfile(obj.pathToModels, modelName), 'file' );
                            % Perform dimensionality reduction with PCA.
                            [lambda, eigenVectors] = pca( featuresTraining );
                            
                            explainedVariance = cumsum(lambda) ./ max(cumsum(lambda));
                            [~, maxIdx] = ...
                                max( explainedVariance > pcaExplainedVariance(parIdx) );
                            
                            model.pcaMatrix = eigenVectors(:, 1 : maxIdx);
                            
                            transformedFeaturesTraining = featuresTraining * model.pcaMatrix;
                            transformedFeaturesValidation = featuresValidation * model.pcaMatrix;
                            
                            model.classifier = fitcdiscr( ...
                                transformedFeaturesTraining, labelsTraining );
                            
                            predictedLabels = predict( model.classifier, ...
                                transformedFeaturesValidation );
                            
                            currentValidationError = ...
                                100 * (1 - (sum(predictedLabels == labelsValidation) / ...
                                size(transformedFeaturesValidation, 1)));
                            
                            model.validationError = currentValidationError;
                            
                            models{parIdx} = model;
                            validationErrors(parIdx) = model.validationError;
                            
                            save( fullfile(obj.pathToModels, modelName), 'model', '-v7.3' );
                        else
                            file = load( fullfile(obj.pathToModels, modelName) );
                            model = file.model;
                            
                            models{parIdx} = model;
                            validationErrors(parIdx) = file.model.validationError;
                        end
                        
                        disp([ '[', num2str(parIdx), '/', num2str(numParameters), ']', ...
                            ' P: ', ...
                            num2str(100 * pcaExplainedVariance(parIdx)), ...
                            ' % explained variance :: Validation error ', ...
                            num2str(model.validationError), '%']);
                    end
                    
                    % Get best performing model.
                    [~, bestIdx] = min(validationErrors);
                    model = models{bestIdx};
                    save( fullfile(obj.pathToModels, 'model_lda.mat'), 'model', '-v7.3' );
                otherwise
                    error('Model not supported.');
            end
        end
        
        function generateDataset( obj )
            % GENERATEDATASET
            
            pathToGridCorpus = fullfile( db.path(), 'sound_databases', ...
                'grid_corpus' );
            
            % Initialize AFE.
            afeParameters = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'ihc_method', 'halfwave', ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 50, ...
                'fb_highFreqHz', 5000, ...
                'fb_nChannels', 64, ...
                'rm_wSizeSec', 0.02, ...
                'rm_hSizeSec', 0.01, ...
                'rm_wname', 'hann', ...
                'p_pitchRangeHz', [50, 600], ...
                'p_confThresPerc', 0.33 );
            
            requests = {'ratemap', 'pitch', 'spectralFeatures'};
            
            warning( 'off', 'all' );
            dataObj = dataObject( [], 16000, 1, 2 );
            managerObj = manager( dataObj, requests, afeParameters );
            warning( 'on', 'all' );
            
            % Specify speakers for training and test sets.
            femaleSpeakers = {'s4', 's7', 's11', 's15', 's16', 's18', 's20', ...
                's21', 's22', 's23', 's24', 's25', 's29', 's31', 's33', 's34'};
            maleSpeakers = {'s1', 's2', 's3', 's5', 's6', 's8', 's9', 's10', ...
                's12', 's13', 's14', 's17', 's19', 's26', 's27', 's28', 's30', 's32'};
            trainSet = {femaleSpeakers{1 : end - 2}, maleSpeakers{1 : end - 4}};
            testSet = {femaleSpeakers{end - 2 : end}, maleSpeakers{end - 2 : end}};
            
            % Initialize the binaural simulator and fix all simulation parameters that
            % will not change during data generation.
            sim = simulator.SimulatorConvexRoom();
            
            sim.set( ...
                'Renderer', @ssr_binaural, ...
                'SampleRate', 44100, ...
                'MaximumDelay', 0.05, ...
                'PreDelay', 0.0, ...
                'LengthOfSimulation', 1, ...    % Fixed to one second here.
                'Sources', {simulator.source.Point()}, ...
                'Sinks', simulator.AudioSink(2), ...
                'HRIRDataset', simulator.DirectionalIR('impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa'), ...
                'Verbose', false );
            
            sim.Sources{1}.set( ...
                'Name', 'Speech', ...
                'AudioBuffer', simulator.buffer.Ring, ...
                'Volume', 1, ...
                'Position', [cosd(0); sind(0); 1.75] );
            
            sim.Sinks.set( ...
                'Position', [0; 0; 1.75], ...   % Cartesian position of the dummy head
                'Name', 'DummyHead' );          % Identifier of the audio sink.
            
            for currentSet = {'train', 'test'}
                if strcmp( currentSet{:}, 'train' )
                    speakerIds = trainSet;
                else
                    speakerIds = testSet;
                end
                
                for speaker = speakerIds
                    % Get gender of current speaker.
                    if any( strcmp(speaker{:}, femaleSpeakers) )
                        gender = 'female';
                        continue;
                    else
                        gender = 'male';
                    end
                    
                    % Check if folder for storing audio data exists.
                    pathToAudioFiles = fullfile( obj.pathToDataset, ...
                        currentSet{:}, gender );
                    
                    if ~exist( pathToAudioFiles, 'dir' )
                        mkdir( pathToAudioFiles );
                    end
                    
                    % Get all audio files for current speaker.
                    listOfAudioFiles = getFiles( fullfile( ...
                        pathToGridCorpus, speaker{:}), 'wav' );
                    
                    for file = listOfAudioFiles
                        [~, filename] = fileparts( file{:} );
                        processedFileName = ...
                            [speaker{:}, '_', filename, '_', gender, '.mat'];
                        pathToFile = fullfile(pathToAudioFiles, processedFileName);
                        
                        if ~exist( pathToFile, 'file' )
                            disp(['GenderRecognitionKS::Rendering file ', ...
                                processedFileName, ' ...']);
                            
                            % Add audio file to simulator.
                            set( sim.Sources{1}.AudioBuffer, ...
                                'File', fullfile(pathToGridCorpus, speaker{:}, file{:}) );
                            sim.init();
                            
                            earSignals = double( sim.getSignal() );
                            earSignals = earSignals( 1 : 44100, : );
                            
                            % Resample ear signals to 16kHz.
                            earSignals = resample( earSignals, 16000, 44100 );
                            
                            % Divide 1s ear signals into 2 500ms blocks and
                            % perform feature extraction.                            
                            features = [];
                            
                            for segIdx = 1 : 2               
                                startIdx = (segIdx - 1) * 8000 + 1;
                                endIdx = startIdx + 8000 - 1;
                                
                                % Perform feature extraction.
                                managerObj.processSignal( earSignals(startIdx : endIdx, :) );
                                
                                ratemap = 0.5 .* ( dataObj.ratemap{1}.Data(:) + ...
                                    dataObj.ratemap{2}.Data(:) );
                                pitch = dataObj.pitch{1}.Data(:);
                                spectralFeatures = dataObj.spectralFeatures{1}.Data(:);
                                
                                features = [features; ...
                                    obj.processBlock( ratemap, pitch, spectralFeatures ) ];
                            end
                            
                            % Save features.
                            save( pathToFile, 'features', '-v7.3' );                            
                        end
                    end
                end
            end
        end
    end
end