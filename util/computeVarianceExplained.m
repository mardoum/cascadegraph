function rSquared = computeVarianceExplained(predicted, measured)
% Computes row-wise R^2 between a prediction and some variable.  If inputs are
% matrices, R^2 values for all rows are returned as a vector.
% Input:
%   prediction  - matrix of rows representing prediction
%   measured    - matrix of rows representing predicted variable

assert(isequal(size(predicted), size(measured)), 'Input matrices must have same size')

if size(predicted,1) > size(predicted,2)
    warning('Input matrices have more rows than columns. R^2 calculated for each row.')
end

responseMean = mean(measured, 2);
sumSquareErr = sum(((measured - predicted).^2), 2);
sumSquareTotal = sum(((measured - responseMean).^2), 2);

rSquared = 1 - (sumSquareErr ./ sumSquareTotal);

end