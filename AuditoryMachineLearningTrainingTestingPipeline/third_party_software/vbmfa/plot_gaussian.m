% Plots a 2D or 3D 1 s.d. frame.
%
% 2D: 'n-1' divisions polar-wise,
% 3D: 'n-1' divisions each azimuthally and polar-wise,
% for a Gaussian with covariance 'covar' and mean 'mu',
% 'colour' can be any integer.     M.Beal GMLC 26/03/99
%
% hh = plot_gaussian(covar,mu,col,n);
%
% M J Beal 25/11/99 GCNU

function [hh] = plot_gaussian(covar,mu,col,n)

if ~isempty(find(covar-covar == 0))

  if size(mu,1) < size(mu,2), mu = mu'; end

  if size(covar,1) == 3

    theta = (0:1:n-1)'/(n-1)*pi;
    phi = (0:1:n-1)/(n-1)*2*pi;
    
    sx = sin(theta)*cos(phi);
    sy = sin(theta)*sin(phi);
    sz = cos(theta)*ones(1,n);
    
    svect = [reshape(sx,1,n*n); reshape(sy,1,n*n); reshape(sz,1,n*n)];
    epoints = sqrtm(covar) * svect  + mu*ones(1,n*n);
    
    ex = reshape(epoints(1,:),n,n);
    ey = reshape(epoints(2,:),n,n);
    ez = reshape(epoints(3,:),n,n);
    
    colourset = [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1];
    colour = colourset(mod(col-1,size(colourset,1))+1,:);      
    hh = mesh(ex,ey,ez, reshape(ones(n*n,1)*colour,n,n,3) );
    hidden off
    light

% for conversion to .eps figures, the 'mesh' command screws up the
% resolution. Therefore use these 4 lines instead of the previous 5.
%    colourset = ['r'; 'g'; 'b'; 'y'; 'm'; 'c']; 
%    colour = colourset(mod(col-1,size(colourset,1))+1,:);
%    plot3(epoints(1,:),epoints(2,:),epoints(3,:),colour)
%    plot3(reshape(ex',1,n*n),reshape(ey',1,n*n),reshape(ez',1,n*n),colour)
    
  else
    
    theta = (0:1:n-1)/(n-1)*2*pi;
    
    epoints = sqrtm(covar) * [cos(theta); sin(theta)]*1   + mu*ones(1,n);
    
    colourset = ['r'; 'g'; 'b'; 'y'; 'm'; 'c']; 
    colour = colourset(mod(col-1,size(colourset,1))+1,:);
    
    hold on
    hh = plot(epoints(1,:),epoints(2,:),colour,'LineWidth',3);
    plot(mu(1,:),mu(2,:),[colour '.']); hold off;
    
  end

else
  fprintf('\nVery ill covariance matrix - not plotting this one\n')
end










