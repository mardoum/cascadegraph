function fitNL = getPolynomialFitNL(rawNL, varargin)

numvarargs = length(varargin);

if numvarargs > 1
    error('Too many input arguments');
elseif numvarargs ~= 0
    degree = varargin{1};
else
    degree = 3; %set the default polynomial degree if unspecified
end

x = rawNL(1,:);
y = rawNL(2,:);
[coeff, ~, mu] = polyfit(x, y, degree);
fitNL = struct('coeff', coeff, 'mu', mu);
end

