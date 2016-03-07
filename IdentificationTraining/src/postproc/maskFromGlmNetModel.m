function [ mask ] = maskFromGlmNetModel( res_path, thres )
%MASKFROMGLMNETMODEL extracts a feature mask from GlmNetModel results
%   Detailed explanation goes here

%% init
if nargin < 2, thres=0.0; end;
assert(exist(res_path,'dir')==7);
res_path_idx = what(res_path);
assert(~isempty(res_path_idx.mat)>0);
arc_path = [res_path '/' res_path_idx.mat{1}];
arc_hndl = load(arc_path, 'model');
assert(isa(arc_hndl.model, 'models.GlmNetModel'));

% find coefficients
coefs = glmnetCoef( arc_hndl.model.model, arc_hndl.model.lambda );
mask = coefs(2:end) > thres;

end
