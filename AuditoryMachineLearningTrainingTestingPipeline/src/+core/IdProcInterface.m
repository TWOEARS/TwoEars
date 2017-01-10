classdef (Abstract) IdProcInterface < handle
    %% data file processor
    %
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        procName;
        externOutputDeps;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected, Transient = true)
        preloadedConfigs = [];
        preloadedConfigsChanged = false;
        pcRWsema = [];
        pcFilename = [];
        pcWriteFilename = [];
        pcFileInfo = [];
        preloadedPath = [];
        configChanged = true;
        currentFolder = [];
        lastClassPath = [];
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function delete(obj)
            obj.savePreloadedConfigs();
        end
        %% -----------------------------------------------------------------

        function savePreloadedConfigs( obj )
            if isempty( obj.preloadedConfigs ), return; end
            if ~obj.preloadedConfigsChanged, return; end
            preloadedConfigs = obj.preloadedConfigs;
            sema = setfilesemaphore( obj.pcWriteFilename );
            new_pcFileInfo = dir( obj.pcFilename );
            if ~isempty( new_pcFileInfo ) && ...
                    ~isequalDeepCompare( new_pcFileInfo, obj.pcFileInfo )
                obj.pcRWsema.getReadAccess();
                Parameters.dynPropsOnLoad( true, false );
                new_pc = load( obj.pcFilename, 'preloadedConfigs' );
                Parameters.dynPropsOnLoad( true, true );
                obj.pcRWsema.releaseReadAccess();
                new_pcKeys = new_pc.preloadedConfigs.keys;
                my_pcKeys = preloadedConfigs.keys;
                for jj = length( new_pcKeys ) : -1 : 1
                    k = new_pcKeys{jj};
                    if ~any( strcmp( k, my_pcKeys ) )
                        preloadedConfigs(k) = new_pc.preloadedConfigs(k);
                    end
                end
            end
            save( obj.pcWriteFilename, 'preloadedConfigs' );
            obj.pcRWsema.getWriteAccess();
            copyfile( obj.pcWriteFilename, obj.pcFilename ); % this blocks pcFilename much shorter
            obj.pcRWsema.releaseWriteAccess();
            delete( obj.pcWriteFilename );
            removefilesemaphore( sema );
            obj.preloadedConfigsChanged = false;
        end
        %% -----------------------------------------------------------------
        
        function init( obj )
            obj.savePreloadedConfigs();
            obj.preloadedConfigs = [];
            obj.preloadedConfigsChanged = false;
            obj.preloadedPath = [];
            obj.configChanged = true;
            obj.currentFolder = [];
            obj.lastClassPath = [];
        end
        %% -----------------------------------------------------------------
        
        function savePlaceholderFile( obj, inFilePath )
            obj.save( inFilePath, struct('dummy',[]) );
        end
        %% -----------------------------------------------------------------
        
        function out = saveOutput( obj, inFilePath )
            out = obj.getOutput();
            obj.save( inFilePath, out );
        end
        %% -----------------------------------------------------------------
        
        function out = processSaveAndGetOutput( obj, inFileName )
            if ~obj.hasFileAlreadyBeenProcessed( inFileName )
                obj.process( inFileName );
                out = obj.saveOutput( inFileName );
            else
                out = load( obj.getOutputFileName( inFileName ) );
            end
        end
        %% -----------------------------------------------------------------
        
        function outFileName = getOutputFileName( obj, inFilePath, currentFolder )
            if nargin < 3
                currentFolder = obj.getCurrentFolder( inFilePath );
            end
            if isempty( currentFolder )
                currentFolder = obj.createCurrentConfigFolder( inFilePath );
            end
            [~, fileName, fileExt] = fileparts( inFilePath );
            fileName = [fileName fileExt];
            outFileName = fullfile( currentFolder, [fileName obj.getProcFileExt] );
        end
        %% -----------------------------------------------------------------
        
        function [fileProcessed,precProcFileNeeded] = hasFileAlreadyBeenProcessed( obj, filePath, createFolder, checkPrecNeed )
            if isempty( filePath ), fileProcessed = false; return; end
            currentFolder = obj.getCurrentFolder( filePath );
            fileProcessed = ...
                ~isempty( currentFolder )  && ...
                exist( obj.getOutputFileName( filePath, currentFolder ), 'file' );
            if nargin > 2  &&  createFolder  &&  isempty( currentFolder )
                currentFolder = obj.createCurrentConfigFolder( filePath );
            end
            if ~fileProcessed && nargin > 3 && checkPrecNeed
                precProcFileNeeded = obj.needsPrecedingProcResult( filePath );
            else
                precProcFileNeeded = false;
            end
        end
        %% -----------------------------------------------------------------

        function setExternOutputDependencies( obj, externOutputDeps )
            obj.configChanged = true;
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
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
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
        %% -----------------------------------------------------------------
        
        function precProcFileNeeded = needsPrecedingProcResult( obj, wavFileName )
            precProcFileNeeded = true; % this method is overwritten in Multi... subclasses
        end
        %% -----------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
        function out = save( obj, inFilePath, data )
