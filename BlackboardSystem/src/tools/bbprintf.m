function bbprintf(obj,messageString,varargin)
% bbprintf  Displays information if the Blackboard was initialized in verbose mode
%
%   USAGE:
%       bbprintf(obj, printfString)
%       bbprintf(obj, printfString, var1, ...)
%
%   INPUT PARAMETERS:
%       obj           - object, containing .blackboard entry
%       printfString  - message to print in printf format
%       var1, ...     - variables needed for printf message

if obj.blackboard.verbosity > 0
    fprintf(['--%05.2fs ', messageString], ...
            obj.blackboard.currentSoundTimeIdx,varargin{:});
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
