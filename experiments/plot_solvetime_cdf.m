function plot_solvetime_cdf(results, labels, Ts, savepath)
% results: cell array of res structs
% labels : cell array of strings
% Ts     : sampling time [s] (for budget line)
% savepath: optional

if nargin < 4, savepath = ""; end

figure('Color','w'); hold on; grid on;

for i=1:numel(results)
    st_ms = 1000 * results{i}.solveT(:);
    st_ms = st_ms(isfinite(st_ms) & st_ms >= 0);

    [f, x] = ecdf(st_ms);
    plot(x, f, 'LineWidth', 1.5);
end

xline(1000*Ts,'--',sprintf('%.0f ms budget',1000*Ts));
xlabel('Solve time [ms]');
ylabel('CDF');
title('Per-step solve time distribution (CDF)');
legend(labels,'Location','best');

if strlength(savepath) > 0
    % exportgraphics(gcf, savepath, 'Resolution', 250);
end
end
