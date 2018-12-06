%% LN modeling skeleton
clear;

%Set the parameters used to derive the model
params.samplingInterval = 1e-4;
params.frequencyCutoff = 20;
params.staPts = 25000;
params.computeNL = 1;
params.numBins = 40;

params.prePts = 3000;  % TODO: retrieve pre- and stim-points in a better way
params.stimPts = 50000;

%% get data
fileName = '041317Ac3.mat';
S = load(fileName);
responseComplete = S.BlueDataExc;
stimComplete = S.BlueStimuliExc;

% Baseline correction, filtering, etc
%   - note these steps do not affect the the output of getFilter, assuming constant frequency cutoff
responseComplete = ApplyFrequencyCutoffOvation(responseComplete, params.frequencyCutoff, params.samplingInterval);
responseComplete = BaselineCorrectOvation(responseComplete, 1, params.prePts); % TODO: make version that finds prepoints automatically

response = trimPreAndTailPts(responseComplete, params.prePts, params.stimPts);
stim = trimPreAndTailPts(stimComplete, params.prePts, params.stimPts);

%% get model
filter = getFilter(stim, response, params);
figure; plot(filter);

%midpoint = round(length(filter)/2);
%filter = [filter(1, midpoint + 1:end) filter(1, 1:midpoint)];
%figure; plot(filter);

rawNL = getRawNL(filter, response, stim, params); 
figure; plot(rawNL(1,:), rawNL(2,:));

degree = 3; 
fitNL = getPolynomialFitNL(rawNL, degree);
evalPoly = polyval(fitNL.coeff, rawNL(1,:), [], fitNL.mu);
hold on; plot(rawNL(1,:), evalPoly);

%% forward run
% prediction, generatorSignal = getPrediction(filter, fitNL, stim)
prediction = getPrediction(filter, stim, @polyval, fitNL);
figure; plot(prediction(1,:));
hold on; plot(response(1,:))

%% evaluate performance
% rSquared = getVarExplainedLN(prediction, data)


%% local functions

function prediction = getPrediction(filter, stim, nlFn, fnParams)

numEpochs = size(stim, 1);
numPts = size(stim, 2);

% Generate a straight line with params.numBins points between the largest
% and smallest generator signal.
generatorSignal = zeros(numEpochs, numPts);
for ii = 1:numEpochs
    stimSingle = stim(ii, :); %- mean(stim(ii, :));  % subtract mean from stim
    generatorSignal(ii,:) = convolveFilterWithStim(filter, stimSingle);
end

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
    stimSingle = stim(ii, :) - mean(stim(ii, :));
    
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

% fit nonlinearity and make full prediction
nanLocs = isnan(dataBinned);
indices = find(nanLocs == 0);
rawNL(1,:) = bins;
rawNL(2,:) = dataBinned;
end

function generatorSignal = convolveFilterWithStim(filter, stim)

if length(filter) ~= length(stim)
    diff = abs(length(filter) - length(stim));
    
    %finds out if the length divided by two is even or odd
    if mod(diff,2) ~= 0
        interval(1) = round(diff/2);
        interval(2) = round(diff/2) - 1;
    else
        interval(1) = diff/2;
        interval(2) = interval(1);
    end
    
    midpoint = round(length(filter)/2);
    
    if length(filter) > length(stim)
    	filter(midpoint-interval(1)+1:midpoint+interval(2)) = [];
    else
    	filter = [filter(1:midpoint) zeros(1,diff-1) filter(midpoint:end)];
    end
end

filterFFT = fft(filter);
stimuliFFT = fft(stim);
generatorSignalFFT = filterFFT .* stimuliFFT;
generatorSignal = real(ifft(generatorSignalFFT));
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



