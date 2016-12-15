function [pred, val, dec] = libsvmPredictExt( y, x, model, translators, factors, calcProbs )

x = scaleData( x, translators, factors );

[pred, ~, dec] = libsvmpredict(y, x, model, sprintf( '-b %d', calcProbs ) );
if model.Label(1) < 0;
  pred = pred * -1;
end
val = validationFunction(pred, y);
