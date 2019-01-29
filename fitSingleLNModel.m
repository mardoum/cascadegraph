%% LN modeling skeleton
clear;
addpath('/Users/pmardoum/Desktop/LN_modeling_Adree/');

% Here are all the params for the filter finding - set as a struct...

% TODO: Retrieve the four parameters below from metadata automatically before exporting as .mat file
p.samplingInterval = 1e-4;
p.frequencyCutoff  = 20;
p.prePts           = 3000;  
p.stimPts          = 50000;
p.filterPts        = 12500;  % filter length (length of ONE SIDE, causal, or anti-causal)

% for filter
useAnticausal = false;

% for nonlinearity
numBins = 100;
binningType = 'equalN';

% for polynomial fit of nonlinearity
degree = 3;

%% get data
fileName = '041317Ac3.mat';
S = load(fileName);
responseComplete = S.BlueDataExc;
stimComplete = S.BlueStimuliExc;

% Baseline correction, filtering, etc
%   - note these steps do not affect the the output of getFilter, assuming constant frequency cutoff
responseComplete = applyFrequencyCutoff(responseComplete, p.frequencyCutoff, p.samplingInterval);
responseComplete = baselineSubtract(responseComplete, p.prePts);

response = trimPreAndTailPts(responseComplete, p.prePts, p.stimPts);
stim = trimPreAndTailPts(stimComplete, p.prePts, p.stimPts);

%% get model
[filterCausal, filterAnticausal] = getFilter(stim, response, p);

if useAnticausal
    filter = [filterCausal filterAnticausal];
else
    filter = filterCausal;
end
filter = filter/max(abs(filter));

generatorSignal = convolveFilterWithStim(filter, stim, useAnticausal);

[nlX, nlY] = getRawNL(generatorSignal, response, numBins, binningType); 

[fitNL.coeff, ~, fitNL.mu] = polyfit(nlX, nlY, degree);

%% forward run
prediction = getPrediction(filter, stim, @polyval, fitNL, useAnticausal);

%% evaluate performance
rSquared = getVarExplained(prediction, response);

rSquaredAll = getVarExplained(reshape(prediction',1,[]), reshape(response',1,[]));

%% plot
evalPoly = polyval(fitNL.coeff, nlX, [], fitNL.mu);

figure; subplot(2,2,1); plot(filter);
xlabel('time'); ylabel('amp');

subplot(2,2,3); plot(nlX, nlY, 'bo');
hold on; plot(nlX, evalPoly);
xlabel('generator signal'); ylabel('data');

subplot(2,2,2); plot(rSquared, 'bo');
hold on; plot(mean(rSquared) .* ones(1,length(rSquared)));
xlabel('epoch'); ylabel('r^2 value');

%%
% figure; hold on;
% window = 1:50000;
% plot(response(1,window), 'linewidth', 2);
% plot(generatorSignal(1,window), 'linewidth', 2);
% plot(prediction(1,window), 'linewidth', 2);
