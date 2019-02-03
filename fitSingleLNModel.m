%% LN modeling test Main
clear; close all;
addpath('/Users/pmardoum/Desktop/Store/LN_modeling_Adree/');

%% set params

% params struct
p.fileName = '041317Ac3.mat';

p.samplingInterval = 1e-4;
p.frequencyCutoff  = 20;
p.prePts           = 3000;  
p.stimPts          = 50000;

% for filter
p.filterPts        = 12500;  % filter length (length of ONE SIDE, causal, or anti-causal)
p.useAnticausal    = true;
p.correctStimPower = false;

% for nonlinearity
p.numBins          = 100;
p.binningType      = 'equalN';

% for polynomial fit of nonlinearity
p.polyFitDegree    = 3;


%% get data
S = load(p.fileName);
responseComplete = S.BlueDataExc;
stimComplete = S.BlueStimuliExc;

% Baseline correction, filtering, etc
%   - note these steps do not affect the the output of getFilter, assuming constant frequency cutoff
responseComplete = applyFrequencyCutoff(responseComplete, p.frequencyCutoff, p.samplingInterval);
responseComplete = baselineSubtract(responseComplete, p.prePts);

response = trimPreAndTailPts(responseComplete, p.prePts, p.stimPts);
stim = trimPreAndTailPts(stimComplete, p.prePts, p.stimPts);

clear S responseComplete stimComplete

%% compute filter
[filterCausal, filterAnticausal] = getFilter(stim, response, p.filterPts, ...
    p.correctStimPower, p.frequencyCutoff, p.samplingInterval);

if p.useAnticausal
    filter = [filterCausal filterAnticausal];
else
    filter = filterCausal;
end
filter = filter/max(abs(filter));
clear filterCausal filterAnticausal

%% Compute model prediction (without computation graph)
generatorSignal = convolveFilterWithStim(filter, stim, p.useAnticausal);

[nlX, nlY] = getRawNL(generatorSignal, response, p.numBins, p.binningType); 

[fitNL.coeff, ~, fitNL.mu] = polyfit(nlX, nlY, p.polyFitDegree);
prediction = getPrediction(filter, stim, @polyval, fitNL, p.useAnticausal);

% Evaluate performance
rSquared = getVarExplained(prediction, response);
rSquaredAll = getVarExplained(reshape(prediction',1,[]), reshape(response',1,[]));
disp(['Overall R^2: ' num2str(rSquaredAll) '   Mean R^2: ' num2str(mean(rSquared))])

% Plot
figure; subplot(2,2,1); plot(filter);
xlabel('time'); ylabel('amp');

subplot(2,2,3); plot(nlX, nlY, 'bo');
hold on; plot(nlX, polyval(fitNL.coeff, nlX, [], fitNL.mu));
xlabel('generator signal'); ylabel('data');

subplot(2,2,2); plot(rSquared, 'bo');
hold on; plot(mean(rSquared) .* ones(1,length(rSquared)));
xlabel('epoch'); ylabel('r^2 value');

%% old snippets

% figure; hold on;
% window = 1:50000;
% plot(response(1,window), 'linewidth', 2);
% plot(generatorSignal(1,window), 'linewidth', 2);
% plot(prediction(1,window), 'linewidth', 2);
