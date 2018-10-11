function resc = addDpiToResc( resc, assignments, bapi )

if isempty( bapi ), return; end

ci = zeros( numel( bapi ), 1 );
for aa = 1:4 % 1: TP, 2: TN, 3: FP, 4: FN
    ci = ci + aa*[assignments{aa}];
end

bapiFields = fieldnames( bapi );
bapiFields = [{'counts'}; bapiFields];
if isfield( resc, 'id' ) && ~isempty( resc.id )
    if numel( bapiFields ) ~= numel( fieldnames( resc.id ) ) || ...
       ~all( strcmpi( bapiFields, fieldnames( resc.id ) ) )
        error( 'AMLTTP:apiUsage', 'existing RESC structure differs from BAPI to be added' );
    end
else
    resc.id.counts = 1;
end

C = zeros( numel( bapi ), numel( bapiFields ) );
C(:,1) = ci;
for ii = 2 : numel( bapiFields )
    if isfield( resc.id, bapiFields{ii} )
        ii_ = resc.id.(bapiFields{ii});
    else
        ii_ = ii;
    end
    C(:,ii_) = cat( 1, bapi.(bapiFields{ii}) );
    resc.id.(bapiFields{ii}) = ii_;
end

[C,~,ic] = unique( C, 'rows' );
paramFactor = arrayfun( @(x)(sum( x == ic )), 1:size( C, 1 ) );
resc = resc.addData( C, paramFactor', true );

end