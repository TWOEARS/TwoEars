classdef ValGen < matlab.mixin.Copyable & matlab.mixin.Heterogeneous
    
    properties (SetAccess = protected)
        type;   % one of 'manual', 'set', 'random'
        val;    % depending on type: specific value, cell of possible values, or random range
    end
    
    properties (Access = protected)
        instantiated = false;
    end
    
    %%
    methods
        
        function obj = ValGen( type, val )
            if sum( strcmpi( type, {'manual', 'set', 'random'} ) ) == 0
                error( 'Type not recognized' );
            end
            obj.type = type;
            obj.val = val;
        end
        
        function instance = instantiate( obj )
            if isempty( obj )  ||  obj.instantiated
                instance = obj; return; 
            end
            instance = copy( obj );
            instance.type = 'manual';
            instance.val = obj.value();
            instance.instantiated = true;
        end
        
        function val = value( obj )
            switch obj.type
                case 'manual'
                    val = obj.val;
                case 'set'
                    setLen = length( obj.val );
                    if setLen == 0, val = []; return; end;
                    randIdx = randi( setLen, 1 );
                    if isa( obj.val, 'cell' )
                        val = obj.val{randIdx};
                    else
                        val = obj.val(randIdx);
                    end
                case 'random'
                    val = rand( 1 ) * (max( obj.val) - min( obj.val )) + min( obj.val );
            end
        end
        
        function e = isequal( obj1, obj2 )
            e = zeros( size( obj2 ) );
            if numel( obj1 ) > 1
                error( 'ValGen.isequal expects a single object as first argument.' );
            end
            if isempty( obj1 ) && isempty( obj2 ), e = true; return; end
            if isempty( obj1 ) || isempty( obj2 ), return; end
            for ii = 1 : numel( obj2 )
                if ~strcmpi( obj1.type, obj2(ii).type ), continue; end
                if strcmpi( obj1.type, 'manual' )
                    e(ii) = isequal( obj1.val, obj2(ii).val );
                else
                    e(ii) = isequal( sort( obj1.val ), sort( obj2(ii).val ) );
                end
            end
            e = logical( e );
        end
        
    end
    
end
