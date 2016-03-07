classdef FileListValGen < sceneConfig.ValGen

    %%
    properties
        filesepsAreUnix = false; % for compatibility with saved FileListValGens
    end
    
    %%
    methods
        
        function obj = FileListValGen( val )
            if ~iscellstr( val ) && ~ischar( val )
                error( 'FileListValGen requires [cell] array with file name[s] as input.' );
            end
            val = strrep( val, '\', '/' );
            if ischar( val )
                valGenArgs = {'manual', val};
            elseif numel( val ) == 1
                valGenArgs = {'manual', val{1}};
            else
                valGenArgs = {'set', val};
            end
            obj = obj@sceneConfig.ValGen( valGenArgs{:} );
            obj.filesepsAreUnix = true;
        end
        
        function e = isequal( obj1, obj2 )
            if ~strcmpi( obj1.type, obj2.type )
                e = false; 
                return; 
            end
            if strcmpi( obj1.type, 'manual' )
                e = isequal( obj1.val, obj2.val ); 
                return; 
            end
            if length( obj1.val ) ~= length( obj2.val )
                e = false;
                return;
            end
            files1 = cell( size( obj1.val ) );
            files2 = cell( size( obj2.val ) );
            if ~obj1.filesepsAreUnix
                obj1.val = strrep( obj1.val, '\', '/' );
                obj1.filesepsAreUnix = true;
            end
            if ~obj2.filesepsAreUnix
                obj2.val = strrep( obj2.val, '\', '/' );
                obj2.filesepsAreUnix = true;
            end
            f1SepIdxs = strfind( obj1.val, '/' );
            f2SepIdxs = strfind( obj2.val, '/' );
            files1 = cellfun( @(f,idx)( f(idx(end-2):end) ), obj1.val, f1SepIdxs, 'UniformOutput', false );
            files2 = cellfun( @(f,idx)( f(idx(end-2):end) ), obj2.val, f2SepIdxs, 'UniformOutput', false );
            e = isequal( sort( files1 ), sort( files2 ) );
        end
        
    end
    
end
