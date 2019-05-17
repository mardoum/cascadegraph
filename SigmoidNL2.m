classdef SigmoidNL2 < ParameterizedNode
	% cumulative normal density function fit to NL
    
    properties
		alpha       % maximum conductance
        beta        % sensitivity of NL to generator signal
        gamma       % determines threshold/shoulder location
        epsilon     % shifts all up or down
    end
    
    properties (Constant)
        freeParamNames = {'alpha'; 'beta'; 'gamma'; 'epsilon'}
    end
    
	methods
		function obj = SigmoidNL2(params)  % constructor
			if nargin > 0
                writeFreeParams(obj, params)
			end
        end
    end
    
    methods (Static)
        function out = fn(params, xarray)
            % sigmoid nonlinearity parameterized as cumulative normal density function
            % alpha * normcdf(beta .* xarray + gamma, 0, 1) + epsilon;
            out = params(1) * normcdf(params(2) .* xarray + params(3), 0, 1) + params(4);
        end
    end
    
    methods
        
        function out = process(obj, in)
            params = obj.getFreeParams();
            out = obj.fn(params, in);
        end
        
        function params = optimizeParams(obj, xarray, yarray, params0, lb, ub, options, optimIters)
            narginchk(3,8);  % set defaults
            if nargin < 4
                params0 = [2*max(yarray), 0.1, -1, -1]';
            end
            if nargin < 5
                lb = [-Inf -Inf -Inf -Inf];
            end
            if nargin < 6
                ub = [Inf Inf Inf max(yarray(:))];
            end
            if nargin < 7
                options = optimset('MaxIter', 1500, 'MaxFunEvals', 600*length(params0), 'Display', 'off');
            end
            if nargin < 8
                optimIters = 5;
            end
            
            for optimIter = 1:optimIters
                params = lsqcurvefit(@obj.fn, params0, xarray, yarray, lb, ub, options);
                params0 = params;  % next iteration starts at previous returned
            end
            
            obj.writeFreeParams(params);
        end
        
    end
    
    methods (Access = protected)
        function out = returnOutput(obj, in)
            out = obj.process(in);
        end
    end
    
end
   