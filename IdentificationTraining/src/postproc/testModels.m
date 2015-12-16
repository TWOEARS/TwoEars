function testModels( dirName, wavflist, trainWavflist, testWavflist, testFun, param )

if numel( param ) > 1
    testModels( dirName, wavflist, trainWavflist, testWavflist, testFun, param(end) );
    testModels( dirName, wavflist, trainWavflist, testWavflist, testFun, param(1:end-1) );
else
    
    dm = dir( [dirName filesep '*.model.mat'] );
    if length( dm ) == 1
        classname = strtok( dm.name, '.' );
        curDir = pwd;
        d = [curDir filesep dirName];
        if ~exist( [d filesep 'test'], 'file' )
            mkdir( d, 'test' );
        end
        cd( [d filesep 'test'] );
        testFun( classname, wavflist, trainWavflist, testWavflist, d, param );
        cd( curDir );
    elseif length( dm ) > 1
        warning( 'what?!' );
    else
        d = dir( dirName);
        d(1:2) = [];
        for di = 1 : length( d )
            if d(di).isdir
                testModels( [dirName filesep d(di).name], ...
                    wavflist, trainWavflist, testWavflist, testFun, param );
            end
        end
    end
    
end