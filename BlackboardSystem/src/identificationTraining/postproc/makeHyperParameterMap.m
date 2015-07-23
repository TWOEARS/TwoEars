function makeHyperParameterMap( hps, xdim, ydim )

if ndims( hps ) == 3
    hps = reshape( hps, size(hps,1)*size(hps,2), size(hps,3) );
end
x = hps(:,xdim);
y = hps(:,ydim);
z = hps(:,end);

[X,Y] = meshgrid( logspace( log10(min( x )), log10(max( x )), 20 ), logspace( log10(min( y )), log10(max ( y )), 20 ) );
Z = griddata( x, y, z, X, Y, 'linear' );

figure1 = figure;
axes1 = axes('Parent',figure1,'YScale','log','YMinorTick','on',...
    'XScale','log',...
    'XMinorTick','on',...
    'Layer','top');
box(axes1,'on');
hold(axes1,'all');
contourf( X, Y, Z,'Parent',axes1);
colorbar('peer',axes1);

