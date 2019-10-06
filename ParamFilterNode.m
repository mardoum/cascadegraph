classdef ParamFilterNode < ParameterizedNode
    
    properties
        % free params
        numFilt             % scaling factor
        tauR                % rising phase time constant
        tauD                % dampening time constant
        tauP                % period
        phi                 % phase
        
        % needed if returnOutput will be called
        dt_stored           % time step
    end
    
    properties (Constant)
        freeParamNames = {'numFilt', 'tauR', 'tauD', 'tauP', 'phi'};
    end
    
    methods
        
        function obj = ParamFilterNode(varargin)  % constructor
            obj@ParameterizedNode(varargin{:});
        end
        
        function filter = getFilter(obj, numPoints, dt)
            params = obj.getFreeParams('struct');
            filter = obj.getFilterWithParams(params, numPoints, dt);
        end
        
    end
    
    methods (Static)
        
        function prediction = runWithParams(params, stim, dt)
            % run with input free params, using instance properties for fixed params
            if size(stim,1) < size(stim,2)
                stim = stim';
                transpose = true;
            else
                transpose = false;
            end
            
            filter = ParamFilterNode.getFilterWithParams(params, length(stim), dt);
            
            prediction = real(ifft(fft(stim) .* fft(filter)));
            if transpose
                prediction = prediction';
            end
        end
        
        function filter = getFilterWithParams(params, numPoints, dt)
            t = ((1:numPoints) * dt)';
            filter = (((t./abs(params.tauR)) .^ params.numFilt) ./ (1 + ((t./abs(params.tauR)) .^ params.numFilt))) ...
                .* exp(-((t./params.tauD))) .* cos(((2.*pi.*t) ./ params.tauP) + (2*pi*params.phi/360));
%             filter = filter / max(filter);  % from Fred's version
            filter = filter/max(abs([max(filter) min(filter)]));
        end
        
    end
    
    methods (Access = protected)
        function out = returnOutput(obj, in)
            validateattributes(in, {'cell'}, {'numel', 1});
            assert(~isempty(obj.dt_stored), ...
                'ParamFilterNode.returnOutput() requires dt_stored property to be set')
            out = obj.process(in{1}, obj.dt_stored);
        end
    end
    
end