function [mixture_onOffSets, target_names] = readMixtureOnOffSets(fpath_mixture)

[pathstr, fpath_mixutre_base, ~] = fileparts( fpath_mixture );
target_names = splitTargetNames(fpath_mixture);
mixture_onOffSets = cell(size(target_names));
if numel( target_names ) > 1
    for ii = 1 : numel( target_names )
        fpath_mixture_onOffSets = fullfile(pathstr, [fpath_mixutre_base, '-', target_names{ii}, '.wav']);
        mixture_onOffSets{ii} = IdEvalFrame.readOnOffAnnotations(fpath_mixture_onOffSets, true);
    end
else
    mixture_onOffSets{1} = IdEvalFrame.readOnOffAnnotations(fpath_mixture, true);
end
% remove '-' from grouped classes to match model naming convention
target_names = cellfun(@(x) strrep(x, '-', ''), ...
        target_names, 'un', false);
end