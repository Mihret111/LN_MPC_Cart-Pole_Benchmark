function plot_compare_nominal_vs_mismatch(res_nom_L, res_mis_L, res_nom_N, res_mis_N, savepath)
figure('Color','w'); tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

% helper time align
alignU = @(r) r.t(1:end-1);

% ---- theta ----
nexttile; hold on; grid on;
plot(res_nom_L.t, res_nom_L.X(3,:), 'LineWidth', 1.2);
plot(res_mis_L.t, res_mis_L.X(3,:), '--', 'LineWidth', 1.2);
plot(res_nom_N.t, res_nom_N.X(3,:), 'LineWidth', 1.2);
plot(res_mis_N.t, res_mis_N.X(3,:), '--', 'LineWidth', 1.2);
yline(0,'--');
xlabel('t [s]'); ylabel('\theta [rad]'); title('\theta(t)');
legend({'LMPC nom','LMPC mis','NMPC nom','NMPC mis'}, 'Location','best');

% ---- p ----
nexttile; hold on; grid on;
plot(res_nom_L.t, res_nom_L.X(1,:), 'LineWidth', 1.2);
plot(res_mis_L.t, res_mis_L.X(1,:), '--', 'LineWidth', 1.2);
plot(res_nom_N.t, res_nom_N.X(1,:), 'LineWidth', 1.2);
plot(res_mis_N.t, res_mis_N.X(1,:), '--', 'LineWidth', 1.2);
xlabel('t [s]'); ylabel('p [m]'); title('p(t)');

% ---- u ----
nexttile; hold on; grid on;
plot(alignU(res_nom_L), res_nom_L.U, 'LineWidth', 1.2);
plot(alignU(res_mis_L), res_mis_L.U, '--', 'LineWidth', 1.2);
plot(alignU(res_nom_N), res_nom_N.U, 'LineWidth', 1.2);
plot(alignU(res_mis_N), res_mis_N.U, '--', 'LineWidth', 1.2);
xlabel('t [s]'); ylabel('u [N]'); title('u(t)');

% ---- solve time ----
nexttile; hold on; grid on;
plot(alignU(res_nom_L), 1000*res_nom_L.solveT, 'LineWidth', 1.2);
plot(alignU(res_mis_L), 1000*res_mis_L.solveT, '--', 'LineWidth', 1.2);
plot(alignU(res_nom_N), 1000*res_nom_N.solveT, 'LineWidth', 1.2);
plot(alignU(res_mis_N), 1000*res_mis_N.solveT, '--', 'LineWidth', 1.2);
yline(20,'--','20 ms budget');
xlabel('t [s]'); ylabel('solve [ms]'); title('Solve time');

if nargin>=5 && strlength(savepath)>0
    exportgraphics(gcf, savepath, 'Resolution', 250);
end
end
