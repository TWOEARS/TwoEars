function [distribution1, distribution2] = ...
        removeFrontBackConfusion(azimuths, distribution1, distribution2, rotateAngle)
%removeFrontBackConfusion removes front back confusions for a source direction
%
%   USAGE
%       [distribution1, distribution2] = ...
%           removeFrontBackConfusion(azimuths, distribution1, distribution2, rotateAngle)
%
%   INPUT PARAMETERS
%       azimuths            possible azimuth angles (x-axis of sources distributions)
%       distribution1       sources distribution before head rotation
%       distribution2       sources distribution after head rotation
%       rotateAngle         head rotation angle
%
%   OUTPUT PARAMETERS
%       distribution1       sources distribution with removed confusion
%       distribution2       sources distribution with removed confusion

if rotateAngle == 0
    return
end

threshold = 0.02;
nAz = numel(azimuths);

% Identify front-back confusion from distribution1
distribution1 = distribution1(:);
distribution2 = distribution2(:);
[pIdx1,pa] = findAllPeaks([0; distribution1; 0]);
pIdx1 = pIdx1 - 1;
pIdx1 = pIdx1(pa > threshold);
[fbIdx1, fbAz1] = find_front_back_idx(azimuths, pIdx1);

% Identify front-back confusion from distribution2
[pIdx2,pa] = findAllPeaks([0; distribution2; 0]);
pIdx2 = pIdx2 - 1;
pIdx2 = pIdx2(pa > threshold);
[fbIdx2, fbAz2] = find_front_back_idx(azimuths, pIdx2);

% Check if any front-back confusion from distribution1 should be removed
srcAz = [];
for n = 1:size(fbIdx1,1)

    % Set prob of both front-back angles to the max
    p = max(distribution1(fbIdx1(n,:)));
    fbAzNew = mod(fbAz1(n,:) - rotateAngle, 360);
    for m = 1:2
        %if min(abs(azimuth(pIdx2) - fbAzNew(m))) > 5
        if distribution2(azimuths==fbAzNew(m)) < threshold
            idx = fbIdx1(n,m)-1:fbIdx1(n,m)+1;
            idx = idx(idx>=1);
            idx = idx(idx<=nAz);
            distribution1(idx) = 0;
            distribution1(fbIdx1(n,mod(m,2)+1)) = p;
        else
            srcAz = [srcAz; fbAzNew(m)];
        end
    end

end

% Check if any front-back confusion from distribution2 should be removed
for n = 1:size(fbIdx2,1)

    % Set prob of both front-back angles to the max
    p = max(distribution2(fbIdx2(n,:)));
    fbAzNew = mod(fbAz2(n,:) + rotateAngle, 360);
    for m = 1:2
        if (isempty(fbAz2(n,mod(m,2)+1)) || isempty(distribution1(azimuths==fbAzNew(m))))
            continue;
        end

        %if sum(fbAz2(n,mod(m,2)+1)==srcAz)>0 || min(abs(azimuth(pIdx1) - fbAzNew(m))) > 5
        if sum(fbAz2(n,mod(m,2)+1)==srcAz)>0 || ...
                distribution1(azimuths==fbAzNew(m)) < threshold
            idx = fbIdx2(n,m)-1:fbIdx2(n,m)+1;
            idx = idx(idx>=1);
            idx = idx(idx<=nAz);
            distribution2(idx) = 0;
            distribution2(fbIdx2(n,mod(m,2)+1)) = p;
        end
    end

end


%------------
function [fbIdx, fbAz] = find_front_back_idx(azimuths, pIdx)

fbIdx = [];
fbAz = [];
for m = 1:length(pIdx)-1

    for n = m+1:length(pIdx)

        az1 = azimuths(pIdx(m));
        az2 = azimuths(pIdx(n));
        if abs(az1 + az2 - 180) <= 5 || abs(az1 + az2 - 540) <= 5
            fbIdx = [fbIdx; [pIdx(m) pIdx(n)]];
            fbAz = [fbAz; [az1 az2]];
        end

    end

end
% vim: set sw=4 ts=4 et tw=90 cc=+1:
