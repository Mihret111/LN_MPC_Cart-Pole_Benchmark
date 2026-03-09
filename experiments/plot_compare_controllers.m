function plot_compare_controllers(results, labels, savepath)
%PLOT_COMPARE_CONTROLLERS Overlay multiple controller results on one figure.
%
% results : cell array of res structs
% labels  : cell array of strings (same length as results)
% savepath: optional string, e.g. "figures/compare_Ts20ms.png"

if nargin < 3, savepath = ""; end

% --- Validate ---
assert(iscell(results) && numel(results)>=2, "results must be a cell array with >=2 elements");
assert(numel(labels)==numel(results), "labels length must match results length");

% --- Figure layout ---
figure('Name','Controller comparison','Color','w');
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

% Helper for aligning U/solveT with time
    function tt = align_time(r, y)
        t = r.t(:);
        y = y(:);
        if numel(y) == numel(t)-1
            tt = t(1:end-1);
        elseif numel(y) == numel(t)
            tt = t;
        else
            % fallback: interpolate or truncate to min
            n = min(numel(t), numel(y));
            tt = t(1:n);
        end
    end

% ---- (1) Theta overlay ----
ax1 = nexttile;
hold on; grid on;
for i=1:numel(results)
    r = results{i};
    plot(r.t, r.X(3,:), 'LineWidth', 1.2);
end
yline(0,'--');
xlabel('t [s]'); ylabel('\theta [rad]');
title('\theta(t) (upright = 0)');
% legend(labels,'Location','best');

ax_in_1=add_inset_snapshot(ax1, [10 25], [-0.2 0.2]);
place_legend_avoid_inset(ax1, labels, ax_in_1);
%%

%%
% ---- (2) Cart position overlay ----
ax2 = nexttile;
hold on; grid on;
for i=1:numel(results)
    r = results{i};
    plot(r.t, r.X(1,:), 'LineWidth', 1.2);
end
xlabel('t [s]'); ylabel('p [m]');
title('Cart position p(t)');
legend(labels,'Location','best');

ax_in_2=add_inset_snapshot(ax2, [10 25], [-1 1]);
% place_legend_avoid_inset(ax2, labels, ax_in_2);

% ---- (3) Control input overlay ----
% ---- (3) Control input overlay + ONE disturbance ----
nexttile;
hold on; grid on;

% Plot controller commands u(t)
for i=1:numel(results)
    r = results{i};
    tt = align_time(r, r.U);
    plot(tt, r.U(:), 'LineWidth', 1.4);
end

% Plot disturbance ONCE (same for both controllers)
r0 = results{1};
if isfield(r0,'D')
    ttD = align_time(r0, r0.D);
    plot(ttD, r0.D(:), '--', 'LineWidth', 1.2);  % one d(t)
end

xlabel('t [s]');
ylabel('force [N]');
title('Control input u(t) with disturbance d(t)');

% Legend: u for each controller + one d(t)
if isfield(r0,'D')
    legend([labels, "d(t)"], 'Location', 'best');
else
    legend(labels, 'Location', 'best');
end

%%%
% Shade disturbance application interval (horizontal marking)
if isfield(r0,'cfg') && isfield(r0.cfg,'disturb') && isfield(r0.cfg.disturb,'enabled') && r0.cfg.disturb.enabled
    t0 = r0.cfg.disturb.t0;

    % Decide interval based on type
    typ = lower(string(r0.cfg.disturb.type));

    yl = ylim;  % current y-limits
    switch typ
        case "pulse"
            T = r0.cfg.disturb.T;
            x1 = t0;
            x2 = t0 + T;

        case {"step","sine"}
            % step/sine start at t0 and persist to end
            x1 = t0;
            x2 = r0.t(end);

        otherwise
            x1 = t0;
            x2 = t0; % fallback
    end

    % draw a light band showing when disturbance is "active"
    hDistBand = patch([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], [0 0 0], ...
    'FaceAlpha', 0.06, 'EdgeColor', 'none', ...
    'DisplayName', 'd(t) active');

    legend('show');   % or legend('Location','best')
    % If you ONLY want the start time shown (your preference):
    if typ == "step"
        % keep only a start marker (optional: remove if you want pure shading)
        text(t0, yl(2), '  t_0', 'VerticalAlignment','top');
    end
