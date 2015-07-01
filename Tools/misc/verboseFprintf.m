function verboseFprintf( obj, formatstr, varargin )

if obj.verbose
    if nargin > 2
        fprintf( formatstr, varargin{:} );
    else
        fprintf( formatstr );
    end
end
