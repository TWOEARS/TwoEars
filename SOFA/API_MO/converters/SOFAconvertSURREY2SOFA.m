function Obj=SOFAconvertSURREY2SOFA(directory)
%% Get an empy conventions structure
Obj = SOFAgetConventions('SingleRoomDRIR');

%%
dir_struct = dir(directory);

selector = ~[dir_struct.isdir];

Obj.Data.IR = [];
Obj.SourcePosition = [];

for idx=find(selector)
  [A, c] = sscanf(dir_struct(idx).name,'CortexBRIR_0_%ds_%ddeg_%dk.wav');
  
  if (c < 3) continue; end
  
  %% Source Position
  [x, y, z] = sph2cart(-deg2rad(A(2)), 0, 1.0);
  Obj.SourcePosition = [Obj.SourcePosition; [x, y, z]];  
  
  %% Fill data with data
  [data, fs] = wavread(fullfile(directory, dir_struct(idx).name));
  
  if (fs ~= A(3)*1000)
    error(['mismatch between sample rate of wav file and sample rate in' ...
      'file name']);
  end
  
  Obj.Data.IR = [Obj.Data.IR; permute(data, [3,2,1])];
  Obj.Data.SamplingRate = A(3)*1000;
end

%% Fill the mandatory variables
% SingleRoomDRIR
% === Source ===
Obj.SourceView = -Obj.SourcePosition;
Obj.SourcePosition = Obj.SourcePosition.*1.5;
Obj.SourceUp = [0 0 1];

% === Listener ===
Obj.ListenerView = [0,0,0];
Obj.ListenerUp = [0 0 1];
% Receiver position for a dummy head (imported from SimpleFreeFieldHRIR)
Obj.ReceiverPosition = [0,-0.09,0; 0,0.09,0];

%% Fill with attributes
Obj.GLOBAL_ListenerShortName = 'Cortex';
Obj.GLOBAL_History='Converted from Surrey .wav files';
%Obj.GLOBAL_Comment = irs.description;
Obj.GLOBAL_License = 'Unknown, Restrictive';
Obj.GLOBAL_ApplicationName = 'BRIR from University of Surrey';
Obj.GLOBAL_ApplicationVersion = '1.0';
Obj.GLOBAL_AuthorContact = 'c.hummersone@surrey.ac.uk';
Obj.GLOBAL_References = [''];
Obj.GLOBAL_Origin = 'University of Surrey';
Obj.GLOBAL_Organization = 'Institute of Sound Recording';
Obj.GLOBAL_DatabaseName = 'Surrey Database';
Obj.GLOBAL_Title = 'Binaural Impulse Response Measurements';
Obj.GLOBAL_ListenerDescription = 'Cortex Instruments Mk.2 HATS';
Obj.GLOBAL_ReceiverDescription = '';
Obj.GLOBAL_SourceDescription = 'Genelec 8020A';
Obj.GLOBAL_RoomType = 'reverberant';
Obj.GLOBAL_RoomDescription = ['RT60(BS EN ISO 3382)= ', num2str(A(1)/100, '%2.2f'), 's'];

%% Update dimensions
Obj=SOFAupdateDimensions(Obj);

end