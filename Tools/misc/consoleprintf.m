function count = consoleprintf(style,format,varargin)
% CONSOLEPRINTF displays styled formatted text in the Command Window
%
% Syntax:
%    count = consoleprintf(style,format,...)
%
% Description:
%    CONSOLEPRINTF processes the specified text using the exact same FORMAT
%    arguments accepted by the built-in SPRINTF and FPRINTF functions.
%
%    It is a subfunction called from CPRINTF for non-desktop versions of Matlab.
%    See the help of CPRINTF for a detailed description.
%

% AUTHOR: Hagen Wierstorf

  % The following is for debug use only:
  if ~exist('el','var') || isempty(el),  el=handle([]);  end  %#ok mlint short-circuit error ("used before defined")
  if nargin<1, showDemo(); return;  end
  if isempty(style),  return;  end
  if all(ishandle(style)) && length(style)~=3
      dumpElement(style);
      return;
  end

  % Process the text string
  if nargin<2, format = style; style='text';  end
  %error(nargchk(2, inf, nargin, 'struct'));
  %str = sprintf(format,varargin{:});

  % Get the normalized style name and underlining flag
  [underlineFlag, boldFlag, style] = processStyleInfo(style);

  % In compiled mode
  try useDesktop = usejava('desktop'); catch, useDesktop = false; end
  if isdeployed | ~useDesktop %#ok<OR2> - for Matlab 6 compatibility

      % See: http://misc.flogisoft.com/bash/tip_colors_and_formatting
      % for a discussion of the color codes and resettings to normal
      NORMAL='\033[00;39;39m'; % if you have another normal setting place it here. 
                               % For example I use bold terminal text and a different white color: NORMAL='\033[01;37;37m';
      BOLD='\033[1m';
      UNDERLINE='\033[4m';
      % Resetting underline and bold after applying them
      if underlineFlag
          format = [UNDERLINE format '\033[24m'];
      end
      if boldFlag
          format = [BOLD format '\033[21m'];
      end
      format = [NORMAL style format NORMAL];
    
      count1 = fprintf(format,varargin{:});
  else
      % Else (Matlab desktop mode)
      count1 = cprintf(style,format,varargin{:});
  end

  if nargout
      count = count1;
  end
  return;  % debug breakpoint

% Process the requested style information
function [underlineFlag,boldFlag,style] = processStyleInfo(style)
  underlineFlag = 0;
  boldFlag = 0;
  % Linux color commands
  % See: http://tldp.org/LDP/abs/html/colorizing.html#AEN20327
  % Also see: http://wiki.bash-hackers.org/scripting/terminalcodes
  BLACK='\033[30;30m';
  RED='\033[31;31m';
  GREEN='\033[32;32m';
  YELLOW='\033[33;33m';
  BLUE='\033[34;34m';
  MAGENTA='\033[35;35m';
  CYAN='\033[36;36m';
  WHITE='\033[37;37m';


  % First, strip out the underline/bold markers
  if ischar(style)
      % Styles containing '-' or '_' should be underlined (using a no-target hyperlink hack)
      underlineIdx = (style=='-') | (style=='_');
      if any(underlineIdx)
          underlineFlag = 1;
          style = style(~underlineIdx);
      end

      % Check for bold style (only if not underlined)
      boldIdx = (style=='*');
      if any(boldIdx)
          boldFlag = 1;
          style = style(~boldIdx);
      end
      if underlineFlag && boldFlag
          warning('YMA:consoleprintf:BoldUnderline','Matlab does not support both bold & underline')
      end

      % Check if the remaining style sting is a numeric vector
      if any(style==' ' | style==',' | style==';')
          style = str2num(style);
      end
  end

  % Style = valid matlab RGB vector
  if isnumeric(style) && length(style)==3 && all(style<=1) && all(abs(style)>=0)
      error('YMA:consoleprintf:InvalidStyle','consoleprintf do only support color names at the moment')
      if any(style<0)
          underlineFlag = 1;
          style = abs(style);
      end
      style = getColorStyle(style);

  elseif ~ischar(style)
      error('YMA:cprintf:InvalidStyle','Invalid style - see help section for a list of valid style values')

  % Style name
  else
      % Try case-insensitive partial/full match with the accepted style names
      validStyles = {'Text','Keywords','Comments','Strings','UnterminatedStrings','SystemCommands','Errors', ...
                     'Black','Cyan','Magenta','Blue','Green','Red','Yellow','White', ...
                     'Hyperlinks'};
      matches = find(strncmpi(style,validStyles,length(style)));

      % No match - error
      if isempty(matches)
          error('YMA:cprintf:InvalidStyle','Invalid style - see help section for a list of valid style values')

      % Too many matches (ambiguous) - error
      elseif length(matches) > 1
          error('YMA:cprintf:AmbigStyle','Ambiguous style name - supply extra characters for uniqueness')

      % Regular text
      elseif matches == 1
          style = '';

      elseif matches == 2 | matches == 11
          style = BLUE;

      elseif matches == 3 | matches == 12
          style = GREEN;

      elseif matches == 4 | matches == 10
          style = MAGENTA;

      elseif matches == 5 | matches == 13
          style = RED;

      elseif matches == 6 | matches == 14
          style = YELLOW;

      elseif matches == 7
          style = RED;
          boldFlag = 1;

      elseif matches == 8
          style = BLACK;

      elseif matches == 9
          style = CYAN;

      elseif matches == 15
          style = WHITE;

      % Hyperlink
      else
          style = BLUE; 
          underlineFlag = 1;
      end
  end

