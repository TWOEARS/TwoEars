function generateGmtkParameters(gmtkEngine, numAzimuths)
%generateGmtkParameters generates parameters needed by GMTK
%   This script generates initial graphical model parameters needed by GMTK
%   before the graphical model can be trained. Note this is a basic attempt
%   to automate parameter generation which is often difficult to do because
%   of the GMTK flexibility. You may have to manually set the parameters
%   sometimes.
%
%   Ning Ma, 11 August 2014
%   n.ma@sheffield.ac.uk
%

    % Generate trainable graph structure
    generateStructure(gmtkEngine.gmStruct, gmtkEngine.dimFeatures, numAzimuths);
    
    % Generate trainable graph structure
    generateTrainableStructure(gmtkEngine.gmStructTrainable, gmtkEngine.dimFeatures, numAzimuths);
    
    % Generate master file
    generateMasterParams(gmtkEngine.inputMaster, numAzimuths);

    % Generate trainable master file
    generateTrainableMasterParams(gmtkEngine.inputMasterTrainable, gmtkEngine.dimFeatures, numAzimuths);
end

function generateStructure(outfn, dimFeatures, numAzimuths)
% Generate trainable paramerters
    fid = fopen(outfn, 'w');
    if fid < 0
        error('Cannot open %s', outfn);
    end
    fprintf(fid, 'GRAPHICAL_MODEL Localisation\n\n');
    
    for f = 0:1
        fprintf(fid, 'frame: %d {\n\n', f);
        fprintf(fid, '   variable: azimuth {\n');
        fprintf(fid, '      type: discrete hidden cardinality %d;\n', numAzimuths);
        fprintf(fid, '      switchingparents: nil;\n');
        fprintf(fid, '      conditionalparents: nil using DenseCPT("azimuthCPT");\n');
        fprintf(fid, '   }\n');

        fprintf(fid, '   variable : obs {\n');
        fprintf(fid, '      type: continuous observed 0:%d;\n', dimFeatures-1);
        fprintf(fid, '        switchingparents: nil;\n');
        fprintf(fid, '        conditionalparents: azimuth(0) using mixture\n');
        fprintf(fid, '           collection("colObs")\n');
        fprintf(fid, '           mapping("directMappingWithOneParent");\n');
        fprintf(fid, '   }\n\n');
        fprintf(fid, '}\n\n');
    end
    fprintf(fid, 'chunk 1:1\n\n');
    fclose(fid);
end

function generateTrainableStructure(outfn, dimFeatures, numAzimuths)
% Generate trainable paramerters
    fid = fopen(outfn, 'w');
    if fid < 0
        error('Cannot open %s', outfn);
    end
    fprintf(fid, 'GRAPHICAL_MODEL Localisation\n\n');
    
    for f = 0:1
        fprintf(fid, 'frame: %d {\n\n', f);
        fprintf(fid, '   variable: azimuth {\n');
        fprintf(fid, '      type: discrete observed %d:%d cardinality %d;\n', dimFeatures, dimFeatures, numAzimuths);
        fprintf(fid, '      switchingparents: nil;\n');
        fprintf(fid, '      conditionalparents: nil using DenseCPT("azimuthCPT");\n');
        fprintf(fid, '   }\n');

        fprintf(fid, '   variable : obs {\n');
        fprintf(fid, '      type: continuous observed 0:%d;\n', dimFeatures-1);
        fprintf(fid, '        switchingparents: nil;\n');
        fprintf(fid, '        conditionalparents: azimuth(0) using mixture\n');
        fprintf(fid, '           collection("colObs")\n');
        fprintf(fid, '           mapping("directMappingWithOneParent");\n');
        fprintf(fid, '   }\n\n');
        fprintf(fid, '}\n\n');
    end
    fprintf(fid, 'chunk 1:1\n\n');
    fclose(fid);
end

function generateMasterParams(outfn, numAzimuths)
% Generate non-trainable paramerters
    fid = fopen(outfn, 'w');
    if fid < 0
        error('Cannot open %s', outfn);
    end
    print_section_title(fid, 'Parameter file');
    print_non_trainable_params(fid, numAzimuths);
    fclose(fid);
end

