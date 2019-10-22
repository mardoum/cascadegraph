function out = baselineSubtract(original, prePoints)
% Subtracts mean of first n points of each vector in input matrix, where n =
% prePoints. 
% 
% Inputs:
%   original   - input matrix with each row being a vector from a single epoch
%   prePoints  - number of points to average to estimate baseline 

baselineMeans = mean(original(:, 1:prePoints), 2);
out = original - repmat(baselineMeans, 1, length(original));

end