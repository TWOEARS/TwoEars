function [diffPerc, cvNumVsTsNum, cvVsTs, cvCoeffs, tsCoeffs] = cmpGlmnetCvCoeffsVsTrainsetCoeffs( glmModel, nCoeffs )

if nargin < 2
    lambdaIdx = find( glmModel.model.lambda <= glmModel.lambda, 1, 'first' );
else
    lambdaIdx = find( glmModel.nCoefs >= nCoeffs, 1, 'first' );
end
if isempty( lambdaIdx )
    lambdaIdx = length( glmModel.nCoefs );
end
cvCoeffs = glmModel.coefsRelAvg(lambdaIdx,:);
tsCoeffs = glmModel.model.beta(:,lambdaIdx)' ./ sum( abs( glmModel.model.beta(:,lambdaIdx) ) );

cvVsTs = abs( cvCoeffs - tsCoeffs );
cvNumVsTsNum = sum( abs( cvCoeffs > 0 ) ) - sum( abs( tsCoeffs > 0 ) );

diffPerc = sum( cvVsTs ) * 50;
