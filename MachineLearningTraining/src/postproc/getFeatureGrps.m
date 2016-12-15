function grps = getFeatureGrps( fdescription )

g = cat( 2, fdescription{:} );

strs = {};
nums = {};
dels = [];
for kk = 1 : size( g, 2 )
    if ischar( g{kk} )
        if ~any( strcmp( strs, g{kk} ) )
            strs{end+1} = g{kk};
        else
            dels(end+1) = kk;
        end
    else
        if ~any( cellfun( @(n)(eq(n,g{kk})), nums ) )
            nums{end+1} = g{kk};
        else
            dels(end+1) = kk;
        end
    end
end
for kk = numel( dels ) : -1 : 1
    g(dels(kk)) = [];
end

grps = g;