function rSquared = getVarExplained(prediction, response)
% Calculates row-wise R^2 between a prediction and some variable.  If inputs are matrices, R^2
% values for all rows are returned as a vector.
% Input:
%   prediction  - matrix of rows representing prediction
%   response    - matrix of rows representing predicted variable

assert(isequal(size(prediction), size(response)), 'Input matrices must have same size')

if size(prediction,1) > size(prediction,2)
    warning('Input matrices have more rows than columns. R^2 calculated for each row.')
end

responseMean = mean(response, 2);
sumSquareErr = sum(((response - prediction).^2), 2);
sumSquareTotal = sum(((response - responseMean).^2), 2);

rSquared = 1 - (sumSquareErr ./ sumSquareTotal);

end
