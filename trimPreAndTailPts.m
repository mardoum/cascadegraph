function trimmed = trimPreAndTailPts(signal, prePts, stimPts)
trimmed = signal(:, (prePts+1):(prePts+stimPts));
end
