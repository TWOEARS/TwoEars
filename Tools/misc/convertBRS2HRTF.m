function convertBRS2HRTF(fileList)
%CONVERTBRS2HRTF converst all brs files of the given fileList to HRTFs
%
% Usage: convertBRS2HRTF(fileList);
%
% If you want to use BRS wav files with WP1 you have to convert them first
% into the right HRTF wav format by reversing the channel order of the 720
% channels (2 for every 1deg).
% BRS files are used togetether with the SoundScape Renderer in experiments
% including prerendered impulse responses and head-tracking of the listener.
%
% Be careful, because you can also apply this script to an HRTF and the output
% will then be a BRS file.
%
% DEPENDENCY: WP1, Tools

% AUTHOR: Hagen Wierstorf

% Add the twoears-tools
%run('../../../twoears-tools/src/startTools');
%run('../../../twoears-wp1/src/startWP1');

% Read file list
[fileNames,nFiles] = readFileList(fileList);
for ii=1:nFiles
    [brs,fs,bits] = wavread(fileNames{ii});
    hrtf = brs2hrtf(brs);
    wavwrite(hrtf,fs,bits,fileNames{ii});
end

function hrtf = brs2hrtf(brs)
    if size(brs,2)~=720
        error('A BRS impulse response has to have 720 channels');
    end
    % Rearrange channels
    hrtf = zeros(size(brs));
    hrtf(:,1:2:719) = brs(:,719:-2:1);
    hrtf(:,2:2:720) = brs(:,720:-2:1);
end
