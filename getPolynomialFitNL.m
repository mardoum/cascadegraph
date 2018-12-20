function fitNL = getPolynomialFitNL(rawNL, degree)
x = rawNL(1,:);
y = rawNL(2,:);
[coeff, ~, mu] = polyfit(x, y, degree);
fitNL = struct('coeff', coeff, 'mu', mu);
end

