classdef SigmoidNlNode < ParameterizedNode
	% Nonlinearity described by cumulative normal density function.
    
    properties
		alpha       % determines maximum
        beta        % determines steepness
        gamma       % determines threshold/shoulder location
        epsilon     % shifts all up or down
    end
    
    properties (Constant)
        freeParamNames = {'alpha'; 'beta'; 'gamma'; 'epsilon'}
    end
    
	methods
        
		function obj = SigmoidNlNode(varargin)
            obj@ParameterizedNode(varargin{:});
        end
        
    end
    
    methods (Static)
        
        function out = processTempParams(params, xarray)
            % Sigmoid nonlinearity parameterized as cumulative normal density
            % function:
            %   alpha * normcdf(beta .* xarray + gamma, 0, 1) + epsilon;
            if isstruct(params)
                params = [params.alpha; params.beta; params.gamma; params.epsilon];
            end
            out = params(1) * normcdf(params(2) .* xarray + params(3), 0, 1) + params(4);
        end
        
    end
    
    methods
        
        function params = fitToSample(...
                obj, xarray, yarray, params0, lowerBounds, upperBounds, options, optimIters)

            % Set defaults
            narginchk(3,8);
            if nargin < 8
                optimIters = 5;
                if nargin < 7
                    options = optimset('MaxIter', 1500, 'MaxFunEvals', 2400, ...
                    'Display', 'off');
                    if nargin < 6
                        upperBounds = [Inf Inf Inf max(yarray(:))];
                        if nargin < 5
                            lowerBounds = [-Inf -Inf -Inf -Inf];
                            if nargin < 4
                                params0 = [2*max(yarray), 0.1, -1, -1]';
                            end
                        end
                    end
                end
            end

            % Optimze
            for optimIter = 1:optimIters
                params = lsqcurvefit(@obj.processTempParams, params0, xarray, yarray, ...
                    lowerBounds, upperBounds, options);
                params0 = params;  % next iteration starts at previous returned
            end
            
            obj.writeFreeParams(params);
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            validateattributes(in, {'cell'}, {'numel', 1});
            out = obj.process(in{1});
        end
        
    end
    
end