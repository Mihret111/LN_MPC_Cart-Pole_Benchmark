function make_phase7_taxonomy_plot(T)

root = setup_paths();
figDir = fullfile(root,'figures');
%  fullfile(figDir, "  ->  fullfile(figDir, "
%   .png"   ->  .png")
% exportgraphics(gcf, fullfile(figDir, "F07_success_vs_theta0.png"), 'Resolution', 250);
% exportgraphics(gcf, fullfile(figDir, "F11_Jcl_vs_Np.png"), 'Resolution', 250);
 

if ~exist("figures","dir"), mkdir("figures"); end

% Count labels per controller (simple)
labels = categories(categorical(T.label_at_boundary));
controllers = unique(T.Controller,'stable');

C = zeros(numel(controllers), numel(labels));
for i=1:numel(controllers)
    tc = T(strcmp(T.Controller,controllers{i}),:);
    for j=1:numel(labels)
        C(i,j) = sum(string(tc.label_at_boundary) == string(labels{j}));
    end
end

figure('Color','w');
bar(C,'stacked');
set(gca,'XTick',1:numel(controllers),'XTickLabel',controllers);
legend(labels,'Location','bestoutside');
ylabel('Count');
title('Boundary-run taxonomy across mismatch severities');
exportgraphics(gcf,fullfile(figDir, "F24_failure_taxonomy_vs_mismatch.png"),'Resolution',250);
end
