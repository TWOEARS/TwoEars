function commonParams = getCommonAFEParams( )
    commonParams = {...
        'pp_bNormalizeRMS', true, ...   % default is 0
        'pp_intTimeSecRMS', 4, ...      % default is 500E-3
        'pp_bBinauralRMS', true, ...    % default is true
        'fb_type', 'gammatone', ...
        'fb_lowFreqHz', 80, ...
        'fb_highFreqHz', 8000, ...
        'ihc_method', 'halfwave', ... % stream segr. uses 'dau'
        'ild_wSizeSec', 20E-3, ...  % DnnLoc uses 20E-3, stream segr. uses 25E-3
        'ild_hSizeSec', 10E-3, ...
        'rm_wSizeSec', 20E-3, ... % DnnLoc uses 20E-3, identification uses 25E-3
        'rm_hSizeSec', 10E-3, ... % DO NOT CHANGE -- important for gabor filters
        'rm_scaling', 'power', ... % DnnLoc uses power, identification uses magnitude
        'rm_decaySec', 8E-3, ...
        'cc_wSizeSec', 20E-3, ... % dnnLocKs uses 20E-3, stream segr. uses 25E-3
        'cc_hSizeSec', 10E-3, ... % dnnLocKs uses 10E-3, stream segr. uses 10E-2
        'cc_wname', 'hann' ...,
        'cc_maxDelaySec', 1.1E-3,... % default is 1.1E-3, stream segregation will use 1.1E-3 as well
        };
end