function generateTrainableMasterParams(outfn, dimFeatures, numAzimuths)
% Generate trainable paramerters
    fid = fopen(outfn, 'w');
    if fid < 0
        error('Cannot open %s', outfn);
    end

    print_section_title(fid, 'Parameter file');

    % Print Dense CPTs
    print_section_title(fid, 'CPTs');
    fprintf(fid, 'DENSE_CPT_IN_FILE inline\n');
    fprintf(fid, '1 %% num DenseCPTs\n');

    fprintf(fid, '0 azimuthCPT %% num, name\n');
    fprintf(fid, '0 %d %% num parents, num values\n', numAzimuths);
    for n=1:numAzimuths
        fprintf(fid, '%.8f ', 1/numAzimuths);
    end
    fprintf(fid, '\n');

    % Print Gaussians
    print_section_title(fid, 'Gaussians');
    fprintf(fid, '%% Discrete PMFs\n');
    fprintf(fid, 'DPMF_IN_FILE inline %d\n', numAzimuths);
    for n=0:numAzimuths-1
       fprintf(fid, '%d %% pmf %d\n', n, n);
       fprintf(fid, 'mx%d 1 %% name, cardinality\n', n);
       fprintf(fid, '1.0\n');
    end
    fprintf(fid, '\n');
    fprintf(fid, '%% Means\n');
    fprintf(fid, 'MEAN_IN_FILE inline %d\n', numAzimuths);
    for n=0:numAzimuths-1
       fprintf(fid, '%d mean%d %% num, name\n', n, n);
       fprintf(fid, '%d %% dimensionality\n', dimFeatures);
       for m=1:dimFeatures
        fprintf(fid, '0.0 ');
       end
       fprintf(fid, '\n');
    end
    fprintf(fid, '\n');
    fprintf(fid, '%% Variances\n');
    fprintf(fid, 'COVAR_IN_FILE inline %d\n', numAzimuths);
    for n=0:numAzimuths-1
       fprintf(fid, '%d covar%d %% num, name\n', n, n);
       fprintf(fid, '%d %% dimensionality\n', dimFeatures);
       for m=1:dimFeatures
        fprintf(fid, '0.1 ');
       end
       fprintf(fid, '\n');
    end
    fprintf(fid, '\n');
    fprintf(fid, '%% Gaussian components\n');
    fprintf(fid, 'MC_IN_FILE inline %d\n', numAzimuths);
    for n=0:numAzimuths-1
       fprintf(fid, '%d %d 0 gc%d %% num, dim, type, name\n', n, dimFeatures, n);
       fprintf(fid, 'mean%d covar%d\n', n, n);
    end
    fprintf(fid, '\n');
    fprintf(fid, '%% Gaussian mixtures\n');
    fprintf(fid, 'MX_IN_FILE inline %d\n', numAzimuths);
    for n=0:numAzimuths-1
       fprintf(fid, '%d %d gm%d 1 %% num, dim, name, num comp\n', n, dimFeatures, n);
       fprintf(fid, 'mx%d gc%d\n', n, n);
    end
    fprintf(fid, '\n');

    % Print non-trainable params
    print_non_trainable_params(fid, numAzimuths);
    fclose(fid);
    
end

function print_section_title(fid, txt)
    fprintf(fid, '\n%%-----------------------------------------\n');
    fprintf(fid, '%% %s\n', txt);
    fprintf(fid, '%%-----------------------------------------\n');
end

function print_non_trainable_params(fid, numAzimuths)
    print_section_title(fid, 'Name collections');
    fprintf(fid, 'NAME_COLLECTION_IN_FILE inline 1\n');
    
    fprintf(fid, '0 colObs %% num, name\n');
    fprintf(fid, '%d\n', numAzimuths);
    for n=0:numAzimuths-1
       fprintf(fid, 'gm%d ', n);
    end
    fprintf(fid, '\n');
    
    print_section_title(fid, 'Decision trees');
    fprintf(fid, 'DT_IN_FILE inline 1\n');
    fprintf(fid, '0 directMappingWithOneParent %% num, name\n');
    fprintf(fid, '1 %% one parent\n');
    fprintf(fid, '0 1 default\n');
    fprintf(fid, '   -1 {(p0)} %% just copy value of parent\n');
    fprintf(fid, '\n');
end


