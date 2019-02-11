classdef SigmoidNL < ModelNode
	% cumulative normal density function fit to NL
    
    properties
		alpha       % maximum conductance
        beta        % sensitivity of NL to generator signal
        gamma       % determines threshold/shoulder location
        epsilon     % shifts all up or down
    end
    
	methods
		function obj = SigmoidNL(alpha, beta, gamma, epsilon)  % constructor
			if nargin > 0
				obj.alpha   = alpha;
                obj.beta    = beta;
                obj.gamma   = gamma;
                obj.epsilon = epsilon;
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
            params = obj.getParamsVec;
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
            
            obj.writeParamsToSelf(params);
        end
        
        function params = getParamsVec(obj)
            params = [obj.alpha;
                      obj.beta;
                      obj.gamma;
                      obj.epsilon];
        end
        
        function params = getParamsStruct(obj)
            params.alpha   = obj.alpha;
            params.beta    = obj.beta;
            params.gamma   = obj.gamma;
            params.epsilon = obj.epsilon;
        end
        
        function writeParamsToSelf(obj, params)
            if isvector(params)
                obj.alpha   = params(1);
                obj.beta    = params(2);
                obj.gamma   = params(3);
                obj.epsilon = params(4);
            elseif isstruct(params)
                obj.alpha   = params.alpha;
                obj.beta    = params.beta;
                obj.gamma   = params.gamma;
                obj.epsilon = params.epsilon;
            end
        end

    end
    
    methods (Access = protected)
        function out = returnOutput(obj, in)
            out = obj.process(in);
        end
    end
    
end
