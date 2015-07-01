function writehtk(file, d, frmPeriod, kind, byteorder)
%WRITEHTK  write an HTK parameter file 
%writehtk(file, d, frmPeriod, kind, byteorder)
%
%  file          HTK format data file
%  d             data (nDimensions x nFrames). Waveform should be in stored
%                in row vectors.
%  frmPeriod     frame period in seconds (default 0.01)
%  kind          parameter kind code, the sum of the following values:
%      0             WAVEFORM
%      1             LPC
%      2             LPREFC
%      3             LPCEPSTRA
%      4             LPDELCEP
%      5             IREFC
%      6             MFCC
%      7             FBANK
%      8             MELSPEC
%      9             USER
%      10            DISCRETE
%      64            _E  log energy included
%      128           _N  absolute energy suppressed
%      256           _D  delta coefs appended
%      512           _A  acceleration coefs appended
%      1024          _C  is compressed
%      2048          _Z  zero meaned
%      4096          _K  has CRC checksum
%      8192          _0  0'th cepstral coef included
%      16384         _V  has VQ index attached
%  byteorder     byte order 'b' or 'l' (default 'b')
%
% Ning Ma, University of Sheffield
% 18 Nov 2006

if nargin < 5
  byteorder = 'b'; % big endian
end
if nargin < 4
  kind = 9; % USER
end
if nargin < 3
  frmPeriod = 0.01; % in seconds
end

fid = fopen(file, 'w', byteorder);
if fid < 0
  error('Unable to create HTK file %s', file);
end

[ndims, nframes] = size(d);

% Write the HTK header
fwrite(fid, nframes, 'int32'); % number of samples
fwrite(fid, frmPeriod*1e7, 'int32'); % sample period in 100ns units

if ( kind == 0 ) % Waveform
  fwrite(fid, 2, 'int16'); % sample size
  fwrite(fid, kind, 'int16'); 
  fwrite(fid, d, 'int16');
else
  fwrite(fid, ndims*4, 'int16'); % sample size
  fwrite(fid, kind, 'int16'); 
  fwrite(fid, d, 'float32' );
end

fclose(fid);

