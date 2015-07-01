function dynSaveMFun( functionHandle, param, matFile )
f = functions( functionHandle );
urlname = ['file:///' f.file];
fstr = urlread( urlname );
save( matFile, 'fstr', 'f', 'param' );