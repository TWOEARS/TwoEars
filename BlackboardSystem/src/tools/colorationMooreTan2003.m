function D = colorationMooreTan2003(testExcitationPattern, refExcitationPattern, audioType)
%colorationMooreTan2003 predicts the coloration between two given excitation patterns
%
%   USAGE
%       D = colorationMooreTan2003(testExcitationPattern, refExcitationPattern, audioType)
%
%   INPUT PARAMETERS
%       testExcitationPattern   - excitation pattern of the test signal
%       refExcitationPattern    - excitation pattern of the reference signal
%       audioType               - type of audio:
%                                   'speech'
%                                   'non-speech' (default)
%
%   OUTPUT PARAMETERS
%       D                       - weighted excitation pattern difference (~coloration)
%
%   DETAILS
%
%       This function calculates the values D of the Moore and Tan (2004) model. It is
%       used inside ColorationKS, where the two excitation patterns are provided.

% Model parameters:
%
%   * s    - sharpening of the auditory filters
%   * w    - weighting factor between first and second order model parameters
%   * f    - floor value, excitation levels below this level are set to the fixed
%            value f. This value should enhance the prediction for signals were
%            complete parts of the signal are missing.
%   * w_s  - slope of the decrease in weighting for high frequency channels
%
s = 1.5; % Applied directly in ColorationKS
w = 0.4;
f = -40; % not used yet (original f = 32;)
w_s = 0.5;

% Sum up over time
refExcitationPattern = db(rms(refExcitationPattern))';
testExcitationPattern = db(rms(testExcitationPattern))';

% Apply floor value, see 1.3 on page 903
refExcitationPattern(refExcitationPattern<f) = f;
testExcitationPattern(testExcitationPattern<f) = f;

% First order differences, compare 1.2
diffFirstOrder = abs(testExcitationPattern - refExcitationPattern);
% Second order differences, compare 1.2
for nn = 1:size(diffFirstOrder, 1) - 1
    diffSecondOrder(nn) = ...
        (testExcitationPattern(nn+1) - refExcitationPattern(nn+1)) - ...
        (testExcitationPattern(nn) - refExcitationPattern(nn));
end

% Create weighting parameter for the different frequency channels
weight = ones(79,1);                                         % (2) on page 903
weight(34:79) = 1 - w_s .* (linspace(17.5,40,46)-17.5) / 46; % (3) on page 903
% Weights for the case of speech, see the remarks under (2) and (3) on page 903
if strcmp('speech', audioType)
    weight(1:6) = 0;
    weight(37:72) = 0;
end

% Sum and standard deviation of first order differences across frequency channels
sumFirstOrder = sum(abs(weight .* diffFirstOrder)); % 1) on page 901
sdFirstOrder = std(abs(weight .* diffFirstOrder));  % 2) on page 901
% Sum and standard deviation of second order differences across frequency channels
sumSecondOrder = sum(abs(weight(1:end-1) .* diffSecondOrder')); % 3) on page 903
sdSecondOrder = std(abs(weight(1:end-1) .* diffSecondOrder'));  % 4) on page 903
% Weighted sum of both orders
sumD = w * sumFirstOrder + (1-w) * sumSecondOrder; % 5) on page 903
sdD = w * sdFirstOrder + (1-w) * sdSecondOrder;    % 6) on page 903

% Use only standard deviaton as metric, see text after 6) on page 903
D = sdD;

% Scale predictions to be in the range ~ 0..1
D = D / 2.5;

% vim: set sw=4 ts=4 et tw=90:
