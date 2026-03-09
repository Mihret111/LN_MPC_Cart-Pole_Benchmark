function make_phase6_success_matrix(T)

% preserve order as they appear in the table
sc = unique(T.scenario, 'stable');
ct = unique(T.controller,'stable');

M = zeros(numel(ct), numel(sc));

for i = 1:numel(ct)
    for j = 1:numel(sc)
        mask = strcmp(T.controller, ct{i}) & strcmp(T.scenario, sc{j});
        if any(mask)
            lab = string(T.label(mask));
            M(i,j) = any(lab == "OK");   % binary 0/1
        else
            M(i,j) = 0;
        end
    end
end

figure('Color','w');
imagesc(M);
colormap(gray);
caxis([0 1]);           % force binary scaling
colorbar;

set(gca,'XTick',1:numel(sc),'XTickLabel',sc,'XTickLabelRotation',35);
set(gca,'YTick',1:numel(ct),'YTickLabel',ct);

title('Success matrix (OK=1, otherwise=0)');
exportgraphics(gcf, "figures/F20_phase6_success_matrix.png", 'Resolution', 250);
end
