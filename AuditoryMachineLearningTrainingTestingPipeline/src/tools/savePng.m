function savePng( saveTitle )

saveTitle = strrep( saveTitle, ' ', '_' );
saveTitle = strrep( saveTitle, '&', '+' );
saveTitle = strrep( saveTitle, ':', '-' );
saveTitle = strrep( saveTitle, ';', '-' );
saveTitle = strrep( saveTitle, ',', '.' );
if ~exist( 'autoPics', 'file' )
    mkdir( 'autoPics' );
end
export_fig( ['autoPics' filesep saveTitle '.png'], '-transparent' );

savefig( ['autoPics' filesep saveTitle '.fig'] );