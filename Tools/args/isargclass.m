function isargclass(classname,varargin)
%ISARGCLASS tests if the given arg is an object of a specified class
%
%   Usage: isargclass(classname,args)
%
%   Input options:
%       classname   - classname
%       args        - list of args
%
%   ISARGCLASS tests if the given arg is an object of a specified class

%% ===== Checking of input  parameters ===================================
if nargin<2
    error('%s: Two input arguments required at least.',upper(mfilename));
end

%% ===== Checking for equal size =========================================
for ii = 1:nargin-1
    if ~isa(varargin{ii},classname)
        error(['%s: at least one input is not an object of the specified',...
          ' class (%s)'],upper(mfilename),classname);
    end
end
end