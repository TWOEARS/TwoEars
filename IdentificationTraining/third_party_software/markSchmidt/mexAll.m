% minFunc
fprintf('Compiling minFunc files...\n');
mex -outdir minFunc minFunc/mcholC.c
mex -outdir minFunc minFunc/lbfgsC.c
mex -outdir minFunc minFunc/lbfgsAddC.c
mex -outdir minFunc minFunc/lbfgsProdC.c

% L1General Group
fprintf('Compiling L1GeneralGroup files...\n');
mex -outdir L1GeneralGroup/mex L1GeneralGroup/mex/projectRandom2C.c
mex -outdir L1GeneralGroup/mex L1GeneralGroup/mex/auxGroupLinfProjectC.c
mex -outdir L1GeneralGroup/mex L1GeneralGroup/mex/auxGroupL2ProjectC.c

% Misc
mex -outdir misc misc/sampleDiscrete_cumsumC.c