%            inFilePath = which( inFilePath ); % ensure absolute path
            out = data;
            if isempty( inFilePath ), return; end
            currentFolder = obj.getCurrentFolder( inFilePath );
            if isempty( currentFolder )
                currentFolder = obj.createCurrentConfigFolder( inFilePath );
            end
            outFilename = obj.getOutputFileName( inFilePath, currentFolder );
            save( outFilename, '-struct', 'out' );
        end
        %% -----------------------------------------------------------------

        function saveOutputConfig( obj, configFileName )
            outputDeps = obj.getOutputDependencies();
            save( configFileName, '-struct', 'outputDeps' );
        end
        %% -----------------------------------------------------------------
        
        function currentFolder = getCurrentFolder( obj, filePath )
            classFolder = fileparts( filePath );
            if ~isempty( obj.currentFolder ) && ...
                    ~obj.configChanged && strcmp( classFolder, obj.lastClassPath )
                currentFolder = obj.currentFolder;
                return;
            end
            currentConfig = obj.getOutputDependencies();
            dbFolder = fileparts( classFolder );
            procFoldersDir = dir( [classFolder filesep obj.procName '.2*'] );
            procFolders = {procFoldersDir.name};
            procFolders = cellfun( @(pfdn)(pfdn(length(obj.procName)+2:end)), ...
                procFolders, 'UniformOutput', false );
            currentFolder = [];
            if isempty( obj.preloadedPath )
                obj.preloadedPath = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            end
            if isempty( procFolders ), return; end
            allProcFolders = strcat( procFolders{:} );
            if obj.preloadedPath.isKey( allProcFolders )
                preloaded = obj.preloadedPath(allProcFolders);
                if isequalDeepCompare( preloaded{2}, currentConfig )
                    currentFolder = preloaded{1};
                    obj.configChanged = false;
                    obj.lastClassPath = classFolder;
                    obj.currentFolder = currentFolder;
                    return;
                end
            end
            obj.loadPreloadedConfigs( dbFolder );
            for ii = length( procFolders ) : -1 : 1
                if obj.preloadedConfigs.isKey( procFolders{ii} )
                    cfg = obj.preloadedConfigs(procFolders{ii});
                    if isequalDeepCompare( currentConfig, cfg )
                        currentFolder = [classFolder filesep ...
                            obj.procName '.' procFolders{ii}];
                        procFolders = {};
                        break;
                    end
                    procFolders(ii) = [];
                end
            end
            for ii = length( procFolders ) : -1 : 1
                cfg = load( fullfile( ...
                    classFolder, [obj.procName '.' procFolders{ii}], 'config.mat' ) );
                if isequalDeepCompare( currentConfig, cfg )
                    currentFolder = [classFolder filesep obj.procName '.' procFolders{ii}];
                    obj.preloadedConfigs(procFolders{ii}) = cfg;
                    obj.preloadedConfigsChanged = true;
                    break;
                end
            end
            if ~isempty( currentFolder )
                obj.preloadedPath(allProcFolders) = {currentFolder, currentConfig};
            end
            obj.configChanged = false;
            obj.lastClassPath = classFolder;
            obj.currentFolder = currentFolder;
        end
        %% -----------------------------------------------------------------
        
        function currentFolder = createCurrentConfigFolder( obj, filePath )
            classFolder = fileparts( filePath );
            timestr = buildCurrentTimeString( true );
            currentFolder = [classFolder filesep obj.procName timestr];
            mkdir( currentFolder );
            obj.saveOutputConfig( fullfile( currentFolder, 'config.mat' ) );
            cfg = load( fullfile( currentFolder, 'config.mat' ) );
            dbFolder = fileparts( classFolder );
            obj.loadPreloadedConfigs( dbFolder );
            obj.preloadedConfigs(timestr(2:end)) = cfg;
            obj.preloadedConfigsChanged = true;
            obj.configChanged = false;
            obj.lastClassPath = classFolder;
            obj.currentFolder = currentFolder;
        end
        %% -----------------------------------------------------------------
        
        function loadPreloadedConfigs( obj, dbFolder )
            if isempty( obj.preloadedConfigs )
                obj.pcFilename = [dbFolder filesep obj.procName '.preloadedConfigs.mat'];
                obj.pcWriteFilename = [dbFolder filesep obj.procName '.preloadedConfigs.write.mat'];
                obj.pcRWsema = ReadersWritersFileSemaphore( obj.pcFilename );
                if exist( obj.pcFilename, 'file' )
                    obj.pcRWsema.getReadAccess();
                    Parameters.dynPropsOnLoad( true, false );
                    obj.pcFileInfo = dir( obj.pcFilename );
                    pc = load( obj.pcFilename );
                    Parameters.dynPropsOnLoad( true, true );
                    obj.pcRWsema.releaseReadAccess();
                    obj.preloadedConfigs = pc.preloadedConfigs;
                    obj.preloadedConfigsChanged = false;
                else
                    obj.preloadedConfigs = ...
                        containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
                end
            end
        end
        %% -----------------------------------------------------------------
        
        function procFileExt = getProcFileExt( obj )
            procFileExt = ['.' obj.procName '.mat'];
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        process( obj, inputFileName )
    end
    methods (Abstract, Access = protected)
        outputDeps = getInternOutputDependencies( obj )
        out = getOutput( obj )
    end
    
end

        