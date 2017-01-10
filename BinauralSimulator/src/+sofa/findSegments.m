function [seg_begin, seg_end, seg_length] = findSegments(idx)
    % find gaps in indices
    gdx = find( idx(2:end) - idx(1:end-1) ~= 1);
    % 
    seg_begin = [1; gdx+1];
    seg_end = [gdx; length(idx)];
    seg_length = seg_end - seg_begin + 1;    
end
