function lms = lMomentAlongDim( d, nl, dim )

lms = arrayFunAlongDim( @(x)(lMoments(x,nl,true)), d, dim );
lms = cell2mat( lms );


