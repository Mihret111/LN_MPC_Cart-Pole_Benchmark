function plot_roa_map(theta0_grid, thetadot0_grid, Z, title_str, savepath)
%PLOT_ROA_MAP
% Z codes: 0 fail, 1 stable but not deployable, 2 stable+deployable

if nargin < 5, savepath = ""; end

figure('Color','w');
imagesc(thetadot0_grid, theta0_grid, Z);
set(gca,'YDir','normal');
xlabel('\dot{\theta}_0 [rad/s]');
ylabel('\theta_0 [rad]');
title(title_str);

% Discrete colormap: 0,1,2
colormap([0.85 0.25 0.25;   % fail (red-ish)
          0.95 0.80 0.20;   % stable but budget miss (yellow-   ish)
          0.25 0.70 0.35]); % deployable (green-ish)

caxis([-0.5 2.5]);
cb = colorbar;
cb.Ticks = [0 1 2];
cb.TickLabels = {'fail','stable (not RT)','stable + RT'};

grid on;

% exportgraphics(f1, fn, 'Resolution', 300);
% files.theta = fn;
% close(f1);

if strlength(savepath) > 0
    exportgraphics(gcf, savepath, 'Resolution', 250);
end
end
