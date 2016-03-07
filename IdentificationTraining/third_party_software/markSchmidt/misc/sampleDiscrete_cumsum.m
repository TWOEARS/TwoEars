function [y] = sampleDiscrete(cs)
% Returns a sample from a cumulative distribution function cs

% Find index y such that cs(y) > u and cs(y-1) < u, 
u = rand;
maxY = length(cs);
minY = 1;
while 1
	y = ceil((minY+maxY)/2);
	
	if cs(y) > u
		if y == 1 || cs(y-1) < u
			% satisfied
			break;
		else
			% y is too big
			maxY = y-1;
		end
	else
		% y is too small
		minY = y+1;
	end
end
