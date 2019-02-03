function trimmed = trimPreAndTailPts(signal, prePts, stimPts)
% Removes pre- and tail-points from epoch time-series data.
% Input:
%   signal  - matrix of row vectors, time-series data
%   prePts  - number of points to remove from beginning (pre-points)
%   stimPts - number of points following pre-points to keep

assert(size(signal,1) < size(signal,2), 'Incompatible matrix or vector orientation')

trimmed = signal(:, (prePts+1):(prePts+stimPts));

end