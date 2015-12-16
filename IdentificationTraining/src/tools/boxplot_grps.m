function boxplot_grps( labels, cgroup, nvPairs, varargin )

vars = cell( size( varargin ) );
grps = cell( size( varargin ) );
cgrps = cell( size( varargin ) );
setlabels = isempty( labels );
for ii = 1 : numel( varargin )
    vars{ii} = varargin{ii};
    grps{ii} = ii * ones( size( vars{ii} ) );
    if ~isempty( cgroup ), cgrps{ii} = cgroup(ii) * ones( size( vars{ii} ) ); end
    if setlabels
        labels{ii} = inputname( ii + 2 );
    end
    labels{ii} = labels{ii};
end
%if isempty( cgroup ), cgrps = gt; end
    
if isempty( nvPairs )
    nvPairs = {
         'notch', 'on', ...
         'whisker', inf, ...
         'widths', 0.8,...
         };
end
    
boxplot( [vars{:}], ...
         [grps{:}], ...
         'labels', labels,...
         'colorgroup', [cgrps{:}],...
         'labelorientation', 'inline',...
         nvPairs{:} ...
         )

