function [target_names] = splitTargetNames(fpath)

[~, fname, ~] = fileparts( fpath );
target_names = strsplit( fname, '_' );
end