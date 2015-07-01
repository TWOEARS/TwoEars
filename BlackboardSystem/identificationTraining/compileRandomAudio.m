function description = compileRandomAudio( audioDir, sceneLength_s, fs, outputName )

soundFileNames = dir( [audioDir '/*.wav'] );

description = [];
scene = [];
currentSceneLength = 0;
while currentSceneLength < sceneLength_s
    silence = rand();
    scene = [scene; zeros(int64(silence * fs),1)];
    currentSceneLength = length(scene) / fs;
    i = randi( size(soundFileNames,1) );
    wavname = [audioDir '/' soundFileNames(i).name];
    classname = soundFileNames(i).name(1:end-6);
    soundFileNames(i) = [];
    s = audioread( wavname );
    annotFid = fopen( [wavname '.txt'] );
    if annotFid ~= -1
        annotLine = fgetl( annotFid );
        onsetOffset = sscanf( annotLine, '%f' );
        fclose( annotFid );
    else
        onsetOffset = [0 0];
    end
    description = [description; {wavname, classname, currentSceneLength+onsetOffset(1), currentSceneLength+onsetOffset(2)}];
    [~,maxchan] = max( std(s) );
    s = s(:,maxchan);
    smean = median( s );
    s = s - smean;
    smax = max( abs( s ) );
    s = s ./ smax;
    scene = [scene; s];
    currentSceneLength = length(scene) / fs;
end

if nargin >= 4
    mkdir( [audioDir '/compilations'] );
    save( [audioDir '/compilations/' outputName], 'description' );
    audiowrite( [audioDir '/compilations/' outputName '.wav'], scene, fs );
end

fig = figure( 'Name', outputName ); 
axes1 = axes( 'Parent', fig, 'YTickLabel', {}, 'YTick', zeros(1,0) );
hold( axes1,'all' );
xlabel( 'time (s)' );

x = (1:length(scene))./fs;
plot( x, scene, 'Parent', axes1, 'DisplayName', 'signal' );

l = zeros( size(x) );
for i = 1:size(description,1)
    name = description{i,2};
    on = floor( description{i,3} * fs );
    off = floor( description{i,4} * fs );
    l(on:off) = max(scene)+0.02;
    text( description{i,3}, max(scene)+0.03, name, 'Parent',axes1, 'BackgroundColor',[.6 .8 .6] );
    harea = area( [description{i,3} description{i,4}], [1 1], -1, 'LineStyle', 'none');
    set(harea, 'FaceColor', 'g')
    alpha(0.2)
end
