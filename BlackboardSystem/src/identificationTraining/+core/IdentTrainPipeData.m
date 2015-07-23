classdef IdentTrainPipeData < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        classNames;
        data;
        emptyDataStruct;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = IdentTrainPipeData()
            obj.emptyDataStruct = struct( 'files', core.IdentTrainPipeDataElem.empty );
            obj.data = obj.emptyDataStruct;
            rng( 'shuffle' );
        end
        %% ----------------------------------------------------------------
        
        % easy get interface
        function varargout = subsref( obj, S )
            if strcmp(S(1).type,'.')
                mc = metaclass( obj );
                pr = mc.PropertyList(strcmp({mc.PropertyList.Name},S(1).subs));
                if ~isempty( pr )
                    pgaccess = pr.GetAccess;
                    if strcmpi( pgaccess, 'private' ), error( 'private property' ); end;
                end
                me = mc.MethodList(strcmp({mc.MethodList.Name},S(1).subs));
                if ~isempty( me )
                    maccess = me.Access;
                    if strcmpi( maccess, 'private' ), error( 'private property' ); end;
                end
            end
            if (length(S) == 1) && strcmp(S(1).type,'()')
                classes = S.subs{1,1};
                if isa( classes, 'char' )
                    if classes == ':'
                        cIdx = 1:length( obj.data );
                    else
                        cIdx = obj.getClassIdx( classes );
                    end;
                elseif isa( classes, 'cell' )
                    cIdx = [];
                    for c = classes
                        cIdx(end+1) = obj.getClassIdx( c{1} );
                    end
                end
                if size( S.subs, 2 ) > 1
                    fIdx = S.subs{1,2};
                else
                    fIdx = ':';
                end
                if size( S.subs, 2 ) > 2
                    dIdx = S.subs{1,3};
                    if strcmp( dIdx, 'x' ) && size( S.subs, 2 ) > 3
                        if length(cIdx) > 1 || length(fIdx) > 1
                            error( 'Index for x can only be chosen if specifying a class and a file.' );
                        end
                        xIdx = S.subs{1,4};
                        varargout{1:nargout} = vertcat( obj.data(cIdx).files(fIdx).x(xIdx,:,:,:) );
                    elseif strcmp( dIdx, 'y' ) && size( S.subs, 2 ) > 3
                        if ~isa( S.subs{1,4}, 'char' )
                            error( 'Index for positive class must be string.' );
                        end
                        yIdx = obj.getClassIdx( S.subs{1,4} );
                        if isempty( yIdx )
                            error( 'Index for positive class not valid.' );
                        end
                        out = [];
                        for c = cIdx(1:end)
                            cy = vertcat( obj.data(c).files(fIdx).y );
                            if c ~= yIdx
                                cy = -1 * ones( size( cy ) );
                            end
                            out = [out; cy];
                        end
                        varargout{1:nargout} = out;
                    elseif strcmp( dIdx, 'wavFileName' )
                        out = {};
                        for c = cIdx(1:end)
                            out = [out, { obj.data(c).files(fIdx).(dIdx) }];
                        end
                        varargout{1:nargout} = out';
                    else
                        out = [];
                        for c = cIdx(1:end)
                            out = [out; vertcat( obj.data(c).files(fIdx).(dIdx) )];
                        end
                        varargout{1:nargout} = out;
                    end
                else
                    out = obj.data(cIdx(1)).files(fIdx);
                    for c = cIdx(2:end)
                        out = [out; obj.data(c).files(fIdx)];
                    end
                    varargout{1:nargout} = out;
                end
            else
                if nargout == 0
                    builtin( 'subsref', obj, S );
                else
                    [varargout{1:nargout}] = builtin( 'subsref', obj, S );
                end
            end
        end
        %% ----------------------------------------------------------------
        
        % easy set interface
        function obj = subsasgn( obj, S, val )
            if (length(S) == 1) && strcmp(S(1).type,'()')
                className = S.subs{1,1};
                if isa( className, 'char' )
                    cIdx = obj.getClassIdx( className, 'createIfnExst' );
                else
                    error( 'className needs to be a string' );
                end
                if size( S.subs, 2 ) > 1
                    fIdx = S.subs{1,2};
                else
                    error( 'file index must be set for assignment' );
                end
                if isa( fIdx, 'char' )
                    if strcmp( fIdx, '+' )
                        fIdx = length( obj.data(cIdx).files ) + 1;
                    else
                        error( 'unknown indexing' );
                    end
                end
                if size( S.subs, 2 ) > 2
                    dIdx = S.subs{1,3};
                else
                    dIdx = 'wavFileName';
                end
                if (strcmp( dIdx, 'x' ) || strcmp( dIdx, 'y' )) ...
                        && size( S.subs, 2 ) > 3
                    xIdx = S.subs{1,4};
                    if isa( xIdx, 'char' )
                        dIdxLen = length( obj.data(cIdx).files(fIdx).(dIdx) );
                        switch xIdx
                            case ':'
                                xIdx = 1:dIdxLen;
                            case '+'
                                xIdx = dIdxLen+1:dIdxLen+1+size(val,1);
                            otherwise
                                error( 'unknown indexing' );
                        end
                    end
                    obj.data(cIdx).files(fIdx).(dIdx)(xIdx,:,:,:,:,:,:) = val;
                elseif strcmp( dIdx, 'Elem' )
                    obj.data(cIdx).files(fIdx) = val;
                else
                    obj.data(cIdx).files(fIdx).(dIdx) = val;
                end
            else
                obj = builtin( 'subsasgn', obj, S, val );
            end
        end
        %% ----------------------------------------------------------------

        function l = length( obj )
            l = 0;
            for d = obj.data
                for f = d.files
                    l = l + size( f.x, 1 );
                end
            end
        end
        %% ----------------------------------------------------------------
        %
        %         function s = size( obj )
        %             s = size(obj.cbuf.dat);
        %             s(1) = length( obj );
        %         end
        %
        %         function n = numel( obj )
        %             n = prod( size( obj ) );
        %         end
        %% ----------------------------------------------------------------
        
        function ind = end( obj, k, n )
            switch k
                case 1
                    ind = length( obj.data );
                case 2
                    error( 'dont know how to implement this yet' );
                case 3
                    error( 'dont know how to implement this yet' );
                case 4
                    error( 'dont know how to implement this yet' );
            end
        end
        %% ----------------------------------------------------------------
        
        function ie = isempty( obj )
            for d = obj.data
                if numel( d.files ) > 0, ie = false; return; end
            end
            ie = true;
        end
        
        %% ----------------------------------------------------------------
        
        function permFolds = splitInPermutedStratifiedFolds( obj, nFolds )
            if nFolds == 0
                permFolds = [];
                return;
            end
            for ii = 1 : nFolds
                permFolds{ii} = core.IdentTrainPipeData();
                permFolds{ii}.classNames = obj.classNames ;
            end
            for cIdx = 1 : numel( obj.classNames )
                nClassFiles = numel( obj.data(cIdx).files );
                fIdxPerm = randperm( nClassFiles );
                for ii = 1 : nFolds
                    fIdx = ii : nFolds : nClassFiles;
                    foldFidxPerm = fIdxPerm(fIdx);
                    pf = permFolds{ii};
                    pf.data(cIdx).files(1:length(fIdx)) = obj.data(cIdx).files(foldFidxPerm);
                end
            end
        end
        %% ----------------------------------------------------------------
        
        function [share, disjShare] = getShare( obj, ratio )
            gcdShares = gcd( round( 100 * ratio ), round( 100 * (1 - ratio) ) ) / 100;
            maxFolds = 0;
            for d = obj.data
                maxFolds = max( maxFolds, size( d.files, 2 ) );
            end
            if maxFolds == 0
                share = core.IdentTrainPipeData();
                disjShare = core.IdentTrainPipeData();
                return;
            end
            nFolds = min( round( 1 / gcdShares ), maxFolds );
            folds = obj.splitInPermutedStratifiedFolds( nFolds );
            shareNfolds = round( nFolds * ratio );
            share = core.IdentTrainPipeData.combineData( folds{1:shareNfolds} );
            if shareNfolds < nFolds
                disjShare = core.IdentTrainPipeData.combineData( folds{shareNfolds + 1:end} );
            else
                disjShare = [];
            end
        end
        %% ----------------------------------------------------------------

        function saveDataFList( obj, flistName, baseDir )
            wavFileNames = {};
            for cIdx = 1 : numel( obj.classNames )
                cName = obj.classNames{cIdx};
                for dataFile = obj.data(cIdx).files
                    if nargin < 3
                        [~,fn,fe] = fileparts( dataFile.wavFileName );
                        wavFileNames{end+1} = sprintf( '%s\n', [cName, '/', fn, fe] );
                    else
                        baseDirPos = strfind( dataFile.wavFileName, baseDir );
                        if numel( baseDirPos ) > 1
                            for bdp = baseDirPos
                                if (bdp == 1 || ...
                                        dataFile.wavFileName(bdp-1) == '/' || ...
                                        dataFile.wavFileName(bdp-1) == '\') && ...
                                       (bdp+length(baseDir) == length(dataFile.wavFileName) ||...
                                       dataFile.wavFileName(bdp+length(baseDir)) == '/' || ...
                                       dataFile.wavFileName(bdp+length(baseDir)) == '\')
                                   baseDirPos = bdp;
                                   break;
                                end
                            end
                        end
                        wavFileNames{end+1} = sprintf( '%s\n', dataFile.wavFileName(baseDirPos:end) );
                    end
                end
            end
            flistFid = fopen( flistName, 'w' );
            for kk = 1:length(wavFileNames)
                fprintf( flistFid, '%s', wavFileNames{kk} );
            end
            fclose( flistFid );
        end
        %% ----------------------------------------------------------------
        
        function loadWavFileList( obj, wavflist )
            if isempty( wavflist ), return; end
            obj.data = obj.emptyDataStruct;
            obj.classNames = {};
            if ~isa( wavflist, 'char' )
                error( 'wavflist must be a string.' );
            elseif ~exist( wavflist, 'file' )
                error( 'Wavflist not found.' );
            end
            fid = fopen( wavflist );
            wavs = textscan( fid, '%s' );
            for k = 1:length(wavs{1})
                wavName = wavs{1}{k};
                if ~exist( wavName, 'file' )
                    error ( 'Could not find %s listed in %s.', wavName, wavflist );
                end
                wavName = which( wavName ); % ensure absolute path
                wavClass = IdEvalFrame.readEventClass( wavName );
                obj.subsasgn( struct('type','()','subs',{{wavClass,'+'}}), wavName );
            end
            fclose( fid );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Static)

        function combinedData = combineData( varargin )
            combinedData = core.IdentTrainPipeData();
            for ii = 1 : numel(varargin)
                d = varargin{ii};
                for jj = 1 : numel( d.classNames )
                    cIdx = combinedData.getClassIdx( d.classNames{jj}, 'createIfnExst' );
                    nDfiles = numel( d.data(jj).files );
                    combinedData.data(cIdx).files(end+1:end+nDfiles) = d.data(jj).files;
                end
            end
        end
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
        
        %% function cIdx = getClassIdx( obj, className, mode )
        %       returns the index of the class with name 'className'
        %       if mode is 'createIfnExst', the class will be created in
        %       the data structure if it does not exist yet.
        function cIdx = getClassIdx( obj, className, mode )
            [classAlreadyPresent,cIdx] = max( strcmp( obj.classNames, className ) );
            if isempty( classAlreadyPresent ) || ~classAlreadyPresent
                if nargin < 3, mode = ''; end;
                if strcmpi( mode, 'createIfnExst' )
                    obj.classNames{end+1} = className;
                    cIdx = length( obj.classNames );
                    obj.data(cIdx) = obj.emptyDataStruct;
                else
                    cIdx = [];
                end
            end
        end
        %% ----------------------------------------------------------------
        
    end
end