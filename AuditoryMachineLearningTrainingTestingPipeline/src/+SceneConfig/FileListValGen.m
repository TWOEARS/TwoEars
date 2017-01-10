classdef FileListValGen < SceneConfig.ValGen

    %%
    properties
        filesepsAreUnix = false; % for compatibility with saved FileListValGens
        eqTestFlistPrep = {};
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
            obj = obj@SceneConfig.ValGen( valGenArgs{:} );
            obj.filesepsAreUnix = true;
            obj.prepEqTestFlist();
        end
        
        function obj = prepEqTestFlist( obj )
            if strcmpi( obj.type, 'set' )
                fSepIdxs = strfind( obj.val, '/' );
                obj.eqTestFlistPrep = cellfun( ...
                                    @(f,idx)( f(idx(end-2):end) ), obj.val, fSepIdxs, ...
                                                                 'UniformOutput', false );
                obj.eqTestFlistPrep = sort( obj.eqTestFlistPrep );
            else
                obj.eqTestFlistPrep = obj.val;
            end
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
            if ~obj1.filesepsAreUnix
                obj1.val = strrep( obj1.val, '\', '/' );
                obj1.filesepsAreUnix = true;
            end
            if ~obj2.filesepsAreUnix
                obj2.val = strrep( obj2.val, '\', '/' );
                obj2.filesepsAreUnix = true;
            end
            if isempty( obj1.eqTestFlistPrep )
                obj1.prepEqTestFlist();
            end
            if isempty( obj2.eqTestFlistPrep )
                obj2.prepEqTestFlist();
            end
            e = isequal( obj1.eqTestFlistPrep, obj2.eqTestFlistPrep );
        end
        
    end
    
end
