classdef TwoArmLnHyperNode < ParameterizedNode
    
    properties
        % Free params
        % filter1:
        numFilt1             % scaling factor
        tauR1                % rising phase time constant
        tauD1                % dampening time constant
        tauP1                % period
        phi1                 % phase
        % filter2:
        numFilt2
        tauR2
        tauD2
        tauP2
        phi2
        % nonlinearity1:
		alpha1               % maximum conductance
        beta1                % sensitivity of NL to generator signal
        gamma1               % determines threshold/shoulder location
        epsilon1             % shifts all up or down
        % nonlinearity2:
		alpha2
        beta2
        gamma2
        epsilon2
        
        % component nodes
        filter1 ParamFilterNode
        filter2 ParamFilterNode
        nonlinearity1 SigmoidNL
        nonlinearity2 SigmoidNL
        
        % needed if returnOutput will be called
        dt_stored           % time step 
    end
    
    properties (Access = private)        
        % hidden component nodes
%         signFlip NegativeNode
        sum SumNode
        
        % For convenience relaying input to component nodes 
        input DataNode
    end
    
    properties (Constant)
        freeParamNames = {...
            'numFilt1', 'tauR1', 'tauD1', 'tauP1', 'phi1', ...
            'numFilt2', 'tauR2', 'tauD2', 'tauP2', 'phi2', ...
            'alpha1', 'beta1', 'gamma1', 'epsilon1', ...
            'alpha2', 'beta2', 'gamma2', 'epsilon2'};
    end
    
    methods
        function obj = TwoArmLnHyperNode(varargin)  % constructor
            obj@ParameterizedNode(varargin{:});
            
            obj.input = DataNode();
            
            obj.filter1 = ParamFilterNode();
            obj.filter2 = ParamFilterNode();
            obj.nonlinearity1 = SigmoidNL();
            obj.nonlinearity2 = SigmoidNL();
%             obj.signFlip = NegativeNode();
            obj.sum = SumNode();
            
            obj.filter1.upstream.add(obj.input);
            obj.filter2.upstream.add(obj.input);
            obj.nonlinearity2.upstream.add(obj.filter2);
%             obj.signFlip.upstream.add(obj.nonlinearity2);
            obj.sum.upstream.add(obj.filter1);
%             obj.sum.upstream.add(obj.signFlip);
            obj.sum.upstream.add(obj.nonlinearity2); %%%
            obj.nonlinearity1.upstream.add(obj.sum);
        end
    end
    
    methods
        function prediction = runWithParams(obj, params, stim, dt)
            % run with input free params, using instance properties for fixed params
            if size(stim,1) < size(stim,2)
                stim = stim';
                transpose = true;
            else
                transpose = false;
            end
            obj.input.data = stim;
            obj.filter1.dt_stored = dt;
            obj.filter2.dt_stored = dt;
            
            obj.filter1.writeFreeParams(...
                [params.numFilt1; params.tauR1; params.tauD1; params.tauP1; params.phi1]);
            obj.filter2.writeFreeParams(...
                [params.numFilt2; params.tauR2; params.tauD2; params.tauP2; params.phi2]);
            obj.nonlinearity1.writeFreeParams(...
                [params.alpha1; params.beta1; params.gamma1; params.epsilon1]);
            obj.nonlinearity2.writeFreeParams(...
                [params.alpha2; params.beta2; params.gamma2; params.epsilon2]);
            
            prediction = obj.nonlinearity1.processUpstream();
            
            if transpose
                prediction = prediction';
            end
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