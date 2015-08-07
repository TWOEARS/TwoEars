classdef gmtkEngine < handle
    %gmtkEngine A Matlab interface for GMTK (graphical model toolkit)
    %   Detailed explanation goes here

    properties (GetAccess = public, SetAccess = private)
        workPath = [];          % GMTK working path
        tempPath                % GMTK temporary files path
        cygwinPath              % Path to CYGWIN binaries (Windows only)
        gmName                  % Name of current GM
        gmStruct                % GM structure file
        gmStructTrainable       % GM structure file for training
        inputMaster             % Input master file
        inputMasterTrainable    % Trainable input master file
        learnedParams           % Learned parameter file
        outputCliqueFile        % Clique posterior output file
        dimFeatures             % dimension of feature observations
        bTrain = false;         % Start in training mode
    end

    properties (Access = public)
        gmtkPath                % Path that contains GMTK binaries
        gmtkTri
        gmtkTrain
        gmtkJT
    end

    methods (Access = public)
        function obj = gmtkEngine(gmName, dimFeatures, workPath, bTrain, gmtkPath, cygwinPath)
            % gmtkEngine Class constructor

            % Checking of input parameters
            if nargin > 2
                obj.workPath = fullfile(workPath, gmName);
            else
                obj.workPath = gmName;
            end
            if nargin > 3
                obj.bTrain = bTrain;
            end
            switch(computer)
                case {'GLNXA64', 'MACI64'}              % --- Linux, Mac
                    if nargin < 5
                        gmtkPath = '/usr/local/bin';
                    end
                    % gmtk binaries
                    obj.gmtkTri = fullfile(gmtkPath, 'gmtkTriangulate');
                    obj.gmtkTrain = fullfile(gmtkPath, 'gmtkEMtrain');
                    obj.gmtkJT = fullfile(gmtkPath, 'gmtkJT');

                case 'PCWIN64'                           % --- Windows
                    % Specify path to Cygwin environment
                    if nargin < 6
                        cygwinPath = 'c:\cygwin64\bin\';
                    end
                    obj.cygwinPath = cygwinPath;
                    if nargin < 5
                        gmtkPath = 'c:\cygwin64\usr\local\bin\';
                    end
                    % gmtk binaries
                    obj.gmtkTri = fullfile(gmtkPath, 'gmtkTriangulate.exe');
                    obj.gmtkTrain = fullfile(gmtkPath, 'gmtkEMtrain.exe');
                    obj.gmtkJT = fullfile(gmtkPath, 'gmtkJT.exe');

                otherwise
                    error('Current OS is not supportet.');
            end

            % Check if gmtk binaries can be found
            if ~exist(obj.gmtkTri, 'file')
                error(['Your gmtkTriangulate binary couldn''t be found under its ', ...
                       'specified path: %s.'], obj.gmtkTri);
            end
            if ~exist(obj.gmtkTrain, 'file')
                error(['Your gmtkEMtrain binary couldn''t be found under its ', ...
                    'specified path: %s.'], obj.gmtkTrain);
            end
            if ~exist(obj.gmtkJT, 'file')
                error(['Your gmtkJT binary couldn''t be found under its ', ...
                    'specified path: %s.'], obj.gmtkJT);
            end
            obj.gmName = gmName;
            obj.dimFeatures = dimFeatures;
            obj.gmtkPath = gmtkPath;


            % Temporary path
            obj.tempPath = strcat(tempname, '_gmtk');
            if ~exist(obj.tempPath, 'dir')
                mkdir(obj.tempPath);
            end

            % Files for gmtk model. If in training modus we would like to create the
            % files, otherwise we look them up in the data base.
            if obj.bTrain                                          % --- Training
                % Create a new folder to store training results
                if ~exist(obj.workPath, 'dir')
                    [success, message] = mkdir(obj.workPath);
                    if ~success
                        error(message);
                    end
                end
                obj.gmStruct = ...
                    fullfile(obj.workPath, [gmName '.str']);
                obj.inputMaster = ...
                    fullfile(obj.workPath, [gmName '.master']);
                obj.learnedParams = ...
                    fullfile(obj.workPath, [gmName '_learned_params.gmp']);
                obj.gmStructTrainable = ...
                    fullfile(obj.workPath, [gmName '_train.str']);
                obj.inputMasterTrainable = ...
                    fullfile(obj.workPath, [gmName '_train.master']);

            else                                                   % --- Localisation
                % Get learned model files
                obj.gmStruct = ...
                    xml.dbGetFile(fullfile(obj.workPath, [gmName '.str']));
                obj.inputMaster = ...
                    xml.dbGetFile(fullfile(obj.workPath, [gmName '.master']));
                obj.learnedParams = ...
                    xml.dbGetFile(fullfile(obj.workPath, [gmName, '_learned_params.gmp']));
                % The following file is needed by GMTK, but not used by Matlab. The next line
                % ensures that it will be downloaded if not present locally.
                xml.dbGetFile(fullfile(obj.workPath, [gmName '.str.trifile']));
            end
            % Set temporary files
            obj.outputCliqueFile = fullfile(obj.tempPath, strcat(gmName, '.post'));
        end
        function setGMTKPath(obj, gmtkPath)
            obj.gmtkPath = gmtkPath;
        end
        function setDimFeatures(obj, dimFeatures)
            obj.dimFeatures = dimFeatures;
        end
        function triangulate(obj, triArgs)
            % Triangulate GM structures. Needed every time the structure is
            % changed

            if nargin < 2
                triArgs = '-reSect -M 1 -S 1 -tri R -seed T';
            end

            % Write OS specific inference commands
            switch(computer)
                case {'GLNXA64', 'MACI64'}
                    if ~exist(obj.gmStruct, 'file')
                        error('GM structure file does not exist: %s', obj.gmStruct);
                    end
                    cmdfn = fullfile(obj.workPath, 'tricommand');
                    fid = fopen(cmdfn, 'w');
                    if fid < 0
                        error('Cannot open %s', cmdfn);
                    end
                    fprintf(fid, '#!/bin/sh\n\n');
                    fprintf(fid, '%s -str %s %s', obj.gmtkTri, obj.gmStruct, triArgs);
                    fprintf(fid, '\n');
                    fclose(fid);
                    unix(['chmod a+x ' cmdfn]);
                    s = unix(cmdfn);
                    if s ~= 0
                        error('Failed to triangulate GM %s', obj.gmStruct);
                    end
                    % Also triangulate training structure if exists
                    if exist(obj.gmStructTrainable, 'file')
                        fid = fopen(cmdfn, 'w');
                        if fid < 0
                            error('Cannot open %s', cmdfn);
                        end
                        fprintf(fid, '#!/bin/sh\n\n');
                        fprintf(fid, '%s -str %s %s', obj.gmtkTri, obj.gmStructTrainable, triArgs);
                        fprintf(fid, '\n');
                        fclose(fid);
                        s = unix(cmdfn);
                        if s ~= 0
                            error('Failed to triangulate GM %s', obj.gmStructTrainable);
                        end
                    end
                case 'PCWIN64'
                    if ~exist(obj.gmStruct, 'file')
                        error('GM structure file does not exist: %s', obj.gmStruct);
                    end
                    cmdfn = [obj.cygwinPath, 'bash -c -l "', ...
                        makeUnixPath(obj.gmtkTri), ' -str ', ...
                        makeUnixPath(fullfile(pwd, obj.gmStruct)), ' ', ...
                        triArgs, '"'];

                    s = system(cmdfn);
                    if s ~= 0
                        error('Failed to triangulate GM %s', obj.gmStruct);
                    end

                    % Also triangulate training structure if exists
                    if exist(obj.gmStructTrainable, 'file')
                        cmdfn = [obj.cygwinPath, 'bash -c -l "', ...
                            makeUnixPath(obj.gmtkTri), ' -str ', ...
                            makeUnixPath(fullfile(pwd, obj.gmStructTrainable)), ' ', ...
                            triArgs, '"'];

                        s = system(cmdfn);
                        if s ~= 0
                            error('Failed to triangulate GM %s', obj.gmStructTrainable);
                        end
                    end
                otherwise
                    error('Current OS is not supported.');
            end
        end
        function train(obj, trainFeatureList, trainLabelList)

            % Write OS specific inference commands
            switch(computer)
                case {'GLNXA64', 'MACI64'}
                    % Write traincommand
                    cmdfn = fullfile(obj.workPath, 'traincommand');
                    fid = fopen(cmdfn, 'w');
                    if fid < 0
                        error('Cannot open %s', cmdfn);
                    end
                    fprintf(fid, '#!/bin/sh\n\n');
                    fprintf(fid, '%s -iswp1 -of1 %s -nf1 %d -fmt1 htk \\\n', obj.gmtkTrain, trainFeatureList, obj.dimFeatures);
                    fprintf(fid, '        -of2 %s -ni2 1 -fmt2 ascii \\\n', trainLabelList);
                    fprintf(fid, '        -strFile %s \\\n', obj.gmStructTrainable);
                    fprintf(fid, '        -inputMasterFile %s \\\n', obj.inputMasterTrainable);
                    fprintf(fid, '        -outputTrainableParameters %s \\\n', obj.learnedParams);
                    %fprintf(fid, '        -varFloor 1e-5 \\\n');
                    fprintf(fid, '        -maxE 5 \n');
                    fprintf(fid, '\n');
                    fclose(fid);
                    unix(['chmod a+x ' cmdfn]);
                    s = unix(cmdfn);
                    if s ~= 0
                        error('Failed to train GM %s', obj.gmStructTrainable);
                    end
                case 'PCWIN64'
                    % Write command function
                    cmdfn = [obj.cygwinPath, 'bash -c -l "', ...
                        makeUnixPath(obj.gmtkTrain), ' -iswp1 -fmt1 htk', ...
                        ' -of1 ', makeUnixPath(fullfile(pwd, trainFeatureList)), ...
                        ' -nf1 ', num2str(obj.dimFeatures), ...
                        ' -ni2 1 -fmt2 ascii -of2 ', makeUnixPath(fullfile(pwd, trainLabelList)), ...
                        ' -strFile ', makeUnixPath(fullfile(pwd, obj.gmStructTrainable)), ...
                        ' -inputMasterFile ', makeUnixPath(fullfile(pwd, obj.inputMasterTrainable)), ...
                        ' -outputTrainableParameters ', makeUnixPath(fullfile(pwd, obj.learnedParams)), ...
                        ' -maxE 5 -random F"'];
                    s = system(cmdfn);
                    if s ~= 0
                        error('Failed to train GM %s', obj.gmStructTrainable);
                    end
                otherwise
                    error('Current OS is not supported.');
            end

        end
        function infer(obj, featureList, cliqueNo)
            if nargin < 3
                cliqueNo = 0; % Posteriors of which clique to be output
            end

            % Write OS specific inference commands
            switch(computer)
                case {'GLNXA64', 'MACI64'}
                    % Write jtcommand
                    cmdfn = fullfile(obj.tempPath, 'jtcommand');
                    fid = fopen(cmdfn, 'w');
                    if fid < 0
                        error('Cannot open %s', cmdfn);
                    end
                    fprintf(fid, '#!/bin/sh\n\n');
                    fprintf(fid, '%s -iswp1 -of1 %s -nf1 %d -fmt1 htk \\\n', obj.gmtkJT, featureList, obj.dimFeatures);
                    fprintf(fid, '        -strFile %s \\\n', obj.gmStruct);
                    fprintf(fid, '        -inputMasterFile %s \\\n', obj.inputMaster);
                    fprintf(fid, '        -inputTrainableParameters %s \\\n', obj.learnedParams);
                    fprintf(fid, '        -pCliquePrintRange %d \\\n', cliqueNo);
                    fprintf(fid, '        -cCliquePrintRange %d \\\n', cliqueNo);
                    fprintf(fid, '        -eCliquePrintRange %d \\\n', cliqueNo);
                    fprintf(fid, '        -cliqueOutputFileName %s \\\n', obj.outputCliqueFile);
                    fprintf(fid, '        -cliqueListFileName %s \\\n', obj.outputCliqueFile);
                    fprintf(fid, '        -verbosity 0 \\\n');
                    fprintf(fid, '        -cliquePrintFormat ascii > /dev/null\n');
                    fprintf(fid, '\n');
                    fclose(fid);
                    unix(['chmod a+x ' cmdfn]);
                    s = unix(cmdfn);
                    if s ~= 0
                        error('Failed to infer GM %s', obj.gmStruct);
                    end
                case 'PCWIN64'
                    % Write command function
                    cmdfn = [obj.cygwinPath, 'bash -c -l "', ...
                        makeUnixPath(obj.gmtkJT), ' -iswp1 -fmt1 htk', ...
                        ' -of1 ', makeUnixPath(featureList), ...
                        ' -nf1 ', num2str(obj.dimFeatures), ...
                        ' -strFile ', makeUnixPath(obj.gmStruct), ...
                        ' -inputMasterFile ', makeUnixPath(obj.inputMaster), ...
                        ' -inputTrainableParameters ', makeUnixPath(obj.learnedParams), ...
                        ' -pCliquePrintRange ', num2str(cliqueNo), ...
                        ' -cCliquePrintRange ', num2str(cliqueNo), ...
                        ' -eCliquePrintRange ', num2str(cliqueNo), ...
                        ' -cliqueOutputFileName ', makeUnixPath(obj.outputCliqueFile), ...
                        ' -cliqueListFileName ', makeUnixPath(obj.outputCliqueFile), ...
                        ' -verbosity 0', ...
                        ' -cliquePrintFormat ascii > /dev/null"'];
                    s = system(cmdfn);
                    if s ~= 0
                        error('Failed to infer GM %s', obj.gmStruct);
                    end
                otherwise
                    error('Current OS is not supported.');
            end
        end
    end

end

% vim: set sw=4 ts=4 et tw=90:
