function shrinkCacheFileSizes( cacheDir, cd_idxs )

cfgFolders = dir( cacheDir );
cfgFolders = cfgFolders([cfgFolders.isdir]);
cfgFolders(1:2) = [];

nextProgressOutStep_ii = 10;
if nargin < 2 || isempty( cd_idxs ), cd_idxs = 1 : numel( cfgFolders ); end;
for ii = cd_idxs
    if ii > numel( cfgFolders ), break; end
    if round( ii*100/numel( cfgFolders ) ) >= nextProgressOutStep_ii
        fprintf( ':' ); 
        nextProgressOutStep_ii = nextProgressOutStep_ii + 10;
    end
    cacheFiles = dir( [cacheDir filesep cfgFolders(ii).name filesep '*.wav.mat'] );
    nextProgressOutStep_jj = 10;
    for jj = 1 : numel( cacheFiles )
        if round( jj*100/numel( cacheFiles ) ) >= nextProgressOutStep_jj
            fprintf( '.' );
            nextProgressOutStep_jj = nextProgressOutStep_jj + 10;
        end
        cacheContent = load( [cacheDir filesep cfgFolders(ii).name filesep cacheFiles(jj).name] );
        cacheContentFields = fieldnames( cacheContent );
        isChanged = false;
        for kk = 1 : numel( cacheContentFields )
            if strcmpi( cacheContentFields{kk}, 'blockAnnotations' )
                baFields = fieldnames( cacheContent.blockAnnotations );
                for bb = 1 : numel( baFields )
                    if ~isstruct( cacheContent.blockAnnotations.(baFields{bb}) )
                        continue;
                    end
                    if ~isfield( cacheContent.blockAnnotations.(baFields{bb}), baFields{bb} )
                        continue;
                    end
                    if iscell( cacheContent.blockAnnotations.(baFields{bb}).(baFields{bb}) ) ...
                       && mean( cellfun( @numel, cacheContent.blockAnnotations.(baFields{bb}).(baFields{bb})(:) ) ) == 1 ...
                       && std( cellfun( @numel, cacheContent.blockAnnotations.(baFields{bb}).(baFields{bb})(:) ) ) == 0
                        cacheContent.blockAnnotations.(baFields{bb}).(baFields{bb}) = ...
                            cell2mat( cacheContent.blockAnnotations.(baFields{bb}).(baFields{bb}) );
                        isChanged = true;
                    end
                end
            end
            if ~isa( cacheContent.(cacheContentFields{kk}), 'double' ), continue; end
            cacheContent.(cacheContentFields{kk}) = single( cacheContent.(cacheContentFields{kk}) );
            isChanged = true;
        end
        if isChanged
            save( [cacheDir filesep cfgFolders(ii).name filesep cacheFiles(jj).name], '-struct', 'cacheContent' );
        end
    end
end

fprintf( '\n' );

end
