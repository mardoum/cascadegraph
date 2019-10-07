classdef LnHyperNode < ParameterizedNode
    % Full linear-nonlinear cascade model. This 'hypernode' comprises other
    % nodes.
    
    properties
        % Free params
        % filter:
        numFilt             % scaling factor
        tauR                % rising phase time constant
        tauD                % dampening time constant
        tauP                % period
        phi                 % phase
        % nonlinearity:
		alpha               % maximum conductance
        beta                % sensitivity of NL to generator signal
        gamma               % determines threshold/shoulder location
        epsilon             % shifts all up or down
        
        % component nodes
        filter ParamFilterNode
        nonlinearity SigmoidNlNode
        
        % needed if returnOutput will be called
        dt_stored           % time step 
    end
    
    properties (Access = private)        
        % For convenience relaying input to component nodes 
        input DataNode
    end
    
    properties (Constant)
        freeParamNames = {'numFilt', 'tauR', 'tauD', 'tauP', 'phi', ...
            'alpha', 'beta', 'gamma', 'epsilon'};
    end
    
    methods
        
        function obj = LnHyperNode(varargin)
            obj@ParameterizedNode(varargin{:});
            
            obj.input = DataNode();
            obj.filter = ParamFilterNode();
            obj.nonlinearity = SigmoidNlNode();
            
            obj.filter.upstream.add(obj.input);
            obj.nonlinearity.upstream.add(obj.filter);
        end
    
        function prediction = processTempParams(obj, params, stim, dt)
            if size(stim,1) < size(stim,2)
                stim = stim';
                transpose = true;
            else
                transpose = false;
            end
            obj.input.data = stim;
            obj.filter.dt_stored = dt;
            
            obj.filter.writeFreeParams(...
                [params.numFilt; params.tauR; params.tauD; params.tauP; params.phi]);
            obj.nonlinearity.writeFreeParams(...
                [params.alpha; params.beta; params.gamma; params.epsilon]);
            
            prediction = obj.nonlinearity.processUpstream();
            
            if transpose
                prediction = prediction';
            end
        end
        
    end
    
    methods (Static)
        
        function prediction = processTempParamsStatic(params, stim, dt)
            % run with input free params, using instance properties for fixed params
            if size(stim,1) < size(stim,2)
                stim = stim';
                transpose = true;
            else
                transpose = false;
            end
            
            filter = ParamFilterNode.getFilterWithParams(params, length(stim), dt);
            generator = real(ifft(fft(stim) .* fft(filter)));
            prediction = SigmoidNlNode.processTempParams(...
                [params.alpha params.beta params.gamma params.epsilon], generator);
            
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