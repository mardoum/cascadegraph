%% temp tests main

nl = SigmoidNL(1,2,3,4)
properties(nl)

%% 

nl = SigmoidNL2([1,2,3,4])
nl.getFreeParams('struct')
nl.getFreeParams()