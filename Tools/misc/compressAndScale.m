function d = compressAndScale( d, compressor, scalor, dim )
%compressAndScale   This function will compress and scale matrix d.
%                   First the compression takes place as 
%                       d = sign(d) .* abs(d).^compressor,
%                   Then scaling is applied individually along dimension dim,
%                   determining the scale with the function scalor.
%
%   USAGE
%       d = compressAndScale( d, compressor, scalor, dim )
%
%   INPUT PARAMETERS
%                   d   -   a numerical matrix
%         [compressor]  -   positive value (default = 1)
%             [scalor]  -   a function handle of a function that gets as input 
%                           a numerical vector and returns the value that shall
%                           be scaled to 0.5 (default = @(x)(0.5))
%                [dim]  -   index of dimension along which the matrix d is
%                           scaled. Put 0 to apply to matrix d as a whole.
%                           (default = 0)
%
%   OUTPUT PARAMETERS
%                   d   -   compressed and scaled matrix d
%
% author: Ivo Trowitzch, TU Berlin

if nargin < 2
    compressor = 1;
end
if nargin < 3
    scalor = 0.5;
end
if nargin < 4
    dim = 0;
end
if dim == 0
    d = sign(d) .* abs(d).^compressor;
    if isnumeric( scalor )
        dScalor = scalor;
    elseif isa( scalor, 'function_handle' )
        dScalor = scalor( d(:) );
    else
        error( 'AMLTTP:unsupportedUsage', 'scalor has to be a number or a function handle to a function that produces a number.' );
    end
    if isnan( dScalor ), scale = 1;
    else scale = 0.5 / dScalor; end;
    d = d .* repmat( scale, size( d ) );
else
    d = arrayFunAlongDim( @(x)(compressAndScale(x,compressor,scalor,0)), d, dim );
    d = cell2mat( d );
end

end
