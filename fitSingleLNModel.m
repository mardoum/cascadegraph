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