classdef RodBiophysNode < ModelNode
    
    properties
        % free params
        beta                % rate constant for removal of Ca from outer segment
        hillaffinity        % affinity for Ca2+ (also called K?) (~0.5*dark Calcium)
        sigma               % decay rate constant for rhodopsin activity (1/sec) (~100/sec)
        phi                 % decay rate constant for phosphodiesterase activity (1/sec) (~30-100/sec)
        gamma
        eta                 % activation rate constant PDE (1/sec) (>100/sec) (juan: "PDE dark activity")
        
        % fixed params
        betaSlow
        hillcoef            % effective Ca2+ cooperativity to GC (2-4)
        darkCurrent         % determined with saturating flash
        
        % should be set if upstream node is assigned
        dt_stored
    end
    
    properties (Constant)
        cdark    = 0.5;    % dark calcium concentration (in uM????) <1uM (~300 -500 nM)
        cgmphill = 3;      % apparent cooperativity cGMP
        cgmp2cur = 10e-3;  % constant relating cGMP to current (k in Juan's thesis "product of the maximal current and the channel affinity for cGMP")
    end
    
    methods
        
        function obj = RodBiophysNode(params, fixed)  % constructor
            if nargin > 0
                if ~isempty(params)
                    obj.writeParamsToSelf(params)   % write free params to self
                end
                
                obj.hillcoef    = fixed.hillcoef;   % write fixed params to self
                obj.betaSlow    = fixed.betaSlow;
                obj.darkCurrent = fixed.darkCurrent;
            end
        end

		function prediction = process(obj, stim, dt)
            % run with instance properties as parameters
            params = obj.getFreeParamsStruct();
            assert(~any(structfun(@isempty, params)), 'execution failed because of empty properties')
            prediction = obj.runWithParams(params, stim, dt);
        end
        
        function fitParams = optimizeParams(obj, params0, stim, response, dt)
            assert(~any(cellfun(@isempty, {obj.betaSlow, obj.hillcoef, obj.darkCurrent})), ...
                'execution failed because of empty properties');
            
            fitParams = lsqcurvefit(@tryParams, params0, stim, response);
            
            function prediction = tryParams(params, stim)
                pstruct = obj.paramsVecToStruct(params);
                prediction = obj.runWithParams(pstruct, stim, dt);
            end
            
            obj.writeParamsToSelf(fitParams)
        end

        function prediction = runWithParams(obj, params, stim, dt)
            % run with input free params, using instance properties for fixed params
            
            gdark = (2 * obj.darkCurrent / obj.cgmp2cur)^(1/obj.cgmphill);  % gdark and cgmp2cur trade with each other to set dark current
            cur2ca = params.beta * obj.cdark / obj.darkCurrent;             % also called q - q and smax calculated from steady state
            smax = params.eta / params.phi * gdark * (1 + (obj.cdark / params.hillaffinity)^obj.hillcoef);

            numPts=length(stim);                                % pre-allocate
            r     = zeros(numPts,1);  % activity of opsin molecules
            p     = zeros(numPts,1);  % activity of PDE
            g     = zeros(numPts,1);  % concentration of cGMP
            c     = zeros(numPts,1);
            s     = zeros(numPts,1);  % rate of cGMP synthesis
            cslow = zeros(numPts,1);
            
            r(1) = 0;                                           % initialize
            p(1) = params.eta / params.phi;
            g(1) = gdark;
            c(1) = obj.cdark;
            s(1) = gdark * params.eta / params.phi;
            cslow(1) = obj.cdark;
                                                                % difference equations
            for ii = 2:numPts
                r(ii) = r(ii-1) + dt * (-params.sigma * r(ii-1)) + params.gamma * stim(ii-1);
                p(ii) = p(ii-1) + dt * (r(ii-1) + params.eta - params.phi * p(ii-1));
                g(ii) = g(ii-1) + dt * (s(ii-1) - p(ii-1) * g(ii-1));
                % 	c(pnt) = c(pnt-1) + TimeStep * (cur2ca * cgmp2cur * g(pnt-1)^cgmphill - beta * c(pnt-1));
%                 I = obj.cgmp2cur * g(ii-1)^obj.cgmphill;
                I = obj.cgmp2cur * g(ii-1)^obj.cgmphill / (1 + (cslow(ii-1) / obj.cdark));
                c(ii) = c(ii-1) + dt * (cur2ca * I - params.beta * c(ii-1));
                s(ii) = smax / (1 + (c(ii) / params.hillaffinity)^obj.hillcoef);
                cslow(ii) = cslow(ii-1) - dt * (obj.betaSlow * (cslow(ii-1) - c(ii-1)));
            end

            % determine current change
            % ios = cgmp2cur * g.^cgmphill * 2 ./ (2 + cslow ./ cdark);
            prediction = -obj.cgmp2cur * g.^obj.cgmphill * 1 ./ (1 + (cslow ./ obj.cdark));
        end
        
        function writeParamsToSelf(obj, params)
            if ~isstruct(params)
                params = obj.paramsVecToStruct(params);
            end
            obj.beta         = params.beta;
            obj.hillaffinity = params.hillaffinity;
            obj.sigma        = params.sigma;
            obj.phi          = params.phi;
            obj.gamma        = params.gamma;
            obj.eta          = params.eta;
        end
        
        function freeParams = getFreeParamsStruct(obj)
            % return struct with free parameters stored in instance properties
            freeParams.beta         = obj.beta;
            freeParams.hillaffinity = obj.hillaffinity;
            freeParams.sigma        = obj.sigma;
            freeParams.phi          = obj.phi;
            freeParams.gamma        = obj.gamma;
            freeParams.eta          = obj.eta;
        end
        
    end
    
    methods (Static)
        function pstruct = paramsVecToStruct(pvec)
            pstruct.beta         = pvec(1);
            pstruct.hillaffinity = pvec(2);
            pstruct.sigma        = pvec(3);
            pstruct.phi          = pvec(3);
            pstruct.gamma        = pvec(4);
            pstruct.eta          = pvec(5);
        end
    end
    
    methods (Access = protected)
        function out = returnOutput(obj, in)
            assert(~isempty(obj.dt_stored), ...
                'RodBiophysNode.returnOutput() requires dt_stored property to be set')
            out = obj.process(in, obj.dt_stored);
        end
    end
    
end