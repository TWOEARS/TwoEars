function locErrors = localisationErrors(refAz, estAzs)
%localisationErrors    Calculates localisation errors
%
%USAGE
%  [locErrors] = localisationErrors(refAz, estAzs)
%
%INPUT ARGUMENTS
%    refAz      : source reference azimuth (0 - 359) 
%    estAzs     : a vector containing estimated azimuths (0 - 359)
%
%OUTPUT ARGUMENTS
%    locErrors  : localisation errors. Note the error between 350 and 10 is
%                 20 instead 340 degrees

locErrors = 180 - abs(abs(estAzs - refAz) - 180);
