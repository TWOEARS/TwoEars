function p = getPathPart( fullpath, baseDir )

baseDirPos = strfind( fullpath, baseDir );
if numel( baseDirPos ) > 1
    for bdp = baseDirPos
        if (bdp == 1 || ...
                fullpath(bdp-1) == '/' || ...
                fullpath(bdp-1) == '\') && ...
                (bdp+length(baseDir) == length(fullpath) ||...
                fullpath(bdp+length(baseDir)) == '/' || ...
                fullpath(bdp+length(baseDir)) == '\')
            baseDirPos = bdp;
            break;
        end
    end
end
p = fullpath(baseDirPos:end);