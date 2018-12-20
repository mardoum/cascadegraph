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
