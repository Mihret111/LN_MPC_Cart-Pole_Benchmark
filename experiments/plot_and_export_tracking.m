function plot_and_export_tracking(res, tag)
root = setup_paths();                  % your project root / where results/figures live
outdir = fullfile(root, "figures");

if ~exist(outdir, 'dir')
    mkdir(outdir);
end
t = res.t;
X = res.X;
u = res.U;

figure('Color','w');
subplot(3,2,1); plot(t, X(1,:)); grid on; ylabel('p [m]');
subplot(3,2,2); plot(t, X(2,:)); grid on; ylabel('v [m/s]');
subplot(3,2,3); plot(t, X(3,:)); grid on; ylabel('\theta [rad]');
subplot(3,2,4); plot(t, X(4,:)); grid on; ylabel('\omega [rad/s]');
subplot(3,2,5); stairs(t(1:end-1), u); grid on; ylabel('u [N]'); xlabel('t [s]');
subplot(3,2,6); plot((1:numel(res.solveT))*res.cfg.Ts, 1000*res.solveT); grid on; ylabel('solve [ms]'); xlabel('t [s]');

if ~exist("figures","dir"), mkdir("figures"); end
% exportgraphics(gcf, fullfile("figures", tag + ".png"), 'Resolution', 250);
exportgraphics(gcf, fullfile(outdir, tag + ".png"), 'Resolution', 250);
end

