function [pOpt, Info] = parameterEstimationOfflineDTOptim(p)
%PARAMETERESTIMATIONOFFLINEDTOPTIM
%
% Solve a parameter estimation problem for the offlineDTOptim model.
%
% The function returns estimated parameter values, pOpt,
% and estimation termination information, Info.
%
% The input argument, p, defines the model parameters to estimate,
% if omitted the parameters specified in the function body are estimated.
%
% Modify the function to include or exclude new experiments, or
% to change the estimation options.
%
% Auto-generated by SPETOOL on 22-Mar-2022 02:39:38.
%

%% Open the model.
open_system('offlineDTOptim')

%% Specify Model Parameters to Estimate
%
if nargin < 1 || isempty(p)
    p = sdo.getParameterFromModel('offlineDTOptim',{'C','K','R','alpha'});
    p(1).Minimum = 10;
    p(1).Maximum = 60;
    p(1).Scale = 16;
    p(2).Minimum = 0;
    p(2).Maximum = 1;
    p(3).Minimum = 3.3;
    p(3).Maximum = 3.3;
    p(3).Free = 0;
    p(4).Minimum = 0.02;
    p(4).Maximum = 0.15;
end

%% Define the Estimation Experiments
%

Exp = sdo.Experiment('offlineDTOptim');

%%
% Specify the measured experiment output data.
Exp_Sig_Output_1 = Simulink.SimulationData.Signal;
Exp_Sig_Output_1.Values    = getData('Exp_Sig_Output_1_Value');
Exp_Sig_Output_1.BlockPath = 'offlineDTOptim/Add1';
Exp_Sig_Output_1.PortType  = 'outport';
Exp_Sig_Output_1.PortIndex = 1;
Exp_Sig_Output_1.Name      = 'Peltier system';
Exp_Sig_Output_2 = Simulink.SimulationData.Signal;
Exp_Sig_Output_2.Values    = getData('Exp_Sig_Output_2_Value');
Exp_Sig_Output_2.BlockPath = 'offlineDTOptim/PID Controller1';
Exp_Sig_Output_2.PortType  = 'outport';
Exp_Sig_Output_2.PortIndex = 1;
Exp_Sig_Output_2.Name      = 'Output1';
Exp.OutputData = [Exp_Sig_Output_1; Exp_Sig_Output_2];

%%
% Create a model simulator from an experiment
Simulator = createSimulator(Exp);

%% Create Estimation Objective Function
%
% Create a function that is called at each optimization iteration
% to compute the estimation cost.
%
% Use an anonymous function with one argument that calls offlineDTOptim_optFcn.
optimfcn = @(P) offlineDTOptim_optFcn(P,Simulator,Exp);

%% Optimization Options
%
% Specify optimization options.
Options = sdo.OptimizeOptions;
Options.Method = 'lsqnonlin';
Options.MethodOptions.Algorithm = 'levenberg-marquardt';
Options.OptimizedModel = Simulator;

%% Estimate the Parameters
%
% Call sdo.optimize with the estimation objective function handle,
% parameters to estimate, and options.
[pOpt,Info] = sdo.optimize(optimfcn,p,Options);

%%
% Update the experiments with the estimated parameter values.
Exp = setEstimatedValues(Exp,pOpt);

%% Update Model
%
% Update the model with the optimized parameter values.
sdo.setValueInModel('offlineDTOptim',pOpt);
end

function Vals = offlineDTOptim_optFcn(P,Simulator,Exp)
%OFFLINEDTOPTIM_OPTFCN
%
% Function called at each iteration of the estimation problem.
%
% The function is called with a set of parameter values, P, and returns
% the estimation cost, Vals, to the optimization solver.
%
% See the sdoExampleCostFunction function and sdo.optimize for a more
% detailed description of the function signature.
%

%%
% Define a signal tracking requirement to compute how well the model
% output matches the experiment data.
r = sdo.requirements.SignalTracking(...
    'Method', 'Residuals');
%%
% Update the experiment(s) with the estimated parameter values.
Exp = setEstimatedValues(Exp,P);

%%
% Simulate the model and compare model outputs with measured experiment
% data.

F_r = [];
Simulator = createSimulator(Exp,Simulator);
Simulator = sim(Simulator);

SimLog = find(Simulator.LoggedData,get_param('offlineDTOptim','SignalLoggingName'));
for ctSig=1:numel(Exp.OutputData)
    Sig = find(SimLog,Exp.OutputData(ctSig).Name);
    
    Error = evalRequirement(r,Sig.Values,Exp.OutputData(ctSig).Values);
    F_r = [F_r; Error(:)];
end

%% Return Values.
%
% Return the evaluated estimation cost in a structure to the
% optimization solver.
Vals.F = F_r;
end

function Data = getData(DataID)
%GETDATA
%
% Helper function to store data used by parameterEstimation_offlineDTOptim.
%
% The input, DataID, specifies the name of the data to retrieve. The output,
% Data, contains the requested data.
%

SaveData = load('parameterEstimation_offlineDTOptim_Data');
Data = SaveData.Data.(DataID);
end
