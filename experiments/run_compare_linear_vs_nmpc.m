function [res_lin, res_nmpc, res_casadiNmpc] = run_compare_linear_vs_nmpc()
%RUN_COMPARE_LINEAR_VS_NMPC Quick A/B run using the SAME experiment runner.

cfg = default_config();
cfg.Ts = 0.02;

% Linear MPC
cfg.controller.type = "linear_mpc";
cfg.meta.name = "linear_mpc";
res_lin = run_experiment(cfg);
disp(res_lin.metrics);

% res_fmin=res_lin;
% res_casadiNmpc= res_lin;
    
% % NMPC
% cfg.controller.type = "nmpc";
% cfg.meta.name = "nmpc";
% res_fmin = run_experiment(cfg);
% disp(res_fmin.metrics);

% cfg.Ts = 0.02;
% cfg.Np = 20;
cfg.controller.type = "casadi_nmpc";
res_casadiNmpc = run_experiment(cfg);
disp(res_casadiNmpc.metrics);

% 
% plot_compare_controllers({res_lin,res_fmin,res_casadiNmpc}, ...
%     {'Linear MPC','NMPC (fmincon)','NMPC (CasADi)'}, ...
%     "figures/compare_Ts20ms.png");
% 
% % this is because the solve time is seen to have a considerable difference
% % between the implementations
% plot_solvetime_cdf({res_lin,res_fmin,res_casadiNmpc}, ...
%  {'LMPC','NMPC fmincon','NMPC CasADi'}, ...
%  "figures/solve_cdf_Ts20ms.png");

plot_compare_controllers({res_lin,res_casadiNmpc}, ...
    {'LMPC','NMPC'}, ...
    "figures/compare_Ts20ms.png");

% this is because the solve time is seen to have a considerable difference
% between the implementations
plot_solvetime_cdf({res_lin,res_casadiNmpc}, ...
 {'LMPC','NMPC'}, ...
 "figures/solve_cdf_Ts20ms.png");

end
