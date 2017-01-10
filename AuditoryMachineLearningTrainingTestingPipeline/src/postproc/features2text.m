function features2text( featureNames, idxs, fileName )

if nargin > 2
    fid = fopen( fileName, 'w' );
else
    fid = 1;
end

if size( idxs, 1 ) ~= 1, idxs = idxs'; end

for idx = idxs
    for ii = 1 : numel( featureNames{idx} )
        if ischar( featureNames{idx}{ii} )
            fprintf( fid, '%s', featureNames{idx}{ii} );
        else
            fprintf( fid, '%s', mat2str( featureNames{idx}{ii} ) );
        end
        if ii < numel( featureNames{idx} )
            fprintf( fid, '; ' );
        else
            fprintf( fid, '\n' );
        end
    end
end
