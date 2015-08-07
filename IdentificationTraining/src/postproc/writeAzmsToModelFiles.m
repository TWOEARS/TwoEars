dirName = './azmTrain/azmTrain2';

dc = dir( [dirName filesep '*'] );
for dci = 1 : length( dc )
    d = dir( [dirName filesep dc(dci).name filesep 'Training.*']);
    azms = [0 45 90 135 180];
    for di = 1 : length( d )
        de = dir( [dirName filesep dc(dci).name filesep d(di).name filesep '*.model.mat'] );
        if isempty( de ), continue; end;
        azm = azms(di);
        save( [dirName filesep dc(dci).name filesep d(di).name filesep de.name], 'azm', '-append' );
    end
end
