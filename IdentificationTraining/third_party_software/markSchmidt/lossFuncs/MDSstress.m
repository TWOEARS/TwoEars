function [S,g] = stress(z,D,visualize)
visualize = 1;
nInst = length(D);
nComp = numel(z)/nInst;

z = reshape(z,nInst,nComp);

if nargout > 1
    g = zeros(size(z));
end

S = 0;
for i = 1:nInst
    for j = i+1:nInst
        nrmDist = norm(z(i,:)-z(j,:));
        s = D(i,j) - nrmDist;
        S = S + s^2;
        
        if nargout > 1
            g(i,:) = g(i,:) - 2*(s/nrmDist)*(z(i,:)-z(j,:));
            g(j,:) = g(j,:) - 2*(s/nrmDist)*(z(j,:)-z(i,:));
        end
    end
end

if nargout > 1
    g = g(:);
end

if visualize
    if nComp == 2
        plot(z(:,1),z(:,2),'.');
        pause(.01)
	else
        plot3(z(:,1),z(:,2),z(:,3),'.');
        pause(.01)
    end
end
end