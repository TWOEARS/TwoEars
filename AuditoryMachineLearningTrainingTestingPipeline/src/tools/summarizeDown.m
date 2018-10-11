function xsummed = summarizeDown( x, leaveVariables, doNotSqueeze )
    dims = 1 : ndims( x );
    dims(leaveVariables) = [];
    dims = flip( dims );
    xsummed = x;
    for dd = dims
        xsummed = sum( xsummed, dd );
    end
    if nargin < 3 || ~doNotSqueeze
        xsummed = squeeze( xsummed );
    end
end

