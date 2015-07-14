function description = makeTestScene( idste, lte, sceneLength_s )

fs = 44100;

testWavsP = unique(idste(lte==+1));
lengthtestWavsP = length(testWavsP);
testWavsN = unique(idste(lte==-1));

description = [];
pdesc = [];
scene = [];
currentSceneLength = 0;
pCasesUsed = [];
nCasesUsed = [];
while currentSceneLength < sceneLength_s
    silence = rand();
    scene = [scene; zeros(int64(silence * fs),1)];
    currentSceneLength = length(scene) / fs;
    if ~isempty(testWavsP) && ...
      (rand() > (0.66 + 0.5*(length( pCasesUsed ) - length( nCasesUsed ))/lengthtestWavsP ))
        pCasesUsed = [pCasesUsed randi(size(testWavsP,1))];
        wavname = testWavsP{pCasesUsed(end)};
        testWavsP(pCasesUsed(end)) = [];
    else
        nCasesUsed = [nCasesUsed randi(size(testWavsN,1))];
        wavname = testWavsN{nCasesUsed(end)};
        testWavsN(nCasesUsed(end)) = [];
    end
    s = audioread( wavname );
    annotFid = fopen( [wavname '.txt'] );
    annotLine = fgetl( annotFid );
    onsetOffset = sscanf( annotLine, '%f' );
    fclose( annotFid );
    description = [description; {wavname, currentSceneLength+onsetOffset(1), currentSceneLength+onsetOffset(2)}];
    pdesc = [pdesc; currentSceneLength+onsetOffset(1), currentSceneLength+onsetOffset(2)];
    [~,maxchan] = max( std(s) );
    s = s(:,maxchan);
    scene = [scene; s];
    currentSceneLength = length(scene) / fs;
end

audiowrite( 'niMix.wav', scene, fs );

x = (1:floor(fs*sceneLength_s))./fs;
fig1 = figure; 
hold all;
plot( x,scene(1:length(x)) );
title( 'testscene' );

l = zeros( size(x) );
pdesc = floor(pdesc * fs);
for i = 1:size(pdesc,1)
    l(pdesc(i,1):pdesc(i,2)) = max(scene)+0.02;
end
plot( x, l(1:length(x)) );

save( 'niMixDesc.mat', 'description', 'pdesc' );
saveas( fig1, 'niMixFig', 'fig' );
