function plot_solvetime_timeseries(results, labels, Ts, savepath)
% Plot per-step solve time vs time for multiple controllers.

if nargin < 4, savepath = ""; end

figure('Color','w'); hold on; grid on;

for i=1:numel(results)
    r = results{i};
    t = r.t(:);
    st = r.solveT(:);

    st_ms = 1000*st;

    % align with t (solveT usually length = length(U) = length(t)-1)
    if numel(st_ms) == numel(t)-1
        tt = t(1:end-1);
    else
        tt = t(1:min(numel(t),numel(st_ms)));
        st_ms = st_ms(1:numel(tt));
    end

    plot(tt, st_ms, 'LineWidth', 1.1);
end

yline(1000*Ts,'--',sprintf('%.0f ms budget',1000*Ts));
xlabel('t [s]');
ylabel('Solve time [ms]');
title('Per-step solve time over time');
legend(labels,'Location','best');

if strlength(savepath) > 0
    % exportgraphics(gcf, savepath, 'Resolution', 250);
end
end
