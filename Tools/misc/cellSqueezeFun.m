function cs = cellSqueezeFun( fn, c, dim, nonUniformOut )

if nargin < 4, nonUniformOut = false; end

szC = size( c );
szCs = szC;
szCs(dim) = 1;
cs = cell(szCs);

targetIdxVectors = {};
for targetIdx = 1 : numel( szC )
    if targetIdx == dim
        targetIdxVectors{end+1} = ones( 1, szC(targetIdx) );
    else
        targetIdxVectors{end+1} = 1 : szC(targetIdx);
    end
end

targetIdxGrid = cell( 1, numel( szC ) );
[targetIdxGrid{:}] = ndgrid( targetIdxVectors{:} );

for cLinIdx = 1 : numel( c )
    targetIdx = {};
    for kk = 1 : numel( targetIdxGrid )
        targetIdx{end+1} = targetIdxGrid{kk}(cLinIdx);
    end
    if isempty( cs{targetIdx{:}} )
        cs{targetIdx{:}} = c{cLinIdx};
    else
        if ~isempty( c{cLinIdx} )
            cs{targetIdx{:}} = cat( dim, cs{targetIdx{:}}, c{cLinIdx} );
        end
    end
end

cs = cellfun( fn, cs, 'UniformOutput', ~nonUniformOut );
