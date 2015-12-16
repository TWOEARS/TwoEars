function nn = nn_init(architecture, gauss_noise, gauss_scale, neg_bias)
%NN_INIT initialises a Feedforward Backpropagate Neural Network
% 
% nn = nn_init(architecture) returns an neural network structure with 
% n=numel(architecture) layers, architecture being an n x 1 vector of layer 
% sizes e.g. [784 100 10]
%
% Loosely based on Karel Vesely's gen_mlp_init.py
% 
%USAGE  
%  nn = nn_init(architecture, gauss_noise, gauss_scale, neg_bias)
%
%INPUT ARGUMENTS
%  architecture  : vector of layer sizes (input, hidden layers, output)
%    gauss_noise : If true, use gaussian noise for weights (default true)
%  nHiddenLayers : Scaling factor for the gaussian noise (default 0.1)
%       neg_bias : If true, use uniform [-4.1,-3.9] for bias (default true)
%
%
% Ning Ma, 29 Jan 2015
%
%

if ~exist('gauss_noise', 'var')
    gauss_noise = true;
end
if ~exist('gauss_scale', 'var')
    gauss_scale = 0.1;
end
if ~exist('neg_bias', 'var')
    neg_bias = true;
end

nn.size   = architecture;
nn.n      = numel(nn.size);

nn.activation_function              = 'sigm';       %  Activation functions of hidden layers: 'sigm' (sigmoid) or 'tanh_opt' (optimal tanh).
nn.learningRate                     = 1;            %  learning rate Note: typically needs to be lower when using 'sigm' activation function and non-normalized inputs.
nn.momentum                         = 0.5;          %  Momentum
nn.weightPenaltyL2                  = 0;            %  L2 regularization
nn.nonSparsityPenalty               = 0;            %  Non sparsity penalty
nn.sparsityTarget                   = 0.05;         %  Sparsity target
nn.inputZeroMaskedFraction          = 0;            %  Used for Denoising AutoEncoders
nn.dropoutFraction                  = 0;            %  Dropout level (http://www.cs.toronto.edu/~hinton/absps/dropout.pdf)
nn.testing                          = 0;            %  Internal variable. nntest sets this to one.
nn.output                           = 'softmax';    %  output unit 'sigm' (=logistic), 'softmax' and 'linear'

for layer = 2 : nn.n   
    % weights and weight momentum
    
    % Column 1 is the bias vector, columns 2:end are the weight matrix
    [nn.W{layer-1}, nn.vW{layer-1}] = deal(zeros(nn.size(layer), nn.size(layer-1)+1));
    
    % the weight matrix
    if gauss_noise
        nn.W{layer-1}(:,2:end) = gauss_scale .* randn(nn.size(layer), nn.size(layer-1));
    else
        nn.W{layer-1}(:,2:end) = (rand(nn.size(layer), nn.size(layer-1)) - 0.5) * 2 * 3 / sqrt(nn.size(layer-1));
    end
    
    % the bias vector
    if layer == nn.n % layer before softmax -> use zero
        nn.W{layer-1}(:,1) = 0;
    elseif neg_bias
        nn.W{layer-1}(:,1) = rand(nn.size(layer), 1) / 5 - 4.1;
    else
        nn.W{layer-1}(:,1) = 0;
    end
    
    % average activations (for use with sparsity)
    nn.p{layer}     = zeros(1, nn.size(layer));   
end


