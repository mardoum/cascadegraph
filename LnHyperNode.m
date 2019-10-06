classdef LnHyperNode < ParameterizedNode
    
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
        
        % needed if returnOutput will be called
        dt_stored           % time step 
    end
    
    properties (Access = private)        
        % component nodes
        filter ParamFilterNode
        nonlinearity SigmoidNL
        
        % For convenience relaying input to component nodes 
        input DataNode
    end
    
    properties (Constant)
        freeParamNames = {'numFilt', 'tauR', 'tauD', 'tauP', 'phi', ...
            'alpha', 'beta', 'gamma', 'epsilon'};
    end
    
    methods
        function obj = LnHyperNode(varargin)  % constructor
            obj@ParameterizedNode(varargin{:});
            
            obj.input = DataNode();
            obj.filter = ParamFilterNode();
            obj.nonlinearity = SigmoidNL();
            
            obj.filter.upstream.add(obj.input);
            obj.nonlinearity.upstream.add(obj.filter);
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
        function prediction = runWithParamsStatic(params, stim, dt)
            % run with input free params, using instance properties for fixed params
            if size(stim,1) < size(stim,2)
                stim = stim';
                transpose = true;
            else
                transpose = false;
            end
            
            filter = ParamFilterNode.getFilterWithParams(params, length(stim), dt);
            generator = real(ifft(fft(stim) .* fft(filter)));
            prediction = SigmoidNL.runWithParams(...
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