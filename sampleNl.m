function [nlX, nlY] = sampleNl(inputSignal, response, numBins, binType)
% Returns binned sampling of relationship between input signal and response.
% Input:
%   inputSignal      - matrix of row vectors
%   response         - matrix of row vectors
%   numBins          - number of bins to sample nonlinearity
%   binType          - string 'equalWidth' or 'equalN'
% Output:
%   nlx  - vector of nonlinearity x values (bin centers)
%       If binType is set to 'equalWidth', bin centers are midpoints of each bin
%       If binType is set to 'equalN', bin centers are the means of x in each bin
%   nly  - vector of nonlinearity y values

assert(isequal(size(inputSignal), size(response)), 'Input matrices must have same size')

assert(size(inputSignal,1) < size(inputSignal,2), 'Incompatible matrix or vector orientation')

assert(numBins > 1, 'number of bins must be greater than 1')

inputSignal = reshape(inputSignal', 1, []);
response = reshape(response', 1, []);
numPoints = length(inputSignal);

nlX = zeros(numBins, 1);
nlY = zeros(numBins, 1);

% Bin signal and assign indices
if strcmp(binType, 'equalWidth')
    [~, binEdges, binIdx] = histcounts(inputSignal, numBins);
    nlX = 0.5 * (binEdges(1:end-1) + binEdges(2:end));
    
elseif strcmp(binType, 'equalN')
    assert(rem(numPoints, numBins) == 0, ...
        'If bin type option set to equally populated bins, # points must be evenly divisible by # bins')
    
    countInBin = numPoints / numBins;
    gsSorted = sort(inputSignal(:));
    binEdgeIndices = (1 + (0:numBins-1) * countInBin);
    binEdges = [gsSorted(binEdgeIndices); gsSorted(end)+1];  % last edge += 1 because bins are [ )
    
    [~, ~, binIdx] = histcounts(inputSignal, binEdges);

else
    error('binType not recognized')
end

for ii = 1:numBins
    binMask = (binIdx == ii);
    nlY(ii) = mean(response(binMask));
    
    if strcmp(binType, 'equalN')
        nlX(ii) = mean(inputSignal(binMask));
    end
end

end