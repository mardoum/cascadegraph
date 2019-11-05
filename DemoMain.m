%% CascadeGraph Demo: Linear-Nonlinear Models
% This script introduces basic functionality of CascadeGraph. We will implement
% a simple two-stage linear-nonlinear (LN) cascade model to predict a visual
% neuron's response to a white-noise light stimulus. We'll do this in a few
% different ways to illustrate some of the options available.
% 
% A LN model consists of a linear filter and a nonlinearity in series. The goal
% is to pick the filter and nonlinearity such that, given some stimulus, the
% model produces a good prediction of the neuron's response. Even such a simple
% model can achieve impressive predictive power when the statistics of the noise
% stimulus, like mean and variance, are held stationary.

%% Set constant settings

clear; close all;

SETTINGS.frequencyCutoff  = 20;

% for filter:
SETTINGS.filterPts        = 1250;  % length of ONE SIDE of filter (causal or anti-causal side)
SETTINGS.useAnticausal    = false;
SETTINGS.correctStimPower = false;

% for nonlinearity:
SETTINGS.numBins          = 100;
SETTINGS.binningType      = 'equalN';

% for polynomial fit of nonlinearity:
SETTINGS.polyFitDegree    = 3;

%% Load data
% We start with some example data containing electrical responses recorded in a
% visual neuron while a noisy light stimulus was presented. We load matrices
% containing the stimulus and the response, where each row contains data from a
% single trial.

addpath([pwd '/util']);
S = load('exampleData.mat');

% Split data into training and test sets (80/20 split)
response = S.response(1:16,:);
stimulus = S.stimulus(1:16,:);
responseTestSet = S.response(17:20,:);
stimulusTestSet = S.stimulus(17:20,:);
samplingInterval = S.samplingInterval;

% Time vectors for plotting
tFilter = ((1:SETTINGS.filterPts) * samplingInterval)';
tTrial  = ((1:length(response)) * samplingInterval)';

% Visualize example trial
subplot(2,1,1); plot(tTrial, response(1,:));
title('response (example trial)'); ylabel('current (pA)');
subplot(2,1,2); plot(tTrial, stimulus(1,:));
title('stimulus'); xlabel('time (s)'); ylabel('light intensity');

%% Filter out high-frequency noise

response = applyFrequencyCutoff(response, SETTINGS.frequencyCutoff, samplingInterval);

%% Compute filter
% Because the stimulus is gaussian white noise, the best filter can be computed
% using a cross-correlation between stimulus and response:

[filterCausal, filterAnticausal] = computeFilter(stimulus, response, SETTINGS.filterPts, ...
    SETTINGS.correctStimPower, SETTINGS.frequencyCutoff, samplingInterval);

if SETTINGS.useAnticausal
    filter = [filterCausal filterAnticausal];
else
    filter = filterCausal;
end
filter = filter/max(abs(filter));
clear filterCausal filterAnticausal

%% Compute model prediction (without computation graph)
% The real power of CascadeGraph is in building models in a graph, where nodes
% are computational elements and edges control the flow of data. However,
% because LN models only contain two computational elements it's worth getting
% started by writing out the model without the graph representation.

% Filter stimulus with filter computed earlier
generatorSignal = convolveFilterWithStim(filter, stimulus, SETTINGS.useAnticausal);

% Sample the input-output relationship between the filtered stimulus and the
% target response, and use polynomial curve fitting to describe the curve.
[nlX, nlY] = sampleNl(generatorSignal, response, SETTINGS.numBins, SETTINGS.binningType); 
[polyfitResults.coeff, ~, polyfitResults.mu] = polyfit(nlX, nlY, SETTINGS.polyFitDegree);

% Now we have our filter and nonlinearity. Compute prediction on test data.
generatorSignal = convolveFilterWithStim(filter, stimulusTestSet, SETTINGS.useAnticausal);
prediction = polyval(polyfitResults.coeff, generatorSignal, [], polyfitResults.mu);

% Evaluate performance
rSquared = computeVarianceExplained(prediction, responseTestSet);
rSquaredAll = computeVarianceExplained(reshape(prediction',1,[]), reshape(responseTestSet',1,[]));
disp(['Overall R^2: ' num2str(rSquaredAll) '   Mean R^2: ' num2str(mean(rSquared))])

% Plot
figure; subplot(2,1,1);
plot(tFilter, filter);
xlabel('time (s)');
title('filter');

subplot(2,1,2); hold on;
plot(nlX, nlY, 'ko');
plot(nlX, polyval(polyfitResults.coeff, nlX, [], polyfitResults.mu));
xlabel('filtered stimulus value'); ylabel('output (pA)');
title('nonlinearity');

figure; hold on;
plot(tTrial, responseTestSet(1,:));
plot(tTrial, prediction(1,:), 'linewidth', 2);
xlabel('time (s)'); ylabel('current (pA)');

%% Compute model prediction (with computation graph)
% Now let's do the same thing, but this time using node objects that represent
% the two stages. In addition to the nodes representing the filter and
% nonlinearity, we create a node that stores the stimulus and place it upstream
% of the filter node. The graph then has everything necessary to run the model.
% 
% To keep things interesting, we'll compare LN models that use two different
% methods of fitting the nonlinearity: polynomial and sigmoid. We'll use
% different node classes for these. In this particular case the two node types
% can be placed in the same graph without affecting each other.
% 
% Each of the nonlinearity nodes contains parameters that define the form of the
% nonlinearity, and these parameters must be optimized. This is done for each
% nonlinearity separately using the fitToSample() method.

