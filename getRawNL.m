function rawNL = getRawNL(filter, data, stim, params)
numEpochs = size(stim, 1);
numPts = size(stim, 2);

% Generate a straight line with params.numBins points between the largest
% and smallest generator signal.
generatorSignal = zeros(numEpochs, numPts);
for ii = 1:numEpochs
    stimSingle = stim(ii, :) - mean(stim(ii, :));  % subtract mean from stim
    generatorSignal(ii,:) = convolveFilterWithStim(filter, stimSingle);
end
minGen = min(min(generatorSignal));
maxGen = max(max(generatorSignal));
step = (maxGen-minGen)/params.numBins;

bins = zeros(params.numBins, 1);
for ii = 1:params.numBins
    bins(ii) = minGen + ii * step;
end

% loop across all epochs to compute nonlinearity
epochBinCnt = zeros(params.numBins,1);
dataBinned = zeros(params.numBins,1);
for ii = 1:numEpochs
    singleGeneratorSignal = generatorSignal(ii, :);
    binIndices = cell(params.numBins, 1);
    for jj = 1:params.numBins
        binIndices{jj} = find((singleGeneratorSignal < bins(jj) + ...
            step/2) & (singleGeneratorSignal > bins(jj) - step/2));
    end
    
    singleEpochData = data(ii, :);
    for jj = 1:params.numBins
        if length(binIndices{jj}) > 4
            if ii == 1
                dataBinned(jj) = mean(singleEpochData(binIndices{jj}));
            else
                dataBinned(jj) = dataBinned(jj) + mean(singleEpochData(binIndices{jj}));
            end
            epochBinCnt(jj) = epochBinCnt(jj) + 1;
        end
    end
    
end

dataBinned(epochBinCnt == 0) = NaN;
% indices = find(epochBinCnt > 0);  %TODO: see if anything here is necessary when something is NaN
% dataBinned(indices) = dataBinned(indices) ./ epochBinCnt(indices);
dataBinned = dataBinned ./ epochBinCnt;
if sum(isnan(dataBinned)) > 0
    error('Bin contains zero counts! See lines 177-184.');
end

% fit nonlinearity and make full prediction
nanLocs = isnan(dataBinned);
indices = find(nanLocs == 0);
rawNL(1,:) = bins;
rawNL(2,:) = dataBinned;
end
