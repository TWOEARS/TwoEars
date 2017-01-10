classdef (Abstract) Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        performance;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = Base( yTrue, yPred )
            if nargin < 2
                error( ['Subclass of performanceMeasures.Base must call superconstructor ',...
                        'and pass yTrue and yPred.'] );
            end
            [obj, obj.performance] = obj.calcPerformance( yTrue, yPred );
        end
        % -----------------------------------------------------------------
    
        function b = lt( obj, otherPm )
            b = ~( obj == otherPm ) && ~( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = le( obj, otherPm )
            b = ~( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = ge( obj, otherPm )
            b = ( obj == otherPm ) || ( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = ne( obj, otherPm )
            b = ~( obj == otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = eq( obj1, obj2 )
            if isa( obj1, 'numeric' )
                b = obj1 == double( obj2 );
            elseif isa( obj2, 'numeric' )
                b = obj2 == double( obj1 );
            else
                b = obj1.eqPm( obj2 );
            end
        end
        % -----------------------------------------------------------------
    
        function b = gt( obj1, obj2 )
            if isa( obj1, 'numeric' )
                b = obj1 > double( obj2 );
            elseif isa( obj2, 'numeric' )
                b = double( obj1 ) > obj2;
            else
                b = obj1.gtPm( obj2 );
            end
        end
        % -----------------------------------------------------------------
        
        function disp( obj )
            disp( obj.char() );
        end
        % -----------------------------------------------------------------

    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        [obj, performance] = calcPerformance( obj, yTrue, yPred )
        b = eqPm( obj, otherPm )
        b = gtPm( obj, otherPm )
        s = char( obj )
        d = double( obj )
    end
    
end