dataNodeInstance = DataNode(stimulusTestSet);
filterNodeInstance = FilterNode(filter, SETTINGS.useAnticausal);
filterNodeInstance.upstream.add(dataNodeInstance);

% Try polynomial fit nonlinearity
polyfitNlNodeInstance = PolyfitNlNode();
polyfitNlNodeInstance.fitToSample(nlX, nlY, SETTINGS.polyFitDegree);
polyfitNlNodeInstance.upstream.add(filterNodeInstance);

predictionPolyfitNl = polyfitNlNodeInstance.processUpstream();

% Try sigmoid nonlinearity
sigmoidNlNodeInstance = SigmoidNlNode();
sigmoidNlNodeInstance.fitToSample(nlX, nlY);
sigmoidNlNodeInstance.upstream.add(filterNodeInstance);

predictionSigmoidNl = sigmoidNlNodeInstance.processUpstream();

% Evaluate performance
rSquaredAllPoly = computeVarianceExplained(...
    reshape(predictionPolyfitNl',1,[]), reshape(responseTestSet',1,[]));
rSquaredAllSig  = computeVarianceExplained(...
    reshape(predictionSigmoidNl',1,[]), reshape(responseTestSet',1,[]));
disp(['PolyFit - Overall R^2: ' num2str(rSquaredAllPoly)])
disp(['Sigmoid - Overall R^2: ' num2str(rSquaredAllSig)])

% Plot
figure; subplot(2,1,1); 
plot(tFilter, filter);
xlabel('time (s)');
title('filter');

subplot(2,1,2); hold on;
plot(nlX, nlY, 'ko');
plot(nlX, polyfitNlNodeInstance.process(nlX));
plot(nlX, sigmoidNlNodeInstance.process(nlX));
xlabel('filtered stimulus value'); ylabel('output (pA)');
title('nonlinearity');

%% Jointly fit parameterized filter and nonlinearity
% In the previous example, the nodes that require optmization are optimized
% separately. But often we need to optimize two or more components jointly, such
% as when multiple parameterized components need to be optimized and the
% paremeters of one component influence the optimal parameters of the others.
% 
% To jointly optimize multiple nodes, build a graph with these nodes inside
% another node object, a "hyper-node", which stores the graph and all the free
% parameters needed to define the contained nodes. The parameters are then
% optimized together within that node, as with any parameterized node. We have
% now encountered all three of the core abstract node classes: All nodes are
% ModelNodes, some ModelNodes are ParameterizedNodes, and some
% ParameterizedNodes are HyperNodes. Subclasses of HyperNode inherit (from
% ParameterizedNode) the machinery to optimize free params, such as the method
% optimizeParams().
% 
% In this example, instead of using the filter computed by cross-correlation we
% will use a parameterized filter and optimize it jointly with a sigmoid
% nonlinearity. The filter and nonlinearity nodes are instantiated in an
% instance of a node class called LnHyperNode. (Note: The hyper-node should
% contain a graph that includes all nodes being jointly optimized, but it
% doesn't need to contain the entire model. For instance, in this example the
% DataNode that stores the stimulus remains outside the hyper node and is
% referenced in the hypernode's "upstream" field.)

stimNode = DataNode(stimulus);
model = LnHyperNode();
model.upstream.add(stimNode);
model.dt_stored = samplingInterval;

% Initialize hyper node params
p0 = [5
      3
      0.1
      11
      800
      800
      0.001
      0.001
      -600];

% Optimize hyper node params
optimIters = 5;
for ii = 1:optimIters
    model.optimizeParams(p0, stimulus, response, samplingInterval);
    p0 = model.getFreeParams;
    
    % Compute prediction
    prediction = model.processUpstream();
    
    rSquaredAll = computeVarianceExplained(reshape(prediction',1,[]), reshape(response',1,[]));
    disp(['Parameterized LN training iter ' num2str(ii) ' R^2: ' num2str(rSquaredAll)])
end

% Compute test prediction
stimNode.data = stimulusTestSet;
prediction = model.processUpstream();

% Evaluate and visualize
rSquaredAll  = computeVarianceExplained(...
    reshape(prediction',1,[]), reshape(responseTestSet',1,[]));
disp(['Overall test R^2: ' num2str(rSquaredAllSig)])

figure; subplot(2,1,1);
plot(tFilter, model.subnodes.filter.getFilter(SETTINGS.filterPts, samplingInterval), 'linewidth', 2);
xlabel('time (s)');
title('filter');

generatorSignal = model.subnodes.filter.process(stimNode.data, samplingInterval);
[nlX, nlY] = sampleNl(generatorSignal, responseTestSet, SETTINGS.numBins, SETTINGS.binningType);
subplot(2,1,2); hold on;
plot(nlX, model.subnodes.nonlinearity.process(nlX), 'linewidth', 2);
plot(nlX, nlY, '.');
xlabel('filtered stimulus value'); ylabel('output (pA)');
title('nonlinearity');

%% Try experimenting with more complicated models
% The examples in this demo require only a few nodes and a simple chaining of
% model stages. But because each node can have multiple parents and children, it
% is possible to build larger graphs with more complicated structure. Try
% building a more ambitious model for your use case. Keep in mind that currently
% CascadeGraph does not handle cycles in the model graph, meaning the package
% would need to be extended to incorporate feedback or closed-loop simulations.
