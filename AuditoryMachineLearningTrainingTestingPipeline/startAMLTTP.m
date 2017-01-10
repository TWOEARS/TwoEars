function startAMLTTP
% This function initialises the path variables that are needed for running
% the Auditory Machine Learning Training and Testing Pipeline 
% of the Two!Ears Blackboard System
% module

startTwoEars( 'AMLTTP.xml' );

basePath = fileparts(mfilename('fullpath'));

% Add all relevant folders to the matlab search path
addPathsIfNotIncluded( ...
    [ strsplit( genpath( fullfile( basePath, 'src') ), pathsep ) ...
      strsplit( genpath( fullfile( basePath, 'third_party_software') ), pathsep )] ...
      );
