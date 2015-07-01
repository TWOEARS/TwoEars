function eq = isequalDeepCompare( a, b )

if ~isequal( class( a ), class( b ) ), eq = false; return; end

if isa( a, 'struct' )
    na = numel( a );
    nb = numel( b );
    if na ~= nb, eq = false; return; end
    sortedFieldnamesA = sort( fieldnames( a ) );
    sortedFieldnamesB = sort( fieldnames( b ) );
    if ~isequal( sortedFieldnamesA, sortedFieldnamesB ), eq = false; return; end
    for nn = 1 : na
        for ff = 1 : length( sortedFieldnamesA )
            if ~isequalDeepCompare( a(nn).(sortedFieldnamesA{ff}), ...
                                    b(nn).(sortedFieldnamesB{ff}) )
                eq = false; return; 
            end
        end
    end
elseif iscell( a )
    na = numel( a );
    nb = numel( b );
    if na ~= nb, eq = false; return; end
    for nn = 1 : na
        if ~isequalDeepCompare( a{nn}, b{nn} ), eq = false; return; end
    end
% elseif isobject( a ) % only compares public (readable) properties
%     na = numel( a );
%     nb = numel( b );
%     if na ~= nb, eq = false; return; end
%     sortedPropnamesA = sort( properties( a ) );
%     sortedPropnamesB = sort( properties( b ) );
%     if ~isequal( sortedPropnamesA, sortedPropnamesB ), eq = false; return; end
%     for nn = 1 : na
%         for ff = 1 : length( sortedPropnamesA )
%             if ~isequalDeepCompare( a(nn).(sortedPropnamesA{ff}), ...
%                                     b(nn).(sortedPropnamesB{ff}) )
%                 eq = false; return; 
%             end
%         end
%     end
else
    if ~isequal( a, b ), eq = false; return; end
end

eq = true;
