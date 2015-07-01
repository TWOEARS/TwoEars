function ms = momentsAlongDim( d, nl, dim )

ms = arrayFunAlongDim( @(x)(moments(x,nl)), d, dim );
ms = cell2mat( ms );


end

function ms = moments( x, nl )

ms = [];
for mm = nl
    switch mm
        case 1
            ms = [ms mean( x )];
        case 2
            ms = [ms std( x )];
        case 3
            ms = [ms skewness( x )];
        case 4
            ms = [ms kurtosis( x )];
    end
end

end