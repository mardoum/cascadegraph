function [rSquared, meanRSquared] = getVarExplainedLN(prediction, response)

responseMean = mean(response, 2);
sumSquareErr = response - prediction;
sumSquareTotal = response - responseMean;
sumSquareErr = sum((sumSquareErr.^2), 2);
sumSquareTotal = sum((sumSquareTotal.^2), 2);

rSquared = 1 - (sumSquareErr ./ sumSquareTotal);

meanRSquared = mean(rSquared);

end