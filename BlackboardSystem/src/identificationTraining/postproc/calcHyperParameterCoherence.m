function hpc = calcHyperParameterCoherence( hps, xdim, ydim )

if ndims( hps ) < 3
    h(1,:,:) = hps;
else
    h = hps;
end

for i = 1:size( h, 1 )
    x = h(i,:,xdim);
    y = h(i,:,ydim);
    z = h(i,:,end);
    
    [X,Y] = meshgrid( logspace( log10(min( x )), log10(max( x )), 20 ), logspace( log10(min( y )), log10(max ( y )), 20 ) );
    Z(i,:,:) = griddata( x, y, z, X, Y, 'linear' );
end

hpc = mean(mean(std( Z )));
