function [tExpsDescs, tVals, tExpsVals] = makeResultsTable( soundsDir, varargin )

nExperiments = nargin - 1;
modelFiles = cell( nExperiments, 1 );
experiments = cell( nExperiments, 1 );
classes = cell( nExperiments, 1 );
for ie = 1:nExperiments
    modelhash = getModelHash( varargin{ie} );
    experiments{ie} = modelhash;
    
    soundDirNames = dir( soundsDir );
    for ic = 1: size( soundDirNames, 1 )
        if strcmpi( soundDirNames(ic).name, '.' ) == 1; continue; end;
        if strcmpi( soundDirNames(ic).name, '..' ) == 1; continue; end;
        if soundDirNames(ic).isdir ~= 1; continue; end;
        currentSoundDir = [soundsDir '/' soundDirNames(ic).name '/'];
        modelfile = dir( [currentSoundDir sprintf( '*%s_model.mat', modelhash )] );
        if ~isempty( modelfile )
            classes{ie} = [classes{ie}; {['c_' soundDirNames(ic).name]}];
        end
        modelfile = {modelfile(:).name}';
        modelfile = strcat( currentSoundDir, modelfile );
        modelFiles{ie} = [modelFiles{ie}; modelfile];
    end
    
end

for ie = 1:nExperiments
    nsctmp = descriptiveStructCells( varargin{ie} );
    nsc{ie} = stringifyCell( nsctmp(:,2) );
    nscn = nsctmp(:,1);
end
tExpsDescs = table( nsc{:}, 'VariableNames', strcat( 'mh_', experiments ), 'RowNames', nscn );
tExpsDescs.Properties.DimensionNames = { 'properties' 'experiments' };
writetable( tExpsDescs, cell2mat( [soundsDir '/' strcat( experiments', '.' ) 'exps.desc.csv'] ), 'WriteRowNames', true );

rowNames = {'cv hps'; 'all data hps'; 'cv train perf'; 'cv pred gen perf'; 'hps-cv pred gen perf std'; 'cv gen perf'; 'cv gen perf std'; 'train set pred gen perf'; 'train set final perf'; 'test set final perf'};
for ie = 1:size( modelFiles,1 )
    tVals{ie} = table( 'RowNames', rowNames );
    for ic = 1:size( modelFiles{ie},1 )
        ls = load( modelFiles{ie}{ic} );
        vals = {ls.hps; ls.trHps; ls.cvtrVal; ls.predGenVal; ls.predGenValStd; ls.genVal; ls.genValStd; ls.trPredGenVal; ls.trVal; ls.testVal};
        tVals{ie}.(classes{ie}{ic}) = vals;
    end
    tVals{ie}.avgs = cell( size( rowNames ) );
    tVals{ie}.avgs(3:end) = num2cell( mean( cell2mat( tVals{ie}{3:end,1:end-1} ), 2 ) );
    tVals{ie}.stds = cell( size( rowNames ) );
    tVals{ie}.stds(3:end) = num2cell( std( cell2mat( tVals{ie}{3:end,1:end-2} ), 0, 2 ) );
end

classes = unique( vertcat( classes{:} ) );
tExpsVals = table( 'RowNames', experiments );
for ic = 1:size( classes,1 )
    tExpsVals.(classes{ic}) = cell( nExperiments, 1 );
    for ie = 1:nExperiments
        if isempty( cell2mat( strfind( tVals{ie}.Properties.VariableNames, classes{ic} ) ) ); 
            tExpsVals{ie,ic} = {0};
        else
            tExpsVals{ie,ic} = tVals{ie}.(classes{ic})(6);
        end;
    end
end

tMaxVals = cell2table( num2cell( max( cell2mat( tExpsVals{:,:}),[], 1 ) ) );
tMaxVals.Properties.VariableNames = tExpsVals.Properties.VariableNames;
tExpsVals = [tExpsVals; tMaxVals];
tExpsVals.Properties.RowNames{end} = 'best values';

tExpsVals.avgs = num2cell( mean( cell2mat( tExpsVals{:,:} ), 2 ) );
tExpsVals.stds = num2cell( std( cell2mat( tExpsVals{:,1:end-1} ), 0, 2 ) );

writetable( tExpsVals, cell2mat( [soundsDir '/' strcat( experiments', '.' ) 'exps.vals.csv'] ), 'WriteRowNames', true );

save( cell2mat( [soundsDir '/' strcat( experiments', '.' ) 'exps.mat'] ), 'tExpsDescs', 'tVals', 'tExpsVals' );
