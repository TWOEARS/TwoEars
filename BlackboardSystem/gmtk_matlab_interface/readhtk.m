function [d, frmPeriod, strKind, kind ] = readhtk ( file, byteorder )
%READ_HTK  read an HTK parameter file 
%[d, frmPeriod, strKind, kind ] = readhtk ( file, byteorder );
%
%  file          HTK format data file
%  byteorder     byte order 'b' or 'l' ( default - 'b' )
%
%  d             data ( nDim x nFrames )
%  frmPeriod     frame period in seconds
%  strKind       parameter kind in string format ( e.g. MFCC_E_D )
%  kind          parameter kind code, the sum of the following values:
%
%  0             WAVEFORM
%  1             LPC
%  2             LPREFC
%  3             LPCEPSTRA
%  4             LPDELCEP
%  5             IREFC
%  6             MFCC
%  7             FBANK
%  8             MELSPEC
%  9             USER
%  10            DISCRETE
%  64            _E  log energy included
%  128           _N  absolute energy suppressed
%  256           _D  delta coefs appended
%  512           _A  acceleration coefs appended
%  1024          _C  is compressed
%  2048          _Z  zero meaned
%  4096          _K  has CRC checksum
%  8192          _0  0'th cepstral coef included
%  16384         _V  has VQ index attached
%
%Ning Ma, University of Sheffield
%n.ma@dcs.shef.ac.uk, 18 Nov 2006

if nargin < 2
   byteorder = 'b';
end
fid = fopen ( file, 'r', byteorder );
if fid < 0
   error ( sprintf ( 'Unable to open HTK file %s', file ) );
end

nFrames = fread ( fid, 1, 'int32' );
frmPeriod = fread ( fid, 1, 'int32' ) * 1e-7;
frmSize = fread ( fid, 1, 'int16' );
kind = fread ( fid, 1, 'int16' );

if frmSize <= 0 || frmSize > 5000 || nFrames <= 0 || frmPeriod <= 0 || frmPeriod > 1
   fclose ( fid );
   error ( 'Invalid HTK header' );
end

if ( kind == 0 )
  d = fread ( fid, Inf, 'int16' );
else
  d = fread ( fid, [frmSize/4, nFrames], 'float32' );
end
fclose ( fid );

if nargout > 2
   ParmKinds = { 'WAVEFORM', 'LPC', 'LPREFC', 'LPCEPSTRA', 'LPDELCEP', ...
        'IREFC', 'MFCC', 'FBANK', 'MELSPEC', 'USER', 'DISCRETE', 'ANON' };  
   BASEMASK = 63;       % Mask to remove qualifiers
   HAS_E =    64;       % _E log energy included
   HAS_N =   128;       % _N absolute energy suppressed
   HAS_D =   256;       % _D delta coef appended
   HAS_A =   512;       % _A acceleration coefs appended
   HAS_C =  1024;       % _C is compressed
   HAS_Z =  2048;       % _Z zero meaned
   HAS_K =  4096;       % _K has CRC check
   HAS_0 =  8192;       % _0 0'th Cepstra included
   HAS_V = 16384;       % _V has VQ index attached

   strKind = ParmKinds ( bitand ( kind, BASEMASK ) + 1 );
   if bitand ( kind, HAS_E ) > 0; strKind = strcat ( strKind, '_E' ); end;
   if bitand ( kind, HAS_N ) > 0; strKind = strcat ( strKind, '_N' ); end;
   if bitand ( kind, HAS_D ) > 0; strKind = strcat ( strKind, '_D' ); end;
   if bitand ( kind, HAS_A ) > 0; strKind = strcat ( strKind, '_A' ); end;
   if bitand ( kind, HAS_C ) > 0; strKind = strcat ( strKind, '_C' ); end;
   if bitand ( kind, HAS_Z ) > 0; strKind = strcat ( strKind, '_Z' ); end;
   if bitand ( kind, HAS_K ) > 0; strKind = strcat ( strKind, '_K' ); end;
   if bitand ( kind, HAS_0 ) > 0; strKind = strcat ( strKind, '_0' ); end;
   if bitand ( kind, HAS_V ) > 0; strKind = strcat ( strKind, '_V' ); end;
end

%-- end
