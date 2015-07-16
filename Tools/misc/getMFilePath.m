function mpath = getMFilePath()

ST = dbstack( 1, '-completenames' );
mFileName = ST(1).name;
mFilePath = ST(1).file;
mpath = mFilePath(1:end-length(mFileName)-2);