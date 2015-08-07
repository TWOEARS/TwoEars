function [b, bs, s] = dirCmpCvAndTestPerf( dirName, className, ...
                                           reqTrParam, reqTeParam, ...
                                           getTrParam, getTeParam, ...
                                           bplot )

if nargin < 7, bplot = 0; end;

b = [];
bs = [];
s = [];

dm = dir( [dirName filesep '*.model.mat'] );
if length( dm ) == 1
    cn = strtok( dm.name, '.' );
    if isempty( className ) || strcmpi( className, cn )
        mf = load( [dirName filesep dm.name] );
        trainParam = getTrParam( mf );
        if all( trainParam ~= reqTrParam ), return; end;
        if ~exist( [dirName filesep 'test'], 'file' ), return; end;
        dmtd = dir( [dirName filesep 'test'] );
        dmtd(1:2) = [];
        for di = 1 : length( dmtd )
            if dmtd(di).isdir
                dmt = dir( [dirName filesep 'test' filesep dmtd(di).name filesep '*.model.mat'] );
                mf = load( [dirName filesep 'test' filesep dmtd(di).name filesep dmt.name] );
                testParam = getTeParam( mf );
                if any( testParam == reqTeParam )
                    testDirName = [dirName filesep 'test' filesep dmtd(di).name];
                    cmpTitle = [cn ': ' num2str(trainParam) ' training; ' num2str(testParam) ' testing'];
                     [btmp,bstmp,stmp] = cmpCvAndTestPerfBestModels( dirName, testDirName, bplot, cmpTitle );
                     b = [b btmp];
                     bs = [bs bstmp];
                     s = [s stmp];
                end;
            end
        end
    end
elseif length( dm ) > 1
    warning( 'what?!' );
else
    d = dir( dirName );
    d(1:2) = [];
    for di = 1 : length( d )
        if d(di).isdir
            [btmp,bstmp,stmp] = dirCmpCvAndTestPerf( ...
                [dirName filesep d(di).name], className, ...
                reqTrParam, reqTeParam, getTrParam, getTeParam,...
                bplot );
            b = [b btmp];
            bs = [bs bstmp];
            s = [s stmp];        
        end
    end
end

