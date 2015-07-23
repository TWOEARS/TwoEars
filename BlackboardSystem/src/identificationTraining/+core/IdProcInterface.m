classdef (Abstract) IdProcInterface < handle
    %% data file processor
    %
    
    %%---------------------------------------------------------------------
    properties (SetAccess = protected)
        procName;
        externOutputDeps;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function out = saveOutput( obj, inFilePath )
            inFilePath = which( inFilePath ); % ensure absolute path
            out = obj.getOutput();
            currentFolder = obj.getCurrentFolder( inFilePath );
            if isempty( currentFolder )
                currentFolder = obj.createCurrentConfigFolder( inFilePath );
            end
            outFilename = obj.getOutputFileName( inFilePath, currentFolder );
            save( outFilename, '-struct', 'out' );
        end
        %%-----------------------------------------------------------------
        
        function out = processSaveAndGetOutput( obj, inFileName )
            if ~obj.hasFileAlreadyBeenProcessed( inFileName )
                obj.process( inFileName );
                out = obj.saveOutput( inFileName );
            else
                out = load( obj.getOutputFileName( inFileName ) );
            end
        end
        %%-----------------------------------------------------------------
        
        function outFileName = getOutputFileName( obj, inFilePath, currentFolder )
            inFilePath = which( inFilePath ); % ensure absolute path
            if nargin < 3
                currentFolder = obj.getCurrentFolder( inFilePath );
            end
            [~, fileName, fileExt] = fileparts( inFilePath );
            fileName = [fileName fileExt];
            outFileName = fullfile( currentFolder, [fileName obj.getProcFileExt] );
        end
        %%-----------------------------------------------------------------
        
        function fileProcessed = hasFileAlreadyBeenProcessed( obj, filePath )
            filePath = which( filePath ); % ensure absolute path
            currentFolder = obj.getCurrentFolder( filePath );
            fileProcessed = ...
                ~isempty( currentFolder )  && ...
                exist( obj.getOutputFileName( filePath, currentFolder ), 'file' );
        end
        %%-----------------------------------------------------------------
        
        function setExternOutputDependencies( obj, externOutputDeps )
            obj.externOutputDeps = externOutputDeps;
        end
        %%-----------------------------------------------------------------
        
        function outputDeps = getOutputDependencies( obj )
            outputDeps = obj.getInternOutputDependencies();
            if ~isa( outputDeps, 'struct' )
                error( 'getInternOutputDependencies must combine values in a struct.' );
            end
            if isfield( outputDeps, 'extern' )
                error( 'Intern output dependencies must not contain field of name "extern".' );
            end
            if ~isempty( obj.externOutputDeps )
                outputDeps.extern = obj.externOutputDeps;
            end
        end
        %%-----------------------------------------------------------------
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = protected)
        
        function obj = IdProcInterface( procName )
            if nargin < 1,
                classInfo = metaclass( obj );
                [classname1, classname2] = strtok( classInfo.Name, '.' );
                if isempty( classname2 ), obj.procName = classname1;
                else obj.procName = classname2(2:end); end
            else
                obj.procName = procName;
            end
            obj.externOutputDeps = [];
        end
        %%-----------------------------------------------------------------
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
        
        function saveOutputConfig( obj, configFileName )
            outputDeps = obj.getOutputDependencies();
            outputDeps.configHash = calcDataHash( outputDeps );
            save( configFileName, '-struct', 'outputDeps' );
        end
        %%-----------------------------------------------------------------
        
        function currentFolder = getCurrentFolder( obj, filePath )
            [procFolders, configs] = obj.getProcFolders( filePath );
            currentConfig = obj.getOutputDependencies();
            currentFolder = [];
            persistent preloadedPath;
            if isempty( preloadedPath )
                preloadedPath = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            end
            if ~isempty( procFolders )
                allProcFolders = strcat( procFolders{:} );
                if preloadedPath.isKey( allProcFolders )
                    preloaded = preloadedPath(allProcFolders);
                    if obj.areConfigsEqual( preloaded{2}, currentConfig )
                        currentFolder = preloaded{1};
                        return;
                    end
                end
                currentConfig.configHash = calcDataHash( currentConfig );
                for ii = 1 : length( configs )
                    if obj.areConfigsEqual( currentConfig, configs{ii} )
                        currentFolder = procFolders{ii};
                        break;
                    end
                end
                preloadedPath(allProcFolders) = {currentFolder, currentConfig};
            end
        end
        %%-----------------------------------------------------------------
        
        function [procFolders, configs] = getProcFolders( obj, filePath )
            fileBaseFolder = fileparts( filePath );
            procFoldersDir = dir( [fileBaseFolder filesep obj.procName '.*'] );
            procFolders = strcat( [fileBaseFolder filesep], {procFoldersDir.name} );
            configs = {};
            persistent preloadedConfigs;
            if isempty( preloadedConfigs )
                preloadedConfigs = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            end
            if ~isempty( procFolders )
                allProcFolders = strcat( procFolders{:} );
                if preloadedConfigs.isKey( allProcFolders )
                    configs = preloadedConfigs(allProcFolders);
                else
                    for ii = 1 : length( procFolders )
                        configs{ii} = obj.readConfig( procFolders{ii} );
                    end
                    preloadedConfigs(allProcFolders) = configs;
                end
            end
        end
        %%-----------------------------------------------------------------
        
        function currentFolder = createCurrentConfigFolder( obj, filePath )
            fileBaseFolder = fileparts( filePath );
            timestr = buildCurrentTimeString();
            currentFolder = [fileBaseFolder filesep obj.procName timestr];
            mkdir( currentFolder );
            obj.saveOutputConfig( fullfile( currentFolder, 'config.mat' ) );
        end
        %%-----------------------------------------------------------------
        
        function config = readConfig( obj, procFolder )
            persistent preloadedConfigs;
            if isempty( preloadedConfigs )
                preloadedConfigs = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            end
            if preloadedConfigs.isKey( procFolder )
                config = preloadedConfigs(procFolder);
            else
                config = load( fullfile( procFolder, 'config.mat' ) );
                preloadedConfigs(procFolder) = config;
            end
        end
        %%-----------------------------------------------------------------
        
        function procFileExt = getProcFileExt( obj )
            procFileExt = ['.' obj.procName '.mat'];
        end
        %%-----------------------------------------------------------------
        
        function eq = areConfigsEqual( obj, config1, config2 )
            if isfield( config1, 'configHash' ) % compatibility to older versions
                if isfield( config2, 'configHash' )
                    eq = strcmp( config1.configHash, config2.configHash );
                else
                    config1 = rmfield( config1, 'configHash' );
                    eq = isequalDeepCompare( config1, config2 );
                end
            else
                config2 = rmfield( config2, 'configHash' );
                eq = isequalDeepCompare( config1, config2 );
            end
        end
        %%-----------------------------------------------------------------
        
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        process( obj, inputFileName )
    end
    methods (Abstract, Access = protected)
        outputDeps = getInternOutputDependencies( obj )
        out = getOutput( obj )
    end
    
end

