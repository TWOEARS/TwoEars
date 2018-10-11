classdef IdentTrainPipeData < handle
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        data;
        stratificationLabels;
        autoStratify;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdentTrainPipeData( varargin )
            obj.data = Core.IdentTrainPipeDataElem.empty;
            rng( 'shuffle' );
            ip = inputParser;
            ip.addOptional( 'autoStratify', true );
            ip.addOptional( 'stratificationLabels', {} );
            ip.parse( varargin{:} );
            obj.stratificationLabels = ip.Results.stratificationLabels;
            obj.autoStratify = ip.Results.autoStratify;
        end
        %% -------------------------------------------------------------------------------
        
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
                fileSubScript = S.subs{1,1};
                dataElemFieldIdxPos = 2;
                if isa( fileSubScript, 'char' )
                    if all( fileSubScript == ':' )
                        fIdx = 1 : length( obj.data );
                    elseif strcmpi( fileSubScript, 'fileLabel' )
                        dataElemFieldIdxPos = 3;
                        labels = S.subs{1,2};
                        if iscell( labels ) && cellfun( @iscell, labels )
                            fmask = ones( size( obj.data ) );
                            for ii = 1 : numel( labels )
                                label = labels{ii}{1};
                                labelValues = labels{ii}{2};
                                if ~iscell( labelValues )
                                    error( 'put labelValues in cell' );
                                end
                                fmasktmp = zeros( size( obj.data ) );
                                for jj = 1 : numel( labelValues )
                                    fmasktmp = fmasktmp | ...
                                            obj.getFilesLabeled( label, labelValues{jj} );
                                end
                                fmask = fmask & fmasktmp;
                            end
                            fIdx = find( fmask );
                        else
                            error( 'unknown referencing' );
                        end
                    else
                        fIdx = obj.getFileIdx( {fileSubScript} );
                    end;
                elseif iscell( fileSubScript )
                    fIdx = obj.getFileIdx( fileSubScript );
                else % direct indexes
                    fIdx = fileSubScript;
                end
                % referencing fields of DataElems
                if size( S.subs, 2 ) >= dataElemFieldIdxPos 
                    dSubScript = S.subs{1,dataElemFieldIdxPos};
                    if size( S.subs, 2 ) > dataElemFieldIdxPos
                        if length( fIdx ) > 1 || isempty( fIdx )
                            error( 'Index for xy can only be chosen if specifying ONE file.' );
                        end
                        xyIdx = S.subs{1,dataElemFieldIdxPos+1};
                        if ndims( obj.data(fIdx(1)).(dSubScript) )  > 5
                            error( 'D > 5 not supported' );
                        end
                        varargout{1:nargout} = ...
                                    vertcat( obj.data(fIdx).(dSubScript)(xyIdx,:,:,:,:) );
                    elseif any( strcmpi( dSubScript, {'fileName','blockAnnotsCacheFile'} ) )
                        varargout{1:nargout} = { obj.data(fIdx).(dSubScript) }';
                    elseif any( strcmpi( dSubScript, {'blockAnnotations'} ) )
                        isEmpty_bas_bb = arrayfun( @(c)(isempty(c.blockAnnotations)), obj.data(fIdx) );
                        for bb = find( isEmpty_bas_bb )
                            bas_bb = [];
                            bacfIdxs = obj.data(bb).bacfIdxs;
                            bacfs = obj.data(bb).blockAnnotsCacheFile;
                            for mm = 1 : numel( bacfs )
                                bIdxs = obj.data(bb).bIdxs(bacfIdxs==mm);
                                bacf = load( bacfs{mm}, 'blockAnnotations' );
                                bas_ = bacf.blockAnnotations(bIdxs);
                                bas_ = Core.IdentTrainPipeDataElem.addPPtoBas( ...
                                                     bas_, obj.data(bb).y(bacfIdxs==mm) );
                                if isempty( bas_bb )
                                    bas_bb = bas_;
                                else
                                    bas_bb = vertcat( bas_bb, bas_ );
                                end
                            end
                            obj.data(bb).blockAnnotations = bas_bb;
                        end
                        varargout{1:nargout} = vertcat( obj.data(fIdx).blockAnnotations );
                    elseif strcmpi( dSubScript, 'pointwiseFileIdxs' )
                        out = [];
                        for ff = fIdx
                            out = [out; repmat( ff, size( obj.data(ff).x, 1 ), 1 )];
                        end
                        varargout{1:nargout} = out;
                    else
                        varargout{1:nargout} = vertcat( obj.data(fIdx).(dSubScript) );
                    end
                else % referencing whole DataElems
                    varargout{1:nargout} = obj.data(fIdx);
                end
            else
                if nargout == 0
                    builtin( 'subsref', obj, S );
                else
                    [varargout{1:nargout}] = builtin( 'subsref', obj, S );
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        % easy set interface
        function obj = subsasgn( obj, S, val )
            if (length(S) == 1) && strcmp(S(1).type,'()')
                fIdx = 0;
                if isa( S.subs{1,1}, 'char' )
                    if strcmp( S.subs{1,1}, '+' )
                        fIdx = numel( obj.data ) + 1;
                    else
                        fIdx = obj.getFileIdx( S.subs{1,1} );
                    end
                else
                    fIdx = S.subs{1,1};
                    if ~isnumeric( fIdx ) || fIdx > numel( obj.data )
                        error( 'Data indexing error' );
                    end
                end
                if ~isempty( fIdx ) && fIdx <= numel( obj.data ) && size( S.subs, 2 ) > 1
                    dSubscript = S.subs{1,2};
                    if size( S.subs, 2 ) > 2
                        xyIdx = S.subs{1,3};
                        if isa( xyIdx, 'char' )
                            dIdxLen = size( obj.data(fIdx).(dSubscript), 1 );
                            switch xyIdx
                                case ':'
                                    xyIdx = 1:dIdxLen;
                                case '+'
                                    xyIdx = dIdxLen+1:dIdxLen+size(val,1);
                                otherwise
                                    error( 'unknown indexing' );
                            end
                        end
                        if ndims( val ) > 5
                            error( 'D > 5 not supported' );
                        end
                        obj.data(fIdx).(dSubscript)(xyIdx,:,:,:,:) = val;
                    else
                        obj.data(fIdx).(dSubscript) = val;
                    end
                else
                    obj.data(fIdx) = val;
                end
            else
                obj = builtin( 'subsasgn', obj, S, val );
            end
        end
        %% -------------------------------------------------------------------------------

        function l = length( obj )
            l = 0;
            for d = obj.data
                l = l + size( d.x, 1 );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function ind = end( obj, k, ~ )
            switch k
                case 1
                    ind = length( obj.data );
                otherwise
                    error( 'not implemented' );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function ie = isempty( obj )
            ie = (numel( obj.data ) == 0 );
        end
        
        %% -------------------------------------------------------------------------------
        
        function autoSetStratificationLabels( obj )
            obj.stratificationLabels = fieldnames( obj.data(1).fileAnnotations );
            for d = obj.data
                fileAnnotLabelsNotIncludedAlready = ...
                     ~strcmp( obj.stratificationLabels, fieldnames( d.fileAnnotations ) );
                obj.stratificationLabels(fileAnnotLabelsNotIncludedAlready) = [];
            end
        end
        %% -------------------------------------------------------------------------------
        
        function permFolds = splitInPermutedStratifiedFolds( obj, nFolds, stratifyLabels )
            if nFolds == 0
                permFolds = [];
                return;
            end
            for ii = nFolds : -1 : 1, permFolds{ii} = Core.IdentTrainPipeData(); end
            if ~exist( 'stratifyLabels', 'var' ) || isempty( stratifyLabels )
                if obj.autoStratify, obj.autoSetStratificationLabels(); end
                stratifyLabels = obj.stratificationLabels;
            end
            if isempty( stratifyLabels )
                labelCombinationIdxs = ones( size( obj.data ) );
            else
                labelCombinationIdxs = obj.getDisjunctSubsetIdxs( stratifyLabels );
            end
            for lcIdx = 1 : numel( unique( labelCombinationIdxs ) )
                labelCombinationInstances = find( labelCombinationIdxs == lcIdx );
                nLabelCombinationFiles = numel( labelCombinationInstances );
                fIdxPerm = labelCombinationInstances(randperm( nLabelCombinationFiles ));
                for ii = 1 : nFolds
                    foldFidxPerm = fIdxPerm(ii:nFolds:nLabelCombinationFiles);
                    fold = permFolds{ii};
                    fold.data(end+1:end+length(foldFidxPerm)) = obj.data(foldFidxPerm);
                end
            end
        end
        %% -------------------------------------------------------------------------------

        function disjunctSubsetIdxs = getDisjunctSubsetIdxs( obj, labels )
            if isempty( labels ), disjunctSubsetIdxs = []; end
            if ~iscell( labels ), error( 'labels must be cell' ); end
            labelInstances = cell( numel( obj.data ), 1 );
            for dd = 1 : numel( obj.data )
                for ii = 1 : numel( labels )
                    fa = obj.data(dd).getFileAnnotation( labels{ii} );
                    if ~ischar( fa ), fa = mat2str( fa ); end
                    labelInstances{dd} = [labelInstances{dd} fa];
                end
            end
            [~,~,disjunctSubsetIdxs] = unique( labelInstances );
        end
        %% -------------------------------------------------------------------------------
        
        function fIdxs = getFilesLabeled( obj, label, labelValue )
            labelValues = arrayfun( @(df)( ...
                                      df.getFileAnnotation( label )...
                                                    ), obj.data, 'UniformOutput', false );
            if ischar( labelValue )
                fIdxs = strcmp( labelValues, labelValue );
            elseif isnumeric( labelValue )
                fIdxs = labelValue == labelValues;
            elseif isobject( labelValue )
                fIdxs = cellfun( @(lv)( lavelValue.equals( lv ) ), labelValues );
            else
                error( 'don''t know how to compare these labelValues' );
            end
        end
        %% -------------------------------------------------------------------------------

        function minSubsetSize = getMinDisjunctSubsetsSize( obj, labels )
            labelCombinationIdxs = obj.getDisjunctSubsetIdxs( labels );
            if isempty( labelCombinationIdxs ), minSubsetSize = 0; return; end
            minSubsetSize = inf;
            for lcIdx = 1 : numel( unique( labelCombinationIdxs ) )
                minSubsetSize = min( minSubsetSize, sum( lcIdx == labelCombinationIdxs ) );
            end            
        end
        %% -------------------------------------------------------------------------------
        
        function [share, disjShare] = getShare( obj, ratio, stratifyLabels )
            if ~exist( 'stratifyLabels', 'var' ) || isempty( stratifyLabels )
                if obj.autoStratify, obj.autoSetStratificationLabels(); end
                stratifyLabels = obj.stratificationLabels;
            end
            if isempty( stratifyLabels )
                maxFolds = numel( obj.data );
            else
                maxFolds = obj.getMinDisjunctSubsetsSize( stratifyLabels );
            end
            if maxFolds == 0
                share = Core.IdentTrainPipeData();
                disjShare = Core.IdentTrainPipeData();
                return;
            end
            nFolds = round( 100 / gcd( round( 100*ratio ), ...
                                       round( 100*(1-ratio) ) ) );
            nFolds = min( nFolds, maxFolds );
            folds = obj.splitInPermutedStratifiedFolds( nFolds, stratifyLabels );
            shareNfolds = round( nFolds * ratio );
            share = Core.IdentTrainPipeData.combineData( folds{1:shareNfolds} );
            if shareNfolds < nFolds
                disjShare = Core.IdentTrainPipeData.combineData( folds{shareNfolds+1:end} );
            else
                disjShare = [];
            end
        end
        %% -------------------------------------------------------------------------------

        function saveFList( obj, flistName, baseDir )
            fileNames = {};
            for dataFile = obj.data
                if nargin < 3
                    fileNames{end+1} = dataFile.fileName;
                else
                    fileNames{end+1} = sprintf( '%s', ...
                                              getPathPart( dataFile.fileName, baseDir ) );
                end
                fileNames{end} = strrep( fileNames{end}, '\', '/' );
            end
            flistFid = fopen( flistName, 'w' );
            for kk = 1 : length(fileNames)
                fprintf( flistFid, '%s\n', fileNames{kk} );
            end
            fclose( flistFid );
        end
        %% -------------------------------------------------------------------------------
        
        function loadFileList( obj, flistName, checkFileExistence )
            if nargin < 3, checkFileExistence = true; end
            if isempty( flistName ), return; end
            obj.data = Core.IdentTrainPipeDataElem.empty;
            try
                fid = fopen( db.getFile( flistName ) );
            catch err
                warning( err.message );
                error( '%s not found!', flistName );
            end
            fileList = textscan( fid, '%s' );
            for ff = 1 : length( fileList{1} )
                fprintf( '.' );
                if checkFileExistence
                    try
                        filepath = db.getFile( fileList{1}{ff} );
                        filepath = cleanPathFromRelativeRefs( filepath );
                        fprintf( '%s\n', filepath );
                    catch err
                        warning( err.message );
                        error( '%s, referenced in %s, not found!', fileList{1}{ff}, flistName );
                    end
                    p = fileparts( filepath );
                    addPathsIfNotIncluded( p );
                    filepath = which( filepath ); % ensure absolute path
                else
                    filepath = fileList{1}{ff};
                    filepath = cleanPathFromRelativeRefs( filepath );
                    fprintf( '%s\n', filepath );
                end
                obj.data(end+1) = Core.IdentTrainPipeDataElem( filepath );
            end
            fclose( fid );
            fprintf( '.\n' );
        end
        %% -------------------------------------------------------------------------------
        
        function fIdx = getFileIdx( obj, fileNames )
            if ~iscell( fileNames ), fileNames = {fileNames}; end
            fIdx = [];
            for ff = 1 : numel( fileNames )
                fIdxff = find( strcmp( fileNames{ff}, {obj.data.fileName} ) );
                if isempty( fIdxff ), continue; end
                fIdx(ff) = fIdxff;
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)

        function combinedData = combineData( varargin )
            combinedData = Core.IdentTrainPipeData();
            for ii = 1 : numel(varargin)
                dii = varargin{ii};
                nDii = numel( dii.data );
                combinedData.data(end+1:end+nDii) = dii.data;
            end
        end
        
    end
    
end
