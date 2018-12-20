function filter = getFilter(stim, response, params)
numPts = size(stim, 2);

% loop across all epochs to compute filter
for ii = 1:size(response, 1)
    responseSingle = response(ii, :) - mean(response(ii, :));
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
