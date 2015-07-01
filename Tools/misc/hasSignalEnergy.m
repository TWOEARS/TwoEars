function bEnergy = hasSignalEnergy(signal, blocksize_s, timeOffset_s)

bEnergy = false;
energy = 0;
for ii=1:numel(signal)
    energy = energy + std(signal{ii}.getSignalBlock(blocksize_s, timeOffset_s));
end
% FIXME: why we have chosen 0.01 as threshold?
bEnergy = (energy >= 0.01);
