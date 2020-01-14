%% CascadeGraph Demo: Linear-Nonlinear Models
% This script introduces basic functionality of CascadeGraph. We will first
% implement a simple two-stage linear-nonlinear (LN) cascade model to predict a
% visual neuron's response to a white-noise light stimulus. We'll do this in a
% few different ways to illustrate some of the options available. Last, we'll
% implement a similar cascade model, but with a branching structure.
% 
% A simple LN model consists of a linear filter and a nonlinearity in series.
% The goal is to pick the filter and nonlinearity such that, given some
% stimulus, the model produces a good prediction of the neuron's response. Even
% such a simple model can achieve impressive predictive power when the
% statistics of the noise stimulus, like mean and variance, are held stationary.

%% Set constant settings

clear; close all;

SETTINGS.frequencyCutoff  = 20;

% Filter settings:
SETTINGS.filterPts        = 1250;  % length of ONE SIDE of filter (causal or anti-causal side)
SETTINGS.correctStimPower = true;
SETTINGS.useAnticausal    = false;

% Nonlinearity settings:
SETTINGS.numBins          = 100;
SETTINGS.binningType      = 'equalN';
SETTINGS.polyFitDegree    = 3;

%% Load data
% We start with some example data containing electrical responses recorded in a
% visual neuron while a noisy light stimulus was presented. We load matrices
% containing the stimulus and the response, where each row contains data from a
% single trial.

% Load data from file
addpath([pwd '/util']);
S = load('exampleData.mat');

% Filter out high-frequency noise
S.response = applyFrequencyCutoff(S.response, SETTINGS.frequencyCutoff, S.samplingInterval);

% Split data into training and test sets (80/20 split)
response = S.response(1:16,:);
stimulus = S.stimulus(1:16,:);
responseTestSet = S.response(17:20,:);
stimulusTestSet = S.stimulus(17:20,:);
samplingInterval = S.samplingInterval;

% Visualize example trial
tTrial  = ((1:length(response)) * samplingInterval)';   % Time vector
figure;
subplot(2,1,1); plot(tTrial, responseTestSet(1,:));
title('response (example trial)'); ylabel('current (pA)');
subplot(2,1,2); plot(tTrial, stimulusTestSet(1,:));
title('stimulus'); xlabel('time (s)'); ylabel('light intensity');

%% Compute filter
% Because the stimulus is gaussian white noise, the best filter can be computed
% using a cross-correlation between stimulus and response:

[filterCausal, filterAnticausal] = computeFilter(stimulus, response, SETTINGS.filterPts, ...
    SETTINGS.correctStimPower, SETTINGS.frequencyCutoff, samplingInterval);

if SETTINGS.useAnticausal
    % Note: This concatenation at first appears out of order and creates a
    % discontinuity in the center of the filter vector. But this ordering is
    % convenient later when we use this filter in a (circular) convolution,
    % which assumes signals are periodic and wrap around.
    filter = [filterCausal filterAnticausal];
else
    filter = filterCausal;
end

filter = filter/max(abs(filter));   % Normalize filter

tFilter = ((1:length(filter)) * samplingInterval)';
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

% Filter stimulus and sample nonlinearity as before
generatorSignal = convolveFilterWithStim(filter, stimulus, SETTINGS.useAnticausal);
[nlX, nlY] = sampleNl(generatorSignal, response, SETTINGS.numBins, SETTINGS.binningType);

% Instantiate nodes for model graph
dataNodeInstance = DataNode(stimulusTestSet);                       % stimulus (DataNode)
filterNodeInstance = FilterNode(filter, SETTINGS.useAnticausal);    % filter (FilterNode)
polyfitNlNodeInstance = PolyfitNlNode();                            % nonlinearity (PolyfitNlNode)

% Fit parameters of nonlinearity
polyfitNlNodeInstance.fitToSample(nlX, nlY, SETTINGS.polyFitDegree);

% Define edges (connections) in computation graph. Here we define a simple
% linear graph with three nodes (stimulus, filter, nonlinearity). There are only
% two edges to define.
filterNodeInstance.upstream.add(dataNodeInstance);
polyfitNlNodeInstance.upstream.add(filterNodeInstance);

% Compute prediction. The nonlinear node is the final node in the model, so we
% can call its processUpstream() method to run the entire model.
prediction = polyfitNlNodeInstance.processUpstream();

% Evaluate performance
rSquaredAllPoly = computeVarianceExplained(...
    reshape(prediction',1,[]), reshape(responseTestSet',1,[]));

disp(['PolyFit - Overall R^2: ' num2str(rSquaredAllPoly)])

% Plot
figure; subplot(2,1,1); 
plot(tFilter, filterNodeInstance.filter);
xlabel('time (s)');
title('filter');

subplot(2,1,2); hold on;
plot(nlX, nlY, 'ko');
plot(nlX, polyfitNlNodeInstance.process(nlX));
xlabel('filtered stimulus value'); ylabel('output (pA)');
title('nonlinearity');

figure; hold on;
plot(tTrial, responseTestSet(1,:));
plot(tTrial, prediction(1,:), 'linewidth', 2);
xlabel('time (s)'); ylabel('current (pA)');

%% Try fitting sigmoidal nonlinearity
% Instead of the polynomial fit nonlinearity used above, let's try a sigmoid. We
% can reuse the nodes containing the stimulus and filter by adding an upstream
% edge between the filter node and the new sigmoid nonlinearity node.

sigmoidNlNodeInstance = SigmoidNlNode();
sigmoidNlNodeInstance.fitToSample(nlX, nlY);
sigmoidNlNodeInstance.upstream.add(filterNodeInstance);

