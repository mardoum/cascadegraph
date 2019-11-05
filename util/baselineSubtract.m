function out = baselineSubtract(original, pointsToAvgForBaseline)
% Subtracts mean of first n points of each vector in input matrix. 
% 
% Inputs:
%   original   - input matrix with each row being a vector from a single epoch
%   prePoints  - number of points to average to estimate baseline 

baselineMeans = mean(original(:, 1:pointsToAvgForBaseline), 2);
out = original - repmat(baselineMeans, 1, length(original));

end