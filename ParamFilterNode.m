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

		function prediction = process(obj, stim, dt)
            % run with instance properties as parameters
            params = obj.getFreeParams('struct');
            assert(~any(structfun(@isempty, params)), 'execution failed because of empty properties')
            prediction = obj.runWithParams(params, stim, dt);
        end
        
        function fitParams = optimizeParams(obj, params0, stim, response, dt)            
            fitParams = lsqcurvefit(@tryParams, params0, stim, response);
            function prediction = tryParams(params, stim)
                pstruct = obj.paramVecToStruct(params);
                prediction = obj.runWithParams(pstruct, stim, dt);
            end
            obj.writeFreeParams(fitParams)
        end

        function prediction = runWithParams(params, stim, dt)
            % run with input free params, using instance properties for fixed params
            if size(stim,1) < size(stim,2)
                stim = stim';
            end
            t = ((1:length(stim)) * dt)';
            filter = (((t./params.tauR).^params.numFilt)./(1+((t./params.tauR).^params.numFilt))) ...
                .* exp(-((t./params.tauD))) .* cos(((2.*pi.*t)./params.tauP)+(2*pi*params.phi/360));
%             filter = filter / max(filter);  % probably not needed?
            prediction = real(ifft(fft(stim) .* fft(filter)));
        end
        
    end
    
    methods (Access = protected)
        function out = returnOutput(obj, in)
            assert(~isempty(obj.dt_stored), ...
                'ParamFilterNode.returnOutput() requires dt_stored property to be set')
            out = obj.process(in, obj.dt_stored);
        end
    end
    
end