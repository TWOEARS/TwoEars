function resetBinauralSimulator(sim, headOrientation)
%resetBinauralSimulator move head orientation back and reinits Binaural Simulator
%
%   USAGE
%       resetBinauralSimulator(sim, headOrientation)
%
%   INPUT PARAMETERS
%       sim              - Binaural Simulator object
%       headOrientation  - head oreintation the Binaural Simulator should start with

sim.rotateHead(headOrientation, 'absolute');
sim.ReInit = true;
