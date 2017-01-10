function meanval = libsvmCVext( y, x, ids, param, nr_fold, bestVal )

[lfolds, dfolds, ~] = splitDataPermutation( y, x, ids, nr_fold );

vals = ones( nr_fold, 1 );
trVals = ones( nr_fold, 1 );
for i = 1:nr_fold % Cross training : folding
    tridx = 1:nr_fold;
    tridx(i) = [];

    [model, translators, factors, trVals(i)] = libsvmtrainExt( vertcat( lfolds{tridx} ), vertcat( dfolds{tridx} ), param, 0 );
    disp( 'testing performance:' );
    [~, vals(i), ~] = libsvmPredictExt( lfolds{i}, dfolds{i}, model, translators, factors, 0 );
  
    meanval = mean(vals);
    meantrval = mean(trVals);
    if (i < nr_fold) && (meanval <= bestVal)
        disp( 'CV run cannot reach best value any more, aborting' );
        break;
    end
end

fprintf( 'Average training performance after CV: %g\n', meantrval );
fprintf( 'Average generalization performance after CV: %g\n', meanval );
