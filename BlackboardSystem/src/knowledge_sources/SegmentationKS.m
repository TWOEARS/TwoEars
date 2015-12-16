classdef SegmentationKS < AuditoryFrontEndDepKS
    % SEGMENTATIONKS This knowledge source computes soft or binary masks
    %   from a set of auditory features in the time frequency domain. The
    %   number of sound sources that should be segregated must be specified
    %   upon initialization. Each mask is associated with a corresponding
    %   estimate of the source position, given as Gaussian distributions.
    %   The segmentation stage can be initialized with additional prior
    %   information, if estimated of the positions of certain sound sources
    %   are available.
    %
    % AUTHOR:
    %   Christopher Schymura (christopher.schymura@rub.de)
    %   Cognitive Signal Processing Group
    %   Ruhr-Universitaet Bochum
    %   Universitaetsstr. 150, 44801 Bochum

    properties (SetAccess = private)
        name                        % Name of the KS instance
        localizationModels          % Cell-array, containing trained
                                    % localization models for each
                                    % gammatone filterbank channel.
        blockSize                   % The size of one data block that
                                    % should be processed by this KS in
                                    % [s].
        nSources                    % Number of sources that should be
                                    % separated.
        fixedPositions = [];        % A set of positions that should be
                                    % fixed during the segmentation
                                    % process.
        bBackground                 % Should background noise be estimated
                                    % additionally?
        bVerbose = false            % Display processing information?
        dataPath = ...              % Path for storing trained models
            fullfile(xml.dbPath, 'learned_models', 'SegmentationKS');
    end

    methods (Static, Hidden)
        function fileList = getFiles(folder, extension)
            % GETFILES Returns a cell-array, containing a list of files
            %   with a specified extension.
            %
            % REQUIRED INPUTS:
            %    folder - Path pointing to the folder that should be
            %       searched.
            %    extension - String, specifying the file extension that
            %       should be searched.
            %
            % OUTPUTS:
            %    fileList - Cell-array containing all files that were found
            %       in the folder. If no files with the specified extension
            %       were found, an empty cell-array is returned.

            % Check inputs
            p = inputParser();

            p.addRequired('folder', @isdir);
            p.addRequired('extension', @ischar);
            parse(p, folder, extension);

            % Get all files in folder
            fileList = dir(fullfile(p.Results.folder, ...
                ['*.', p.Results.extension]));

            % Return cell-array of filenames
            fileList = {fileList(:).name};
        end

        function [nData, dataMean, whiteningMatrix] = whitenData(data)
            % WHITENDATA This function performs a whitening
            %   transformation on a matrix containing data points.
            %
            % REQUIRED INPUTS:
            %   data - Input data matrix of dimensions N x D, where N is
            %       the number of data samples and D is the data dimension.
            %
            % OUTPUTS:
            %   nData - Normalized data matrix, having zero mean and unit
            %       variance.
            %   dataMean - D x 1 vector, representing the mean of the data
            %              samples.
            %   whiteningMatrix - Transformation matrix for performing the
            %       whitening transform on the given dataset.

            % Check inputs
            p = inputParser();

            p.addRequired('data', @(x) validateattributes(x, ...
                {'numeric'}, {'real', '2d'}));
            p.parse(data);

            % Check if data matrix is skinny
            [nSamples, nDims] = size(data);
            if nDims >= nSamples
                error(['The number of data samples must be ', ...
                    'greater than the data dimension.']);
            end

            % Compute mean and covariance matrix of the input data
            dataMean = mean(p.Results.data);
            dataCov = cov(p.Results.data);

            % Compute whitening matrix
            [V, D] = eig(dataCov);
            whiteningMatrix = ...
                V * diag(1 ./ (diag(D) + eps).^(1/2)) * V';

            % Compute normalized dataset
            nData = ...
                bsxfun(@minus, p.Results.data, dataMean) * whiteningMatrix;
        end

        function hashValue = generateHash(inputString)
            % GENERATEHASH This function can be used to generate a MD5 hash
            %   value for a given string.
            %
            % REQUIRED INPUTS:
            %   inputString - String that should be converted.
            %
            % OUTPUTS:
            %   hashValue - MD5 hash value

            % Check inputs
            p = inputParser();

            p.addRequired('inputString', @ischar);
            p.parse(inputString);

            % Convert string to byte-array
            byteString = java.lang.String(inputString);

            % Generate an instance of the Java "Message Digest" class
            javaMessageDigest = ...
                java.security.MessageDigest.getInstance('MD5');

            % Append byte array to hash processor
            javaMessageDigest.update(byteString.getBytes);

            % Generate hash value and convert back to Matlab string format
            byteHash = javaMessageDigest.digest();
            byteHash = java.math.BigInteger(1, byteHash);
            hashValue = char(byteHash.toString(16));
        end
    end

    methods (Access = public)
        function obj = SegmentationKS(name, varargin)
            % SEGMENTATIONKS This is the class constructor. This KS can
            %   either be initialized in working or training-mode. In
            %   working mode, the KS can be used within a working
            %   blackboard architecture. If set to training mode,
            %   localization models needed for the segmentation stage can
            %   be trained for a given set of HRTFs.
            %
            % REQUIRED INPUTS:
            %   name - Name that describes the properties of the
            %       instantiated KS object.
            %
            % OPTIONAL INPUTS:
            %   blockSize - Size of the processing blocks in [s]
            %       (default = 1).
            %   nSources - Number of sources that should be separated
            %       (default = 2).
            %   doBackgroundEstimation - Flag that indicates if an
            %       additional estimation of the background noise should be
            %       performed. If this function is enabled, an additional
            %       segmentation hypothesis will be generated at each
            %       execution of this KS, which contains a soft mask for
            %       the background (default = true);
            %
            % INPUT PARAMETERS:
            %   ['NumChannels', numChannels] - Name-value pair for setting
            %       the number of gammatone filterbank channels that should
            %       be used by the Auditory Front-End.
            %   ['WindowSize', windowSize] - Name-value pair for setting
            %       the size of the processing window in seconds.
            %   ['HopSize', hopSize] - Name-value pair for setting the hop
            %       size or window shift in seconds that should be used
            %       during processing.
            %   ['FLow', fLow] - Name-value pair for setting the lowest
            %       center frequency of the gammatone filterbank in Hz.
            %   ['FHigh', fHigh] - Name-value pair for setting the highest
            %       center frequency of the gammatone filterbank in Hz.
            %   ['Verbosity', bVerbose] - Flag indicating wheter processing
            %       information should be displayed during runtime.

            % Check inputs
            p = inputParser();
            defaultNumChannels = 32;
            defaultWindowSize = 0.02;
            defaultHopSize = 0.01;
            defaultFLow = 80;
            defaultFHigh = 8000;
            defaultBVerbose = false;
            defaultBlockSize = 1;
            defaultNSources = 2;
            defaultBGEstimation = true;

            p.addRequired('name', @ischar);
            p.addOptional('blockSize', defaultBlockSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addOptional('nSources', defaultNSources, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'integer', 'scalar', 'nonnegative'}));
            p.addOptional('doBackgroundEstimation', ...
                defaultBGEstimation, @(x) islogical(logical(x)));
            p.addParameter('NumChannels', defaultNumChannels, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'integer', 'scalar', 'nonnegative'}));
            p.addParameter('WindowSize', defaultWindowSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('HopSize', defaultHopSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('FLow', defaultFLow, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('FHigh', defaultFHigh, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('Verbosity', defaultBVerbose, @islogical);
            p.parse(name, varargin{:});

            % Set parameters for the gammatone filterbank processor
            fb_type = 'gammatone';
            fb_lowFreqHz = p.Results.FLow;
            fb_highFreqHz = p.Results.FHigh;
            fb_nChannels = p.Results.NumChannels;

            % Set parameters for the cross-correlation processor
            cc_wSizeSec = p.Results.WindowSize;
            cc_hSizeSec = p.Results.HopSize;
            cc_wname = 'hann';

            % Set parameters for the ILD processor
            ild_wSizeSec = p.Results.WindowSize;
            ild_hSizeSec = p.Results.HopSize;
            ild_wname = 'hann';

            % Generate parameter structure
            afeParameters = genParStruct( ...
                'fb_type', fb_type, ...
                'fb_lowFreqHz', fb_lowFreqHz, ...
                'fb_highFreqHz', fb_highFreqHz, ...
                'fb_nChannels', fb_nChannels, ...
                'cc_wSizeSec', cc_wSizeSec, ...
                'cc_hSizeSec', cc_hSizeSec, ...
                'cc_wname', cc_wname, ...
                'ild_wSizeSec', ild_wSizeSec, ...
                'ild_hSizeSec', ild_hSizeSec, ...
                'ild_wname', ild_wname);

            % Set AFE requests
            requests{1}.name = 'crosscorrelation';
            requests{1}.params = afeParameters;
            requests{2}.name = 'ild';
            requests{2}.params = afeParameters;
            obj = obj@AuditoryFrontEndDepKS(requests);

            % Instantiate KS
            obj.name = p.Results.name;
            obj.blockSize = p.Results.blockSize;
            obj.nSources = p.Results.nSources;
            obj.bBackground = p.Results.doBackgroundEstimation;
            obj.bVerbose = p.Results.Verbosity;
            obj.lastExecutionTime_s = 0;

            % Check if trained models are available
            filename = [obj.name, '_models_', ...
                cell2mat(obj.reqHashs), '.mat'];
            if ~exist(fullfile(obj.dataPath, obj.name, filename), 'file')
                warning(['No trained models are available for this ', ...
                    'KS. Please ensure to run KS training first.']);
            else
                % Load available models and add them to object props
                models = load(fullfile(obj.dataPath, obj.name, filename));
                obj.localizationModels = models.locModels;
            end
        end

        function [bExecute, bWait] = canExecute(obj)
            % CANEXECUTE This function specifies which conditions must be
            %   met before this KS can be executed.

            % Execute KS if a sufficient amount of data for one block has
            % been gathered
            bExecute = (obj.blackboard.currentSoundTimeIdx - ...
                obj.lastExecutionTime_s) >= obj.blockSize;
            bWait = false;
        end

        function execute(obj)
            % EXECUTE This mehtods performs joint source segregation and
            %   localization for one block of audio data.

            % Get features of current signal block
            afeData = obj.getAFEdata();
            iacc = afeData(1).getSignalBlock(obj.blockSize, ...
                obj.timeSinceTrigger);
            ilds = afeData(2).getSignalBlock(obj.blockSize, ...
                obj.timeSinceTrigger);

            % Get number of frames and channels
            [nFrames, nChannels] = size(ilds);

            % Initialize location map
            locMap = zeros(nFrames, nChannels);

            % Estimate azimuth angle for each time-frequency bin
            for chanIdx = 1 : nChannels
                % Get feature vector for current T-F-bin
                features = [squeeze(iacc(:, chanIdx, :)), ...
                    ilds(:, chanIdx)];

                % Get whitening parameters for current channels
                featureMean = obj.localizationModels{chanIdx}.featureMean;
                whiteningMatrix = ...
                    obj.localizationModels{chanIdx}.whiteningMatrix;

                % Perform whitening
                features = ...
                    bsxfun(@minus, features, featureMean) * ...
                    whiteningMatrix;

                % Predict azimuth positions
                locMap(:, chanIdx) = libsvmpredict(ones(nFrames, 1), ...
                    features, ...
                    obj.localizationModels{chanIdx}.model, ...
                    sprintf('-q'));
            end

            % Wrap all features to the interval [-pi, pi]
            locMap = mod(locMap + 180, 360) - 180;
            locMap = locMap ./ 180 .* pi;

            % Fit a von Mises mixture model to the data. The number of
            % mixture components can be set to nSources + 1, if background
            % noise should be estimated. It is handled as a separate
            % cluster with concentration parameter equal to zero.
            if obj.bBackground
                mvmModel = fitmvmdist(locMap(:), obj.nSources + 1, ...
                    'FixedMu', ...
                    [pi - min(abs(mean(obj.fixedPositions)), 2 * pi); ...
                    obj.fixedPositions], 'FixedKappa', 0, ...
                    'Replicates', 3, 'MaxIter', 250);
            else
                mvmModel = fitmvmdist(locMap(:), obj.nSources, ...
                    'FixedMu', obj.fixedPositions, 'Replicates', 3, ...
                    'MaxIter', 250);
            end

            % Perform clustering on the estimated model to get soft masks
            % for segmentation
            [~, ~, probMap] = mvmModel.cluster(locMap(:));

            % Generate hypotheses
            if obj.bBackground
                % Generate segmentation hypothesis for background noise
                idString = ['1', num2str(obj.lastExecutionTime_s)];
                bgIdentifier = obj.generateHash(idString);

                % Get soft mask of background noise
                bgSoftMask = reshape(probMap(:, 1), nFrames, nChannels);

                % Add segmentation hypothesis to the blackboard
                segHyp = SegmentationHypothesis(bgIdentifier, ...
                    'Background', bgSoftMask);
                obj.blackboard.addData('segmentationHypotheses', ...
                    segHyp, true, obj.trigger.tmIdx);

                % Set index shift to "1"
                idxShift = 1;
            else
                idxShift = 0;
            end

            % Generate new hypotheses for each "true" sound source
            for sourceIdx = 1 + idxShift : obj.nSources + idxShift
                % Generate source identifier
                idString = [num2str(sourceIdx), ...
                    num2str(obj.lastExecutionTime_s)];
                sourceIdentifier = obj.generateHash(idString);

                % Get soft mask for current source
                softMask = ...
                    reshape(probMap(:, sourceIdx), nFrames, nChannels);

                % Get azimuth estimate for current source
                sourceAzimuth = mvmModel.mu(sourceIdx);

                % Compute circular variance for current position estimate
                circularVariance = 1 - ...
                    besseli(1, mvmModel.kappa(sourceIdx)) / ...
                    besseli(0, mvmModel.kappa(sourceIdx));

                % Add segmentation hypothesis to the blackboard
                segHyp = SegmentationHypothesis(sourceIdentifier, ...
                    'SoundSource', softMask);
                obj.blackboard.addData('segmentationHypotheses', ...
                    segHyp, true, obj.trigger.tmIdx);

                % Add position hypothesis to the blackboard
                aziHyp = SourceAzimuthHypothesis(sourceIdentifier, ...
                    sourceAzimuth, circularVariance);
                obj.blackboard.addData('sourceAzimuthHypotheses', ...
                    aziHyp, true, obj.trigger.tmIdx);
            end

            % Trigger event that KS has been executed
            notify(obj, 'KsFiredEvent', ...
                BlackboardEventData(obj.trigger.tmIdx));
        end

        function generateTrainingData(obj, sceneDescription)
            % GENERATETRAININGDATA This function generates a dataset
            %   containing interaural time- and level-differences for a set
            %   of specified source positions. The source positions used
            %   for training are arranged on a circle around the listeners'
            %   head, ranging from -90° to 90° with 1° angular resolution.
            %   For each source position, binaural signals will be
            %   generated using broadband noise in anechoic conditions. The
            %   generated signals have a fixed length of one second per
            %   source position.
            %
            % REQUIRED INPUTS:
            %   sceneDescription - Scene description file in XML-format,
            %       that will be used by the Binaural Simulator to create
            %       binaural signals.

            % Check inputs
            p = inputParser();

            p.addRequired('sceneDescription', @(x) exist(x, 'file'));
            p.parse(sceneDescription);

            % Check if folder for storing training data exists
            dataFolder = fullfile(obj.dataPath, obj.name, 'data');
            if ~exist(dataFolder, 'dir')
                mkdir(dataFolder)
            end

            % Check if training data has already been generated
            filelist = obj.getFiles(dataFolder, 'mat');
            if ~isempty(filelist)
                warning(['Training data for current KS is already ', ...
                    'available. Please run the ', ...
                    '''removeTrainingData()'' method before generating ', ...
                    'a new training dataset.']);
            else % Run data generation
                % Initialize Binaural Simulator
                sim = simulator.SimulatorConvexRoom(sceneDescription);
                sim.Verbose = false;

                % Initialize source as white noise target
                set(sim, 'Sources', {simulator.source.Point()});
                set(sim.Sources{1}, 'AudioBuffer', ...
                    simulator.buffer.Noise());

                % Set simulation length to 1 second
                set(sim, 'LengthOfSimulation', 1);

                % Set look direction of the head to 0 degrees
                sim.rotateHead(0, 'absolute');

                % Start simulation
                set(sim, 'Init', true);

                % Initialize auditory front-end
                dataObj = dataObject([], sim.SampleRate, ...
                    sim.LengthOfSimulation, 2);
                managerObj = manager(dataObj);
                for idx = 1 : length(obj.requests)
                    managerObj.addProcessor(obj.requests{idx}.name, ...
                        obj.requests{idx}.params);
                end

                % Get center frequencies of gammatone filterbank
                centerFrequencies = dataObj.filterbank{1}.cfHz;

                % Generate vector of azimuth positions
                % TODO: This can be extended to be set by the user in a
                % future version.
                nPositions = 181;
                angles = linspace(-90, 90, nPositions);

                for posIdx = 1 : nPositions
                    if obj.bVerbose
                        disp(['Generating training features (', ...
                            num2str(posIdx), '/', num2str(nPositions), ...
                            ') ...']);
                    end

                    % Get current angle
                    angle = angles(posIdx);

                    % Set source position
                    set(sim.Sources{1}, 'Position', ...
                        [cosd(angle); sind(angle); 0]);

                    % Re-initialize Binaural Simulator and AFE
                    set(sim, 'ReInit', true);
                    dataObj.clearData();
                    managerObj.reset();

                    % Get audio signal
                    earSignals = sim.getSignal(sim.LengthOfSimulation);

                    % Process ear signals
                    managerObj.processSignal(earSignals);

                    % Get binaural features
                    ilds = dataObj.ild{1}.Data(:);
                    iacc = dataObj.crosscorrelation{1}.Data(:);

                    % Assemble filename for current set of features
                    filename = [obj.name, '_', num2str(angle), 'deg.mat'];

                    % Compute target vector from angles
                    nFrames = size(ilds, 1);
                    targets = angle .* ones(nFrames, 1);

                    % Get parameters
                    parameters = obj.requests{1}.params;

                    % Save features and meta-data to file
                    save(fullfile(dataFolder, filename), ...
                        'ilds', 'iacc', 'targets', ...
                        'centerFrequencies', 'parameters', '-v7.3');
                end
            end
        end

        function removeTrainingData(obj)
            % REMOVETRAININGDATA Training data that has already been
            %   generated for a specific instance of this knowledge source
            %   can be removed via this function.

            % Check if folder containing training data exists
            trainingFolder = fullfile(obj.dataPath, obj.name, 'data');
            if ~exist(trainingFolder, 'dir')
                error(['No folder containing training data can be ', ...
                    'found for SegmentaionKS of type ', obj.name, '.']);
            end

            % Get all mat-files from training folder
            filelist = obj.getFiles(trainingFolder, 'mat');
            if isempty(filelist)
                error([trainingFolder, ' does not contain any ', ...
                    'training files.']);
            end

            % Delete all files
            nFiles = length(filelist);

            for fileIdx = 1 : nFiles
                if obj.bVerbose
                    disp(['Deleting temporary training files (', ...
                        num2str(fileIdx), '/', num2str(nFiles), ') ...']);
                end

                % Get current filename
                filename = filelist{fileIdx};

                % Delete file
                delete(fullfile(trainingFolder, filename));
            end
        end

        function obj = train(obj, varargin)
            % TRAIN This function computes SVM regression models for
            %   each frequency band of the gammatone filterbank. The models
            %   take ITDs and ILDs as inputs and predict the most likely
            %   azimuth angle of the source position in the range between
            %   -90° and 90°. To use this function, training data has to be
            %   generated first by calling the 'generateTrainingData'
            %   method of this KS.
            %
            % OPTIONAL INPUTS:
            %   bOverwrite - Flag that indicates if an existing model file
            %       that has already been genereated for the same parameter
            %       set should be overwritten by a retrained model
            %       (default = false).

            % Check inputs
            p = inputParser();
            defaultOverwrite = false;

            p.addOptional('bOverwrite', defaultOverwrite, @islogical);
            p.parse(varargin{:});

            % Check if folder containing training data exists
            trainingFolder = fullfile(obj.dataPath, obj.name, 'data');
            if ~exist(trainingFolder, 'dir')
                error(['No folder containing training data can be ', ...
                    'found for SegmentaionKS of type ', obj.name, '.']);
            end

            % Get all mat-files from training folder
            filelist = obj.getFiles(trainingFolder, 'mat');
            if isempty(filelist)
                error([trainingFolder, ' does not contain any ', ...
                    'training files. Please run the method ', ...
                    '''generateTrainingData()'' first.']);
            end

            % Check if trained models for current parameter settings
            % already exist. Otherwise start training.
            filename = [obj.name, '_models_', cell2mat(obj.reqHashs), ...
                '.mat'];
            if exist(fullfile(obj.dataPath, obj.name, filename), ...
                    'file') && ~p.Results.bOverwrite
                error(['File containing trained models already exists ', ...
                    'for the current parameter settings. Please set ', ...
                    'this function in overwriting-mode to re-train ', ...
                    'the existing models.']);
            else
                % Get number of training files
                nFiles = length(filelist);

                % Initialize cell-arrays for data storage
                trainingFeatures = cell(nFiles, 2);
                trainingTargets = cell(nFiles, 1);

                % Gather data
                for fileIdx = 1 : nFiles
                    % Load current training file
                    data = load(fullfile(trainingFolder, ...
                        filelist{fileIdx}));

                    % Append training data to cell-arrays
                    trainingFeatures{fileIdx, 1} = data.ilds;
                    trainingFeatures{fileIdx, 2} = data.iacc;
                    trainingTargets{fileIdx} = data.targets;
                end

                % "Vectorize" all features
                ilds = cell2mat(trainingFeatures(:, 1));
                iacc = cell2mat(trainingFeatures(:, 2));
                targets = cell2mat(trainingTargets);

                % Get number of gammatone filterbank channels
                [~, nChannels] = size(ilds);

                % Initialize localization models
                locModels = cell(nChannels, 1);

                % Train localization models for each gammatone channel
                for chanIdx = 1 : nChannels
                    if obj.bVerbose
                        disp(['Training regression model for channel (', ...
                            num2str(chanIdx), '/', ...
                            num2str(nChannels), ') ...']);
                    end

                    % Get training features
                    features = [squeeze(iacc(:, chanIdx, :)), ...
                        ilds(:, chanIdx)];

                    % Perform whitening on features
                    [features, featureMean, whiteningMatrix] = ...
                        obj.whitenData(features);

                    % Train SVM regression model
                    trainingParams = sprintf('-s 4 -t 0 -m 512 -h 0 -q');
                    model = libsvmtrain(targets, features, trainingParams);

                    % Append model and parameters to cell-array
                    locModels{chanIdx}.model = model;
                    locModels{chanIdx}.featureMean = featureMean;
                    locModels{chanIdx}.whiteningMatrix = whiteningMatrix;
                    locModels{chanIdx}.centerFrequency = ...
                        data.centerFrequencies(chanIdx);
                end

                % Add localization models to object properties
                obj.localizationModels = locModels;

                % Save features and meta-data to file
                save(fullfile(obj.dataPath, obj.name, filename), ...
                    'locModels', '-v7.3');
            end
        end

        function obj = setBlockSize(obj, blockSize)
            % SETBLOCKSIZE Setter function for the block size.
            %
            % REQUIRED INPUTS:
            %   blockSize - Size of the processing blocks in [s].

            % Check inputs
            p = inputParser();

            p.addRequired('blockSize', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'scalar', 'nonnegative'}));
            p.parse(blockSize);

            % Set property
            obj.blockSize = blockSize;
        end

        function obj = setNumSources(obj, nSources)
            % SETNUMSOURCES Setter function for the number of sources.
            %
            % REQUIRED INPUTS:
            %   nSources - Number of sound sources.

            % Check inputs
            p = inputParser();

            p.addRequired('blockSize', @(x) validateattributes(x, ...
                {'numeric'}, {'integer', 'scalar', 'nonnegative'}));
            p.parse(nSources);

            % Set property
            obj.nSources = nSources;
        end

        function obj = setFixedPositions(obj, fixedPositions)
            % SETFIXEDPOSITIONS Setter function for fixed source positions.
            %
            % REQUIRED INPUTS:
            %   fixedPositions - Vector of fixed positions.

            % Check inputs
            p = inputParser();

            p.addRequired('fixedPositions', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector', '>=', -pi, '<=', pi}));
            p.parse(fixedPositions);

            % Set property
            obj.fixedPositions = fixedPositions;
        end
    end
end
