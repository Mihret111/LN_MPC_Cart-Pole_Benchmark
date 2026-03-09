function files = plot_experiment(res, base)
%PLOT_EXPERIMENT Create and save standard figures.

root = setup_paths();
figDir = fullfile(root,'figures');

t = res.t;
X = res.X;
U = res.U;
solveT = res.solveT;

files = struct();

% Theta
figure('Visible','off');
plot(t, X(3,:)); grid on;
xlabel('t [s]'); ylabel('\theta [rad]');
title('MPC on nonlinear plant (upright is 0)');
fn = fullfile(figDir, base + "_theta.png");
%exportgraphics(f1, fn, 'Resolution', 300);
files.theta = fn;
% close(f1);

% Cart position
figure('Visible','off');
plot(t, X(1,:)); grid on;
xlabel('t [s]'); ylabel('p [m]');
title('Cart position');
fn = fullfile(figDir, base + "_p.png");
%exportgraphics(f2, fn, 'Resolution', 300);
files.p = fn;
% close(f2);

% Control force
figure('Visible','off');
stairs(t(1:end-1), U); grid on;
xlabel('t [s]'); ylabel('u [N]');
title('Control force');
fn = fullfile(figDir, base + "_u.png");
%exportgraphics(f3, fn, 'Resolution', 300);
files.u = fn;
% close(f3);

% Solve time
figure('Visible','off');
plot(t(1:end-1), solveT*1000); grid on;
xlabel('t [s]'); ylabel('solve time [ms]');
title('Solve time per step');
fn = fullfile(figDir, base + "_solve.png");
%exportgraphics(f4, fn, 'Resolution', 300);
files.solve = fn;
% close(f4);

% Print stats to console too (nice for quick sanity)
fprintf('Fallback steps: %d / %d\n', res.metrics.fallback_steps, res.metrics.N_steps);
fprintf('Avg solve time: %.3f ms\n', res.metrics.solve_avg_ms);
fprintf('95%% solve time: %.3f ms\n', res.metrics.solve_p95_ms);
fprintf('Max solve time: %.3f ms\n', res.metrics.solve_max_ms);
end
