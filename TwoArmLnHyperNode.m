classdef TwoArmLnHyperNode < HyperNode
    % Full two-arm linear-nonlinear cascade model. This HyperNode comprises
    % other nodes.
    
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
        
        % needed if returnOutput will be called
        dt_stored           % time step 
    end
    
    properties (Constant)
        freeParamNames = {...
            'numFilt1', 'tauR1', 'tauD1', 'tauP1', 'phi1', ...
            'numFilt2', 'tauR2', 'tauD2', 'tauP2', 'phi2', ...
            'alpha1', 'beta1', 'gamma1', 'epsilon1', ...
            'alpha2', 'beta2', 'gamma2', 'epsilon2'};
    end
    
    methods
        
        function obj = TwoArmLnHyperNode(varargin)
            obj@HyperNode(varargin{:});
        end
        
        function nodeStruct = subnodes(obj)
            % Initialize nodes
            nodeStruct.input = DataNode();
            nodeStruct.filter1 = ParamFilterNode(...
                [obj.numFilt1; obj.tauR1; obj.tauD1; obj.tauP1; obj.phi1]);
            nodeStruct.filter2 = ParamFilterNode(...
                [obj.numFilt2; obj.tauR2; obj.tauD2; obj.tauP2; obj.phi2]);
            nodeStruct.nonlinearity1 = SigmoidNlNode(...
                [obj.alpha1; obj.beta1; obj.gamma1; obj.epsilon1]);
            nodeStruct.nonlinearity2 = SigmoidNlNode(...
                [obj.alpha2; obj.beta2; obj.gamma2; obj.epsilon2]);
            nodeStruct.sum = SumNode();
            
            % Construct graph
            nodeStruct.filter1.upstream.add(nodeStruct.input);
            nodeStruct.filter2.upstream.add(nodeStruct.input);
            nodeStruct.nonlinearity2.upstream.add(nodeStruct.filter2);
            nodeStruct.sum.upstream.add(nodeStruct.filter1);
            nodeStruct.sum.upstream.add(nodeStruct.nonlinearity2);
            nodeStruct.nonlinearity1.upstream.add(nodeStruct.sum);
        end
        
        function prediction = processTempParams(obj, params, stim, dt)
            % run with input free params, using instance properties for fixed params
            if size(stim,1) < size(stim,2)
                stim = stim';
                transpose = true;
            else
                transpose = false;
            end
            obj.subnodesProtected.input.data = stim;
            obj.subnodesProtected.filter1.dt_stored = dt;
            obj.subnodesProtected.filter2.dt_stored = dt;
            
            obj.subnodesProtected.filter1.writeFreeParams(...
                [params.numFilt1; params.tauR1; params.tauD1; params.tauP1; params.phi1]);
            obj.subnodesProtected.filter2.writeFreeParams(...
                [params.numFilt2; params.tauR2; params.tauD2; params.tauP2; params.phi2]);
            obj.subnodesProtected.nonlinearity1.writeFreeParams(...
                [params.alpha1; params.beta1; params.gamma1; params.epsilon1]);
            obj.subnodesProtected.nonlinearity2.writeFreeParams(...
                [params.alpha2; params.beta2; params.gamma2; params.epsilon2]);
            
            prediction = obj.subnodesProtected.nonlinearity1.processUpstream();
            
            if transpose
                prediction = prediction';
            end
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            validateattributes(in, {'cell'}, {'numel', 1});
            assert(~isempty(obj.dt_stored), ...
                'TwoArmLnHyperNode.returnOutput() requires dt_stored property to be set')
            out = obj.process(in{1}, obj.dt_stored);
        end
        
    end
    
end