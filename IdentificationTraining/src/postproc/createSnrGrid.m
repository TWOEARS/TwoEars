function snrGrid = createSnrGrid( className, dispLatexCode )

snrs = [-15,-10,-5,0, 5, 10, 20, 30];
snrGrid = createTrTeGrid( 'trainings/snrTrain', className, snrs, @snrCmpCvAndTestPerf, dispLatexCode, '~db' );

