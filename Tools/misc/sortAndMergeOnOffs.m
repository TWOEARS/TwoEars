%sortAndMergeOnOffs   This function will sort the rows of onOffs and
%   then merge consecutive rows that overlap (i.e. where onOffs(r,2) >=
%   onOffs(r+1,1).
%
%   USAGE
%       onOffs = sortAndMergeOnOffs( onOffs )
%
%   INPUT PARAMETERS
%       onOffs     -   a numerical array of dimension Nx2
%
%   OUTPUT PARAMETERS
%       onOffs     -   same as input, but sorted and with merged rows
%
function onOffs = sortAndMergeOnOffs( onOffs )

if ~isa( onOffs, 'numeric' ), error( 'onOffs must be a numeric array' ); end
if size( onOffs, 2 ) ~= 2, error( 'onOffs must be an Nx2 array' ); end

onOffs = sortrows( onOffs );

kk = 1;
while kk < size( onOffs, 1 )
    if onOffs(kk,2) >= onOffs(kk+1,1)
        onOffs(kk,2) = max( onOffs(kk,2), onOffs(kk+1,2) );
        onOffs(kk+1,:) = [];
    else
        kk = kk + 1;
    end
end
