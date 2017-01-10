function idModels = setDefaultIdModels()

idModels(1).name = 'speech';
idModels(2).name = 'keyboard';
idModels(3).name = 'switch';
idModels(4).name = 'knock';
idModels(5).name = 'clearthroat';
idModels(6).name = 'alert';
[idModels.dir] = deal( fullfile('models', 'test_1vsAll_training') );
