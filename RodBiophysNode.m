classdef RodBiophysNode < ParameterizedNode
    % Biophysical model of rod photoreceptor.
    
    properties
        % Free params
        beta                % rate constant for removal of Ca from outer segment
        hillaffinity        % affinity for Ca2+ (also called K?) (~0.5*dark Calcium)
        sigma               % decay rate constant for rhodopsin activity (1/sec) (~100/sec)
        gamma
        eta                 % activation rate constant PDE (1/sec) (>100/sec) (juan: "PDE dark activity")
        % phi (decay rate constant for phosphodiesterase activity (1/sec) (~30-100/sec)) always set = to alpha
        
        % Fixed params
        betaSlow
        hillcoef            % effective Ca2+ cooperativity to GC (2-4)
        darkCurrent         % determined with saturating flash
        
        dt_stored           % timestep size, should not be empty if upstream node is assigned
    end
    
    properties (Constant)
        cdark    = 0.5;    % dark calcium concentration (in uM????) <1uM (~300 -500 nM)
        cgmphill = 3;      % apparent cooperativity cGMP
        cgmp2cur = 10e-3;  % constant relating cGMP to current (k in Juan's thesis "product of the maximal current and the channel affinity for cGMP")
        
        freeParamNames = {'beta', 'hillaffinity', 'sigma', 'gamma', 'eta'};
    end
    
    methods
        
        function obj = RodBiophysNode(varargin)
            obj@ParameterizedNode(varargin{:});
        end

        function prediction = processTempParams(obj, params, stim, dt)
            % Use input free params and stored fixed params
            if ~isstruct(params)
                params = obj.paramVecToStruct(params);
            end
            
            phi = params.sigma;
            gdark = (2 * obj.darkCurrent / obj.cgmp2cur)^(1/obj.cgmphill);  % gdark and cgmp2cur trade with each other to set dark current
            cur2ca = params.beta * obj.cdark / obj.darkCurrent;             % also called q - q and smax calculated from steady state
            smax = params.eta / phi * gdark * (1 + (obj.cdark / params.hillaffinity)^obj.hillcoef);

            numPts=size(stim, 2);                                % pre-allocate
            r     = zeros(numPts, 1);  % activity of opsin molecules
            p     = zeros(numPts, 1);  % activity of PDE
            g     = zeros(numPts, 1);  % concentration of cGMP
            c     = zeros(numPts, 1);
            s     = zeros(numPts, 1);  % rate of cGMP synthesis
            cslow = zeros(numPts, 1);
            
            r(1) = 0;                                           % initialize
            p(1) = params.eta / phi;
            g(1) = gdark;
            c(1) = obj.cdark;
            s(1) = gdark * params.eta / phi;
            cslow(1) = obj.cdark;
                                                                % difference equations
            for i = 2:numPts
                r(i) = r(i-1) + dt * (-params.sigma * r(i-1)) + params.gamma * stim(i-1);
                p(i) = p(i-1) + dt * (r(i-1) + params.eta - phi * p(i-1));
                g(i) = g(i-1) + dt * (s(i-1) - p(i-1) * g(i-1));
                % 	c(pnt) = c(pnt-1) + TimeStep * (cur2ca * cgmp2cur * g(pnt-1)^cgmphill - beta * c(pnt-1));
%                 I = obj.cgmp2cur * g(i-1)^obj.cgmphill;
                I = obj.cgmp2cur * g(i-1)^obj.cgmphill / (1 + (cslow(i-1) / obj.cdark));
                c(i) = c(i-1) + dt * (cur2ca * I - params.beta * c(i-1));
                s(i) = smax / (1 + (c(i) / params.hillaffinity)^obj.hillcoef);
                cslow(i) = cslow(i-1) - dt * obj.betaSlow * (cslow(i-1) - c(i-1));
            end

            % Determine current change
            % ios = cgmp2cur * g.^cgmphill * 2 ./ (2 + cslow ./ cdark);
            prediction = -obj.cgmp2cur * g.^obj.cgmphill ./ (1 + cslow ./ obj.cdark);
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            validateattributes(in, {'cell'}, {'numel', 1});
            assert(~isempty(obj.dt_stored), ...
                'RodBiophysNode.returnOutput() requires dt_stored property to be set')
            out = obj.process(in{1}, obj.dt_stored);
        end
        
    end
    
end