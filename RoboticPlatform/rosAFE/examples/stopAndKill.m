function [] = stopAndKill( bass, rosAFE, client )
%STOPANDKILL [] = stopAndKill( bass, rosAFE, client )
%   Stops and kills modules properly.

rosAFE.Stop();
rosAFE.kill();
delete(rosAFE);

bass.Stop();
bass.kill();
delete(bass);

delete(client);

end