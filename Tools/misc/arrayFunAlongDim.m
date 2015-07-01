function result = arrayFunAlongDim( fn, ar, dim )
%arrayFunAlongDim   Applies function fn to array ar along dimension dim.
%
%   USAGE
%       result = arrayFunAlongDim( fn, ar, dim )
%
%   INPUT PARAMETERS
%                  fn   -   function handle, takes array and returns
%                           anything
%                  ar   -   array
%                 dim   -   index of dimension along which the function is
%                           applied.
%
%   OUTPUT PARAMETERS
%              result   -   cell array of results of fn along dim in ar
%
% author: Ivo Trowitzch, TU Berlin

arraySplit = num2cell( ar, dim );
result = cellfun( fn, arraySplit, 'UniformOutput', false );