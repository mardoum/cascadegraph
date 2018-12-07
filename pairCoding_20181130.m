%% LN modeling skeleton
clear;

%TODO: Retrieve the four parameters below from metadata automatically 
%before exporting as .mat file
params.samplingInterval = 1e-4;
params.frequencyCutoff = 20;
params.prePts = 3000;  
params.stimPts = 50000;

%TODO: Figure out how to use staPts + truncating the filter effectively
params.staPts = 25000;

params.numBins = 40; %Is it fine if this is fixed?

%% get data
fileName = '041317Ac3.mat';
S = load(fileName);
responseComplete = S.BlueDataExc;
stimComplete = S.BlueStimuliExc;

% Baseline correction, filtering, etc
%   - note these steps do not affect the the output of getFilter, assuming constant frequency cutoff
responseComplete = ApplyFrequencyCutoffOvation(responseComplete, params.frequencyCutoff, params.samplingInterval);
responseComplete = BaselineCorrectOvation(responseComplete, 1, params.prePts);

response = trimPreAndTailPts(responseComplete, params.prePts, params.stimPts);
stim = trimPreAndTailPts(stimComplete, params.prePts, params.stimPts);

%% get model
filter = getFilter(stim, response, params);
midpoint = round(length(filter)/2); %TODO: truncate the filter in the filter collection stage
%filter(midpoint:end) = 0;
%midpoint = round(length(filter)/2);
%filter = [filter(1, midpoint + 1:end) filter(1, 1:midpoint)];
figure; plot(filter);

rawNL = getRawNL(filter, response, stim, params); 

degree = 3; 
fitNL = getPolynomialFitNL(rawNL, degree);
evalPoly = polyval(fitNL.coeff, rawNL(1,:), [], fitNL.mu);

figure; plot(rawNL(1,:), rawNL(2,:));
hold on; plot(rawNL(1,:), evalPoly);

%% forward run
prediction = getPrediction(filter, stim, @polyval, fitNL);

%% evaluate performance
[rSquared, meanRSquared] = getVarExplainedLN(prediction, response);

figure; plot(rSquared);
hold on; plot(meanRSquared .* ones(1,length(rSquared)));

%% local functions

function [rSquared, meanRSquared] = getVarExplainedLN(prediction, response)

responseMean = mean(response, 2);
sumSquareErr = response - prediction;
sumSquareTotal = response - responseMean;
sumSquareErr = sum((sumSquareErr.^2), 2);
sumSquareTotal = sum((sumSquareTotal.^2), 2);

rSquared = 1 - (sumSquareErr ./ sumSquareTotal);

meanRSquared = mean(rSquared);

end

function prediction = getPrediction(filter, stim, nlFn, fnParams)

generatorSignal = convolveFilterWithStim(filter, stim);

if isequal(nlFn, @polyval)
    prediction = nlFn(fnParams.coeff, generatorSignal, [], fnParams.mu);
elseif isequal(nlFn, @evalSigmoid)
    error('not implemented yet')
else
    error('not recognized function')
end

end

function filter = getFilter(stim, response, params)
numPts = size(stim, 2);

% loop across all epochs to compute filter
for ii = 1:size(response, 1)
    responseSingle = response(ii, :);
    stimSingle = stim(ii, :);
    
    dataFFT = fft(responseSingle);
    stmFFT = fft(stimSingle);
    
    if ii == 1
        filterFFT = conj(stmFFT) .* dataFFT;
    else
        filterFFT = filterFFT + conj(stmFFT) .* dataFFT;
    end
end

filterFFT = filterFFT / size(response, 1);
filterFFT = filterFFT / numPts;

freqStep = 1 / (numPts * params.samplingInterval);
maxFreq = round(params.frequencyCutoff / freqStep);

filterFFT(maxFreq:numPts - maxFreq) = 0;
filterFFT(1) = 0;

filter = real(ifft(filterFFT));
filter(params.staPts:length(filter) - params.staPts) = 0;

filter = filter / max(abs(filter));  % normalize (set peak to 1)
end

function rawNL = getRawNL(filter, data, stim, params)
numEpochs = size(stim, 1);
numPts = size(stim, 2);

% Generate a straight line with params.numBins points between the largest
% and smallest generator signal.
generatorSignal = zeros(numEpochs, numPts);
for ii = 1:numEpochs
    stimSingle = stim(ii, :); %- mean(stim(ii, :));  % subtract mean from stim
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

function generatorSignal = convolveFilterWithStim(filter, stim)

filterLength = size(filter,2);
numPts = size(stim,2); 
numEpochs = size(stim,1);

if filterLength ~= numPts
    diff = abs(filterLength - numPts);
    
    %finds out if the length of the difference is even or odd
    if mod(diff,2) ~= 0
        interval(1) = round(diff/2);
        interval(2) = round(diff/2) - 1;
    else
        interval(1) = diff/2;
        interval(2) = interval(1);
    end
    
    midpoint = round(filterLength / 2);
    
    %remove zeros from filter if stimuli length is shorter; otherwise, pad
    %with zeros - in either case, start modification from the middle of
    %filter
    if filterLength > numPts
    	filter(midpoint-interval(1)+1:midpoint+interval(2)) = [];
    else
    	filter = [filter(1:midpoint) zeros(1,diff-1) filter(midpoint:end)];
    end
end

filterFFT = fft(filter);

generatorSignalFFT = zeros(numEpochs, numPts);
generatorSignal = zeros(numEpochs, numPts);

for ii = 1:numEpochs
    stimSingle = stim(ii,:);
    stimSingleFFT = fft(stimSingle);
    generatorSignalFFT(ii,:) = filterFFT .* stimSingleFFT;
    generatorSignal(ii,:) = real(ifft(generatorSignalFFT(ii,:))); 
end
end

function trimmed = trimPreAndTailPts(signal, prePts, stimPts)
trimmed = signal(:, (prePts+1):(prePts+stimPts));
end

function fitNL = getPolynomialFitNL(rawNL, degree)
x = rawNL(1,:);
y = rawNL(2,:);
[coeff, ~, mu] = polyfit(x, y, degree);
fitNL = struct('coeff', coeff, 'mu', mu);
end



