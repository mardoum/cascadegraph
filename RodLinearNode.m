classdef RodLinearNode < ModelNode
    
    properties
        % free params
        scFact              % Scaling Factor
        tauR                % Rising Phase Time Constant
        tauD                % Dampening Time Constant
        
        % fixed params
        darkCurrent
        
        % needed if returnOutput will be called during recursive traversal of node chain
        dt_stored           % time step 
    end
    
    methods
        
        function obj = RodLinearNode(params, fixed)  % constructor
            if nargin > 0
                if ~isempty(params)
                    obj.writeParamsToSelf(params)     % write free params to self
                end
                
                obj.darkCurrent = fixed.darkCurrent;  % write fixed params to self
            end
        end

		function prediction = process(obj, stim, dt)
            % run with instance properties as parameters
            params = obj.getFreeParamsStruct();
            assert(~any(structfun(@isempty, params)), 'execution failed because of empty properties')
            prediction = obj.runWithParams(params, stim, dt);
        end
        
        function fitParams = optimizeParams(obj, params0, stim, response, dt)
            assert(~isempty(obj.darkCurrent), 'execution failed because obj.darkCurrent is empty');
            
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
            filter = params.scFact .* (((t./params.tauR).^3)./(1+((t./params.tauR).^3))) .* ...
                exp(-((t./params.tauD)));
            prediction = real(ifft(fft(stim) .* fft(filter))) - obj.darkCurrent;
        end
        
        function writeParamsToSelf(obj, params)
            if ~isstruct(params)
                params = obj.paramsVecToStruct(params);
            end
            obj.scFact = params.scFact;
            obj.tauR   = params.tauR;
            obj.tauD   = params.tauD;
        end
        
        function freeParams = getFreeParamsStruct(obj)
            % return struct with free parameters stored in instance properties
            freeParams.scFact = obj.scFact;
            freeParams.tauR   = obj.tauR;
            freeParams.tauD   = obj.tauD;
        end
        
    end
    
    methods (Static)
        function pstruct = paramsVecToStruct(pvec)
            pstruct.scFact = pvec(1);
            pstruct.tauR   = pvec(2);
            pstruct.tauD   = pvec(3);
        end
    end
    
    methods (Access = protected)
        function out = returnOutput(obj, in)
            assert(~isempty(obj.dt_stored), ...
                'RodLinearNode.returnOutput() requires dt_stored property to be set')
            out = obj.process(in, obj.dt_stored);
        end
    end
    
end