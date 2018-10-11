function varargout = applyIfNempty( x, fun )

if isempty( x )
    varargout(1:nargout) = cell( 1, nargout );
    return;
end

[varargout{1:nargout}] = fun( x );

end