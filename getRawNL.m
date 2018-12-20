function rawNL = getRawNL(filter, data, stim, numBins, varargin)

numEpochs = size(stim, 1);

generatorSignal = convolveFilterWithStim(filter, stim);

% Let the user choose how to bin the generator signal values - either with
% equally spaced bins or equally populated bins. If they don't specify a
% value in the passed struct "params", then default to equally populated
% bins.

numvarargs = length(varargin);

if numvarargs > 1
    error('Too many input arguments');
elseif numvarargs ~= 0
    binType = varargin{1};
else
    binType = 'binPop';
end

if strcmp(binType, 'binWidth')
    minGen = min(min(generatorSignal));
    maxGen = max(max(generatorSignal));
    step = (maxGen-minGen)/numBins;
    binCenter = zeros(1, numBins);
    
    for ii = 1:numBins
        binCenter(ii) = minGen + ii * step;
    end
    
    binWindowHalf = step .* ones(1, numBins) / 2;
    
elseif strcmp(binType, 'binPop')
    sortedGeneratorSignal = sort(generatorSignal(:));
    countInBin = round(length(sortedGeneratorSignal) / numBins);
    binCenter = zeros(1, numBins);
    binWindowHalf = binCenter;
    
    for ii = 1:numBins
        startPoint = (ii-1) * countInBin + 1;
        endPoint = min(ii * countInBin, length(sortedGeneratorSignal));
        if ii == numBins
            endPoint = length(sortedGeneratorSignal);
        end
    
        currentPopulation = sortedGeneratorSignal(startPoint:endPoint);
    
        binCenter(ii) = mean(currentPopulation);
        
        %Generate variable bin windows. Since you cannot calculate the
        %first bin window by taking the midpoint between binMean_i and 
        %binMean_(i-1), use the window of the final bin instead.
        
        if ii > 1
            binWindowHalf(ii) = (binCenter(ii) - binCenter(ii-1))/2;
        end
        
        if ii == numBins
            binWindowHalf(1) = binWindowHalf(ii);
        end
    end
    
else
    error('Binning method not implemented.')
end

% loop across all epochs to compute nonlinearity
epochBinCnt = zeros(numBins,1);
dataBinned = zeros(numBins,1);
for ii = 1:numEpochs
    singleGeneratorSignal = generatorSignal(ii, :);
    binIndices = cell(numBins, 1);
    for jj = 1:numBins
        binLHS = binCenter(jj) - binWindowHalf(jj);
        binRHS = binCenter(jj) + binWindowHalf(jj);
        
        binIndices{jj} = find((singleGeneratorSignal < binRHS) & ...
            (singleGeneratorSignal > binLHS));
    end
    
    singleEpochData = data(ii, :);
    for jj = 1:numBins
        if length(binIndices{jj}) > 4
            singleEpochMean = mean(singleEpochData(binIndices{jj}));
            if ii == 1
                dataBinned(jj) = singleEpochMean;
            else
                dataBinned(jj) = dataBinned(jj) + singleEpochMean;
            end
            epochBinCnt(jj) = epochBinCnt(jj) + 1;
        end
    end
    
end

dataBinned = dataBinned ./ epochBinCnt;

rawNL(1,:) = binCenter;
rawNL(2,:) = dataBinned;
end