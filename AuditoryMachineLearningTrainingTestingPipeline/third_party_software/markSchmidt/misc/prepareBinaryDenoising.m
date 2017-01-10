function [Xnode,Xedge,Y,edgeStruct,nodeMap,edgeMap,nRows,nCols] = prepareBinaryDenoising
%% Load Noisy X
fprintf('Preparing Binary Denoising data.');
load totalLabels_synIm1
load dataMat_multSyn1N90
images = squeeze(dataMat);
labels = totalLabels;
labels(labels==-1) = 2;
labels(labels==0) = 2;

nSamples = 50;
nRows = 64;
nCols = 64;
nNodes = nRows*nCols;
nStates = 2;

Xnode = zeros(nSamples,1,nNodes);
Y = zeros(nSamples,nNodes);
for i = 1:nSamples
	y = labels(:,:,i);
	Y(i,:) = y(:);
	x = images(:,:,i);
	Xnode(i,1,:) = x(:);
end

%% Make edgeStruct

fprintf('.');
adj = sparse(nNodes,nNodes);

% Add Down Edges
ind = 1:nNodes;
exclude = sub2ind([nRows nCols],repmat(nRows,[1 nCols]),1:nCols); % No Down edge for last row
ind = setdiff(ind,exclude);
adj(sub2ind([nNodes nNodes],ind,ind+1)) = 1;

% Add Right Edges
ind = 1:nNodes;
exclude = sub2ind([nRows nCols],1:nRows,repmat(nCols,[1 nRows])); % No right edge for last column
ind = setdiff(ind,exclude);
adj(sub2ind([nNodes nNodes],ind,ind+nRows)) = 1;

% Add Up/Left Edges
adj = adj+adj';
edgeStruct = UGM_makeEdgeStruct(adj,nStates);

%% Make Xnode, Xedge, infoStruct, initialize weights

fprintf('.');

tied = 1;
ising = 1;

% Standardize Columns, make edge features
Xnode = UGM_standardizeCols(Xnode,tied);
globalFeatures = 0;
Xedge = UGM_makeEdgeFeatures(Xnode,edgeStruct.edgeEnds,globalFeatures);

% Add biases
Xnode = [ones(nSamples,1,nNodes) Xnode];
Xedge = [ones(nSamples,1,edgeStruct.nEdges) abs(Xedge(:,1,:)-Xedge(:,2,:))];

% Make infoStruct
[nodeMap,edgeMap] = UGM_makeCRFmaps(Xnode,Xedge,edgeStruct,ising,tied,0);
Y = int32(Y);
fprintf('Done\n');