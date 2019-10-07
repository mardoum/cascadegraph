classdef PolyfitNlNode < ModelNode
    % Nonlinear transformation described as polynomial evaluation.
    % Does NOT subclass from ParameterizedNode because parameters are stored as vectors, which is
    % incompatible with methods in ParameterizedNode.
    
    properties
        coeff
        mu
    end
    
    properties (Dependent)
        degree
    end
    
    methods
        
        function obj = PolyfitNlNode(coeff, mu)
            if nargin > 0
                assert(isvector(coeff) && isvector(mu), ...
                    'error: coeff and mu must be passed to constructor together and must be vectors');
                obj.coeff = coeff;
                obj.mu = mu;
            end
        end
        
        function out = process(obj, input)
            out = polyval(obj.coeff, input, [], obj.mu);
        end
        
        function optimizeParams(obj, nlX, nlY, degree)
            [fitCoeff, ~, fitMu] = polyfit(nlX, nlY, degree);
            obj.coeff = fitCoeff;
            obj.mu = fitMu;
        end
        
        function val = get.degree(obj)
            val = length(obj.coeff) - 1;
        end
        
    end
    
    methods (Access = protected)
        function out = returnOutput(obj, in)
            validateattributes(in, {'cell'}, {'numel', 1});
            out = obj.process(in{1});
        end
    end

end