end

% ---- (4) Solve time overlay (ms) + budget line ----
ax4 = nexttile;
hold on; grid on;
for i=1:numel(results)
    r = results{i};
    tt = align_time(r, r.solveT);
    plot(tt, 1000*r.solveT(:), 'LineWidth', 1.2);
end
yline(20,'--','20 ms budget');
xlabel('t [s]'); ylabel('solve time [ms]');
title('Per-step solve time');
legend(labels,'Location','best');

ax_in_4 = add_inset_snapshot(ax4, [10 25], [0 40]);
% place_legend_avoid_inset(ax4, labels, ax_in_4);
% --- Save if requested ---
if strlength(savepath) > 0
    exportgraphics(gcf, savepath, 'Resolution', 200);
end

end
function ax_in = add_inset_snapshot(ax_main, xl, yl)
    % Add an inset axes inside ax_main, showing [xl],[yl]
    fig = ancestor(ax_main,'figure');

    % Position inset relative to the tile axes position (normalized)
    oldUnits = ax_main.Units;
    ax_main.Units = 'normalized';
    p = ax_main.Position;

    % Inset size + margin (tweak if you want)
    w = 0.38 * p(3);
    h = 0.38 * p(4);
    m = 0.03 * p(3);   % <-- you were using m but it was commented out

    % WEST (center-left) inset inside the tile
    dx = 0.04 * p(3);   % shift left by 4% of the main axes width (tune this)
    pos = [p(1) + m - dx,  p(2) + 0.5*(p(4)-h),  w, h];
    ax_in = axes('Parent', fig, 'Units','normalized', 'Position', pos);
    box(ax_in,'on'); grid(ax_in,'on'); hold(ax_in,'on');

    % Copy everything drawn in main axes into inset
    copyobj(allchild(ax_main), ax_in);

    % Apply your requested zoom window
    xlim(ax_in, xl);
    ylim(ax_in, yl);

    % Make inset look clean
    ax_in.FontSize  = max(7, ax_main.FontSize - 2);
    ax_in.LineWidth = 0.8;

    % ---- TICKS INSIDE (this is what you asked) ----
    ax_in.TickDir    = 'in';          % ticks point inward (x + y)
    ax_in.TickLength = [0.02 0.02];   % tweak if you want shorter/longer
    ax_in.Layer      = 'top';         % ticks/grid drawn on top of graphics

    % ---- OPTIONAL: move tick LABELS inside (numbers inside) ----
    % Works in newer MATLAB. If not supported, it just won't run.
    try
        ax_in.YRuler.TickLabelGapOffset = 0.2;   % negative pulls labels inward
        % ax_in.XRuler.TickLabelGapOffset = -8;
    catch
        % Older MATLAB: ignore
    end

    % restore
    ax_main.Units = oldUnits;

    % return focus to main axes
    axes(ax_main); %#ok<LAXES>
end

function place_legend_avoid_inset(ax, labels, ax_in)
    lg = legend(ax, labels, 'Location','best'); % create it first
    drawnow;

    % rectangles in normalized figure units
    old1 = lg.Units; old2 = ax_in.Units;
    lg.Units = 'normalized';
    ax_in.Units = 'normalized';
    insetPos = ax_in.Position;

    candidates = {'northeast','northwest','southeast','southwest','north','south','east','west','best'};
    bestLoc = 'best';
    bestOverlap = inf;

    for k = 1:numel(candidates)
        lg.Location = candidates{k};
        drawnow;
        lp = lg.Position;

        % compute overlap area between [x y w h] rectangles
        ov = rectOverlapArea(lp, insetPos);
        if ov == 0
            bestLoc = candidates{k};
            bestOverlap = 0;
            break;
        elseif ov < bestOverlap
            bestOverlap = ov;
            bestLoc = candidates{k};
        end
    end

    lg.Location = bestLoc;

    lg.Units = old1; ax_in.Units = old2;
end

function a = rectOverlapArea(r1, r2)
    x1 = max(r1(1), r2(1));
    y1 = max(r1(2), r2(2));
    x2 = min(r1(1)+r1(3), r2(1)+r2(3));
    y2 = min(r1(2)+r1(4), r2(2)+r2(4));
    a = max(0, x2-x1) * max(0, y2-y1);
end