% Note we can delete the old polyfit nonlinear node, but we don't need to
% because the new sigmoid nonlinear node does not have access to it (i.e. there
% is no path between the two nonlinear nodes because of the structure of the
% directed edges in the graph).

prediction = sigmoidNlNodeInstance.processUpstream();

% Evaluate performance
rSquaredAllPoly = computeVarianceExplained(...
    reshape(prediction',1,[]), reshape(responseTestSet',1,[]));

disp(['Sigmoid - Overall R^2: ' num2str(rSquaredAllPoly)])

%% Jointly fit parameterized filter and nonlinearity
% In the previous examples, the nodes that require optmization are optimized
% separately. But often we need to optimize two or more components jointly, such
% as when the paremeters of one component influence the optimal parameters of
% one or more others.
% 
% To jointly optimize multiple nodes, instantiate these nodes inside another
% node object, a "hyper-node", which stores the graph and all the free
% parameters needed to define the contained nodes. The parameters are then
% optimized together within that node, as with any parameterized node.
% 
% In this example, instead of using the filter computed by cross-correlation we
% will use a parameterized filter and optimize it jointly with a sigmoid
% nonlinearity. The filter and nonlinearity nodes are instantiated in an
% instance of a hyper-node class called LnHyperNode. (Note: The hyper-node
% should contain a graph that includes all nodes being jointly optimized, but it
% doesn't necessarily need to contain the entire model. For instance, in this
% example the DataNode that stores the stimulus remains outside the hyper node
% and is referenced in the hypernode's "upstream" field.)

stimNode = DataNode(stimulus);
model = LnHyperNode();
model.upstream.add(stimNode);
model.dt_stored = samplingInterval;

% Set initial conditions. The first 5 parameters define the filter. The
% following 4 parameters define the nonlinearity. All are placed in the same
% vector to be optimized together.
p0 = [5
      3
      0.1
      11
      800
      800
      0.001
      0.001
      -600];

% Optimize hyper-node params
optimIters = 5;
for i = 1:optimIters
    model.optimizeParams(p0, stimulus, response, samplingInterval);
    p0 = model.getFreeParams;
    
    % Compute prediction
    prediction = model.processUpstream();
    
    rSquaredAll = computeVarianceExplained(reshape(prediction',1,[]), reshape(response',1,[]));
    disp(['Parameterized LN training iter ' num2str(i) ' R^2: ' num2str(rSquaredAll)])
end

% Compute test prediction
stimNode.data = stimulusTestSet;
prediction = model.processUpstream();

% Evaluate and visualize
rSquaredAll  = computeVarianceExplained(...
    reshape(prediction',1,[]), reshape(responseTestSet',1,[]));
disp(['Overall test R^2: ' num2str(rSquaredAll)])

figure; subplot(2,1,1);
plot(tFilter, model.subnodes.filter.getFilter(SETTINGS.filterPts, samplingInterval));
xlabel('time (s)');
title('filter');

generatorSignal = model.subnodes.filter.process(stimNode.data, samplingInterval);
[nlX, nlY] = sampleNl(generatorSignal, responseTestSet, SETTINGS.numBins, SETTINGS.binningType);
subplot(2,1,2); hold on;
plot(nlX, model.subnodes.nonlinearity.process(nlX));
plot(nlX, nlY, 'ko');
xlabel('filtered stimulus value'); ylabel('output (pA)');
title('nonlinearity');

%% Fit model with branching structure

stimNode = DataNode(stimulus);
model = TwoArmLnHyperNode();
model.upstream.add(stimNode);
model.dt_stored = samplingInterval;

p0 = [5
      3
      0.1
      11
      800
      5
      3
      0.1
      11
      800
      800
      0.001
      0.001
      -600
      800
      0.001
      0.001
      -600];

% Optimize hyper-node params
optimIters = 5;
for i = 1:optimIters
    model.optimizeParams(p0, stimulus, response, samplingInterval);
    p0 = model.getFreeParams;
    
    % Compute prediction
    prediction = model.processUpstream();
    
    rSquaredAll = computeVarianceExplained(reshape(prediction',1,[]), reshape(response',1,[]));
    disp(['Parameterized LN training iter ' num2str(i) ' R^2: ' num2str(rSquaredAll)])
end

% Compute test prediction
stimNode.data = stimulusTestSet;
prediction = model.processUpstream();

% Evaluate and visualize
rSquaredAll  = computeVarianceExplained(...
    reshape(prediction',1,[]), reshape(responseTestSet',1,[]));
disp(['Overall test R^2: ' num2str(rSquaredAll)])

tFilter = (1:SETTINGS.filterPts) * samplingInterval;
figure; subplot(2,1,1); hold on;
plot(tFilter, model.subnodes.filter1.getFilter(SETTINGS.filterPts, samplingInterval));
plot(tFilter, model.subnodes.filter2.getFilter(SETTINGS.filterPts, samplingInterval));
xlabel('time (s)');
title('Two-arm LN');
subplot(2,1,2); hold on;
xarray = -800:1200;
plot(xarray, model.subnodes.nonlinearity1.process(xarray))
plot(xarray, model.subnodes.nonlinearity2.process(xarray))
xlabel('filtered stimulus value'); ylabel('output (pA)');

%% Try experimenting with more complicated models
% The examples in this demo require only a few nodes and a simple chaining of
% model stages. But because each node can have multiple parents and children, it
% is possible to build larger graphs with more complicated structure. Try
% building a more ambitious model for your use case. Keep in mind that currently
% CascadeGraph does not handle cycles in the model graph, meaning the package
% would need to be extended to incorporate feedback or closed-loop simulations.
