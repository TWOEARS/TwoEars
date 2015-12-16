function idxs = getFeatureIdxs( fDescription, varargin )

idxs = [];
nidxs = 1 : numel( fDescription );

for ii = 1 : numel( varargin )
    lidxs = true( size( fDescription ) );
    for jj = 1 : numel( varargin{ii} )
        if ischar( varargin{ii}{jj} )
            lidxs = lidxs & cellfun( @(fd)(any( strcmp( varargin{ii}{jj}, fd ) )), fDescription );
        else
            lidxs = lidxs & cellfun( @(fd)(eq( varargin{ii}{jj}, fd )), fDescription );
        end
    end
    idxs = unique( [idxs, nidxs(lidxs)] );
end
