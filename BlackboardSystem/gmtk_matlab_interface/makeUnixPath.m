function unixPath = makeUnixPath(winPath)
% Transform Win-style path into unix format

unixPath = winPath;
unixPath((unixPath == '\') == 1) = '/';

end

