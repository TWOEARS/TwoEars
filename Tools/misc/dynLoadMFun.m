function [fh, tmpmpath, param] = dynLoadMFun( matFile )

v = load( matFile, 'fstr', 'f', 'param' );
tmpmfile = sprintf( 'tmp%s%bx', v.f.function, now );
fstr = strrep( v.fstr, v.f.function, tmpmfile );
fid = fopen( [tmpmfile '.m'], 'w' );
fprintf( fid, '%s', fstr );
fclose( fid );
fh = str2func( tmpmfile );
tmpmpath = fullfile( [pwd filesep tmpmfile '.m'] );
param = v.param;
