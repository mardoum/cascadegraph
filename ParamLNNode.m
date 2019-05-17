classdef ParamLNNode < ModelNode
    
    properties
        % free params
        numFilt             % scaling factor
        tauR                % rising phase time constant
        tauD                % dampening time constant
        tauP                % period
        phi                 % phase
        nonlinScale
        nonlinMean
        nonlinSD
        nonlinOffset
        
        % needed if returnOutput will be called
        dt_stored           % time step 
    end
    
    methods
        
        function obj = ParamLNNode(params)  % constructor
            if nargin > 0
                if ~isempty(params)
                    obj.writeParamsToSelf(params)     % write free params to self
                end
            end
        end

		function prediction = process(obj, stim, dt)
            % run with instance properties as parameters
            params = obj.getFreeParamsStruct();
            assert(~any(structfun(@isempty, params)), 'execution failed because of empty properties')
            prediction = obj.runWithParams(params, stim, dt);
        end
        
        function fitParams = optimizeParams(obj, params0, stim, response, dt)            
            fitParams = lsqcurvefit(@tryParams, params0, stim, response);
            function prediction = tryParams(params, stim)
                pstruct = obj.paramsVecToStruct(params);
                prediction = obj.runWithParams(pstruct, stim, dt);
            end
            obj.writeParamsToSelf(fitParams)
        end

        function prediction = runWithParams(obj, params, stim, dt)
            % run with input free params, using instance properties for fixed params
            if size(stim,1) < size(stim,2)
                stim = stim';
            end
            t = ((1:length(stim)) * dt)';
            filter = (((t./params.tauR).^params.numFilt)./(1+((t./params.tauR).^params.numFilt))) ...
                .* exp(-((t./params.tauD))) .* cos(((2.*pi.*t)./params.tauP)+(2*pi*params.phi/360));
%             filter = filter / max(filter);  % probably not needed?
            generator = real(ifft(fft(stim) .* fft(filter)));
            
            prediction = params.nonlinScale * ...
                normcdf(generator, params.nonlinMean, abs(params.nonlinSD)) + params.nonlinOffset;
        end
        
        function writeParamsToSelf(obj, params)
            if ~isstruct(params)
                params = obj.paramsVecToStruct(params);
            end
            obj.numFilt = params.numFilt;
            obj.tauR    = params.tauR;
            obj.tauD    = params.tauD;
            obj.tauP    = params.tauP;
            obj.phi     = params.phi;
            obj.nonlinScale  = params.nonlinScale;
            obj.nonlinMean   = params.nonlinMean;
            obj.nonlinSD     = params.nonlinSD;
            obj.nonlinOffset = params.nonlinOffset;
        end
        
        function freeParams = getFreeParamsStruct(obj)
            % return struct with free parameters stored in instance properties
            freeParams.numFilt = obj.numFilt;
            freeParams.tauR    = obj.tauR;
            freeParams.tauD    = obj.tauD;
            freeParams.tauP    = obj.tauP;
            freeParams.phi     = obj.phi;
            freeParams.nonlinScale  = obj.nonlinScale;
            freeParams.nonlinMean   = obj.nonlinMean;
            freeParams.nonlinSD     = obj.nonlinSD;
            freeParams.nonlinOffset = obj.nonlinOffset;
        end
        
    end
    
    methods (Static)
        function pstruct = paramsVecToStruct(pvec)
            pstruct.numFilt = pvec(1);
            pstruct.tauR    = pvec(2);
            pstruct.tauD    = pvec(3);
            pstruct.tauP    = pvec(4);
            pstruct.phi     = pvec(5);
            pstruct.nonlinScale  = pvec(6);
            pstruct.nonlinMean   = pvec(7);
            pstruct.nonlinSD     = pvec(8);
            pstruct.nonlinOffset = pvec(9);
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