% Convert a Matlab RGB vector into a known style name (e.g., '[255,37,0]')
function styleName = getColorStyle(rgb)
  intColor = int32(rgb*255);
  javaColor = java.awt.Color(intColor(1), intColor(2), intColor(3));
  styleName = sprintf('[%d,%d,%d]',intColor);
  com.mathworks.services.Prefs.setColorPref(styleName,javaColor);

% Fix a bug in some Matlab versions, where the number of URL segments
% is larger than the number of style segments in a doc element
function delta = getUrlsFix(docElement)  %#ok currently unused
  tokens = docElement.getAttribute('SyntaxTokens');
  links  = docElement.getAttribute('LinkStartTokens');
  if length(links) > length(tokens(1))
      delta = length(links) > length(tokens(1));
  else
      delta = 0;
  end

% Utility function to convert matrix => cell
function cells = m2c(data)
  %datasize = size(data);  cells = mat2cell(data,ones(1,datasize(1)),ones(1,datasize(2)));
  cells = num2cell(data);

% Display the help and demo
function showDemo()
  fprintf('consoleprintf displays formatted text in the Command Window.\n\n');
  fprintf('Syntax: count = consoleprintf(style,format,...);  help consoleprintf for details.\n\n');
  url = 'http://UndocumentedMatlab.com/blog/cprintf/';
  fprintf('Technical description: %s\n\n',url);
  fprintf('Demo:\n\n');
  boldFlag = 1;
  s = ['consoleprintf(''text'',    ''regular black text'');' 10 ...
       'consoleprintf(''hyper'',   ''followed %s'',''by'');' 10 ...
       'consoleprintf(''key'',     ''%d colored'',' num2str(4+boldFlag) ');' 10 ...
       'consoleprintf(''-comment'',''& underlined'');' 10 ...
       'consoleprintf(''err'',     ''elements:\n'');' 10 ...
       'consoleprintf(''cyan'',    ''cyan'');' 10 ...
       'consoleprintf(''_green'',  ''underlined green'');' 10 ...
       'consoleprintf(''-magenta'',  ''underlined magenta'');' 10 ...
       'consoleprintf(''yellow'', ''and multi-\nline yellow\n'');' 10];
   if boldFlag
       % In R2011b+ the internal bug that causes the need for an extra space
       % is apparently fixed, so we must insert the sparator spaces manually...
       % On the other hand, 2011b enables *bold* format
       s = [s 'consoleprintf(''*blue'',   ''and *bold*\n'');' 10];
       s = strrep(s, ''')',' '')');
       s = strrep(s, ''',5)',' '',5)');
       s = strrep(s, '\n ','\n');
   end
   disp(s);
   eval(s);


%%%%%%%%%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%%%%%
% - Fix: Remove leading space char (hidden underline '_')
% - Fix: Find workaround for multi-line quirks/limitations
% - Fix: Non-\n-terminated segments are displayed as black
% - Fix: Check whether the hyperlink fix for 7.1 is also needed on 7.2 etc.
% - Enh: Add font support
