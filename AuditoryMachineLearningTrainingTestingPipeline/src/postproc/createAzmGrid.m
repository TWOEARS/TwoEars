function azmGrid = createAzmGrid( className, dispLatexCode )

azms = [0, 45, 90, 135, 180];
azmGrid = createTrTeGrid( 'trainings/azmTrain', className, azms, @azmCmpCvAndTestPerf, dispLatexCode, '\textdegree' );
