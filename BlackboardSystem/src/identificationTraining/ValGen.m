classdef ValGen < Hashable & handle
    
    properties (SetAccess = protected)
        type;   % one of 'manual', 'set', 'random'
        val;    % depending on type: specific value, cell of possible values, or random range
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
        
        function val = value( obj )
            switch obj.type
                case 'manual'
                    val = obj.genManual();
                case 'set'
                    val = obj.genSet();
                case 'random'
                    val = obj.genRandom();
            end
        end
        
        function hashMembers = getHashObjects( obj )
            hashMembers = {obj.type, obj.val};
        end


    end
    %%
    methods (Access = protected)
        
        function val = genManual( obj )
            val = obj.val;
        end
        
        function val = genSet( obj )
            setLen = length( obj.val );
            randIdx = randi( setLen, 1 );
            if isa( obj.val, 'cell' )
                val = obj.val{randIdx};
            else
                val = obj.val(randIdx);
            end
        end
        
        function val = genRandom( obj )
            val = rand( 1 ) * ...
                (max( obj.val) - min( obj.val )) + ...
                min( obj.val );
        end
        
    end
    
end
