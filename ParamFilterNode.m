classdef ParamFilterNode < ParameterizedNode
    % Parameterized temporal filter
    
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
        
        function obj = ParamFilterNode(varargin)
            obj@ParameterizedNode(varargin{:});
        end
        
        function filter = getFilter(obj, numPoints, dt)
            params = obj.getFreeParams('struct');
            filter = obj.getFilterWithParams(params, numPoints, dt);
        end
        
    end
    
    methods (Static)
        
        function prediction = processTempParams(params, stim, dt)
            % run with input free params, using instance properties for fixed params
            filter = ParamFilterNode.getFilterWithParams(params, length(stim), dt);
            prediction = real(ifft(fft(stim') .* fft(filter)))';
        end
        
        function filter = getFilterWithParams(params, numPoints, dt)
            t = ((1:numPoints) * dt)';
            filter = (((t./abs(params.tauR)) .^ params.numFilt) ./ (1 + ((t./abs(params.tauR)) .^ params.numFilt))) ...
                .* exp(-((t./params.tauD))) .* cos(((2.*pi.*t) ./ params.tauP) + (2*pi*params.phi/360));
            filter = filter/max(abs([max(filter) min(filter)]));
        end
        
    end
    
    methods
       
        function fitToExistingFilter(obj, inputFilter, params0, dt)
            OPTIM_ITERS = 3;
            numPoints = length(inputFilter);
            t = ((1:numPoints) * dt);
            for optimIter = 1:OPTIM_ITERS
                params = lsqcurvefit(@tryParams, params0, t, inputFilter);
                params0 = params;  % next iteration starts at previous returned
            end
            
            function out = tryParams(params, ~)
                pstruct = obj.paramVecToStruct(params);
                out = obj.getFilterWithParams(pstruct, numPoints, dt)';
            end
            
            obj.writeFreeParams(params);
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