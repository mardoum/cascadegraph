classdef RodBiophysNode < ModelNode
	
    properties
        beta
        hillaffinity
        sigma
        phi
        gamma
        eta
        
        betaSlow
        hillcoef
        darkCurrent
    end
    
    properties (Dependent)
        gdark
        cur2ca
        smax
    end
    
    properties (Constant)
        cdark    = 0.5;    % dark calcium concentration (in uM????) <1uM (~300 -500 nM)
        cgmphill = 3;
        cgmp2cur = 10e-3;  % constant relating cGMP to current
    end

	methods
        
		function obj = RodBiophysNode(params)  % constructor
            if nargin > 0
                obj.beta         = params.beta;
                obj.hillaffinity = params.hillaffinity;
                obj.sigma        = params.sigma;
                obj.phi          = params.phi;
                obj.gamma        = params.gamma;
                obj.eta          = params.eta;
                
                obj.hillcoef     = params.hillcoef;
                obj.betaSlow     = params.betaSlow;
                obj.darkCurrent  = params.darkCurrent;
            end
        end

		function response = process(obj, stim, dt)
            numPts=length(stim);
            
            g     = zeros(numPts,1);
            s     = zeros(numPts,1);
            c     = zeros(numPts,1);
            p     = zeros(numPts,1);
            r     = zeros(numPts,1);
            cslow = zeros(numPts,1);
            
            % initial conditions
            g(1) = obj.gdark;
            s(1) = obj.gdark * obj.eta / obj.phi;
            c(1) = obj.cdark;
            p(1) = obj.eta / obj.phi;
            r(1) = 0;
            cslow(1) = obj.cdark;
            
            % difference equations
            for ii = 2:numPts
                r(ii) = r(ii-1) + dt * (-obj.sigma * r(ii-1)) + obj.gamma * stim(ii-1);
                p(ii) = p(ii-1) + dt * (r(ii-1) + obj.eta - obj.phi * p(ii-1));
                % 	c(pnt) = c(pnt-1) + TimeStep * (cur2ca * cgmp2cur * g(pnt-1)^cgmphill - beta * c(pnt-1));
                c(ii) = c(ii-1) + dt * (obj.cur2ca * obj.cgmp2cur * ... 
                    g(ii-1)^obj.cgmphill / (1+(cslow(ii-1)/obj.cdark)) - obj.beta * c(ii-1));
                cslow(ii) = cslow(ii-1) - dt * (obj.betaSlow * (cslow(ii-1)-c(ii-1)));
                s(ii) = obj.smax / (1 + (c(ii) / obj.hillaffinity)^obj.hillcoef);
                g(ii) = g(ii-1) + dt * (s(ii-1) - p(ii-1) * g(ii-1));
            end
            
            % determine current change
            % ios = cgmp2cur * g.^cgmphill * 2 ./ (2 + cslow ./ cdark);
            response = -obj.cgmp2cur * g.^obj.cgmphill * 1 ./ (1 + (cslow ./ ojb.cdark));
        end
        
        function val = get.gdark(obj)
            % gdark and cgmp2cur trade with each other to set dark current
            val = (2 * obj.darkCurrent / obj.cgmp2cur)^(1/obj.cgmphill);
        end
        
        function val = get.cur2ca(obj)
            % get q using steady state
            val = obj.beta * obj.cdark / obj.darkCurrent;
        end
        
        function val = get.smax(obj)
            % get smax using steady state
            val = obj.eta / obj.phi * obj.gdark * (1 + (obj.cdark / obj.hillaffinity)^obj.hillcoef);
        end

    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            out = obj.process(in);
        end
            
    end
    
end