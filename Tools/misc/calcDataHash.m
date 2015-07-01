function hash = calcDataHash( data, maxRecursionLevel )
%CALCDATAHASH ...
% TODO: add description

if ~exist( 'maxRecursionLevel', 'var' ), maxRecursionLevel = 10; end;
engine = java.security.MessageDigest.getInstance( 'MD5' );
hash = calcHashRecursion( data, engine, 0, maxRecursionLevel );
hash = sprintf( '%.2x', hash );   % To hex string

end

function hash = calcHashRecursion( data, engine, recursionLevel, maxRecursionLevel )

% Consider the type of empty arrays:
s = [class(data), sprintf('%d ', size(data))];
engine.update(typecast(uint16(s(:)), 'uint8'));
hash = double(typecast(engine.digest, 'uint8'));

if recursionLevel > maxRecursionLevel, return; end;

if isa( data, 'struct' )
    n = numel(data);
    if n == 1  % Scalar struct:
        F = sort(fieldnames(data));  % ignore order of fields
        for iField = 1:length(F)
            hash = bitxor(hash, calcHashRecursion(data.(F{iField}), engine, recursionLevel + 1, maxRecursionLevel));
        end
    else  % Struct array:
        for iS = 1:n
            hash = bitxor(hash, calcHashRecursion(data(iS), engine, recursionLevel + 1, maxRecursionLevel));
        end
    end
elseif isempty( data )
    % No further actions needed
elseif isnumeric( data )
    if ~isreal( data )
        data = [real(data), imag(data)];
    end
    engine.update(typecast(data(:), 'uint8'));
    hash = bitxor(hash, double(typecast(engine.digest, 'uint8')));
elseif ischar( data )  % Silly TYPECAST cannot handle CHAR
    engine.update(typecast(uint16(data(:)), 'uint8'));
    hash = bitxor(hash, double(typecast(engine.digest, 'uint8')));
elseif iscell( data )
    for iS = 1:numel(data)
        hash = bitxor(hash, calcHashRecursion(data{iS}, engine, recursionLevel + 1, maxRecursionLevel));
    end
elseif islogical( data )
    engine.update(typecast(uint8(data(:)), 'uint8'));
    hash = bitxor(hash, double(typecast(engine.digest, 'uint8')));
elseif isa( data, 'function_handle' )
    hash = bitxor(hash, calcHashRecursion(functions(data), engine, recursionLevel + 1, maxRecursionLevel));
elseif isa( data, 'Hashable' )
    for ii = 1:numel( data )
        hash = bitxor( hash, calcHashRecursion( data(ii).getHashObjects(), engine, recursionLevel + 1, maxRecursionLevel ) );
    end
elseif isobject( data )
    for ii = 1:numel( data )
        hashProps = getNonTransientObjectProps( data(ii) );
        hash = bitxor(hash, calcHashRecursion( hashProps, engine, recursionLevel + 1, maxRecursionLevel ));
    end
else
    warning( ['Type of variable not considered: ', class(data)] );
end

end

