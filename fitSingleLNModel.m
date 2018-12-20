%% LN modeling skeleton
clear;

%Here are all the params for the filter finding - set as a struct...

%TODO: Retrieve the four parameters below from metadata automatically 
%before exporting as .mat file
params.samplingInterval = 1e-4;
params.frequencyCutoff = 20;
params.prePts = 3000;  
params.stimPts = 50000;

%TODO: Figure out how to use staPts + truncating the filter effectively
params.staPts = 25000;

params.filterType = 'half';

%% get data
fileName = '081313Fc2.mat';
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

numBins = 60;
binningType = 'binPop';
rawNL = getRawNL(filter, response, stim, numBins, binningType); 

degree = 3;
fitNL = getPolynomialFitNL(rawNL, degree);
evalPoly = polyval(fitNL.coeff, rawNL(1,:), [], fitNL.mu);

%% forward run
prediction = getPrediction(filter, stim, @polyval, fitNL);

%% evaluate performance
[rSquared, meanRSquared] = getVarExplainedLN(prediction, response);

%% plot
figure; subplot(2,1,1); plot([filter.positiveTime]);
xlabel('time'); ylabel('amp');

subplot(2,1,2); plot(rawNL(1,:), rawNL(2,:), 'bo');
hold on; plot(rawNL(1,:), evalPoly);
xlabel('generator signal'); ylabel('data');

figure; plot(rSquared, '-bo');
hold on; plot(meanRSquared .* ones(1,length(rSquared)));
xlabel('epoch'); ylabel('r^2 value');