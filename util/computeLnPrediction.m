function prediction = computeLnPrediction(...
    filter, stim, nlFn, fnParams, filterHasAnticausalHalf)
% Computes predicted responses given stimuli, linear filter, and nonlinear
% function.
%
% Input:
%   filter    - vector containing the linear filter
%   stim      - matrix of row vectors containing stimuli
%   nlFn      - handle for function that evaluates the nonlinearity
%   fnParams  - structure countaining params for the nonlinear function
%   filterHasAnticausalHalf  - boolean

generatorSignal = convolveFilterWithStim(filter, stim, filterHasAnticausalHalf);

if isequal(nlFn, @polyval)
    prediction = nlFn(fnParams.coeff, generatorSignal, [], fnParams.mu);
elseif isequal(nlFn, @evalSigmoid)
    error('not implemented yet')
else
    error('not recognized function')
end

end