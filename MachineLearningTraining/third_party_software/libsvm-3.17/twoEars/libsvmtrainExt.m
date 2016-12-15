function [model, translators, factors, trVal] = libsvmtrainExt( y, x, paramStr, calcProbs )

%% calculate proportion of positive examples / the respective weight

ypShare = (mean(y) + 1 ) * 0.5;
cp = (1-ypShare)/ypShare;

%% balance data in case of probability model creation

if calcProbs
    x = [x(y == -1,:); repmat( x(y == +1,:), floor(cp), 1)];
    y = [y(y == -1); repmat( y(y == +1), floor(cp), 1)];
    cp = 1;
end

%% modify paramStr to this weight

cpPos = strfind( paramStr, '-w1 ' );
if ~isempty( cpPos )
   str1 = paramStr(1:cpPos+2);
   cpPos2 = strfind( paramStr(cpPos+4:end), ' ' );
   str2 = paramStr(cpPos+4+cpPos2:end);
   paramStr = sprintf( '%s %e %s', str1, cp, str2 );
end

%% scale training data to zero mean, unit variance

[xscaled, translators, factors] = scaleTrainingData( x );

%% train model

paramStr = sprintf( '%s -m 500 -h 1 -b %d', paramStr, calcProbs );
disp( ['training with ' paramStr] );
model = libsvmtrain( y, xscaled, paramStr );

%% evaluate performance of model on training data

disp( 'training performance:' );
[~, trVal, ~] = libsvmPredictExt( y, x, model, translators, factors, calcProbs );

end