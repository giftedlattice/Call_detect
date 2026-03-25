function redrawAll_v7(mainFig)
app = guidata(mainFig);

% -----------------------------
% Overview envelope (rear only) - improved visibility
% -----------------------------
axes(app.axOverview); cla(app.axOverview);
t = (0:numel(app.env_dB)-1)/app.fs;
envPlot = app.env_dB(:);

plot(app.axOverview, t, envPlot, 'Color', [0.15 0.15 0.15], 'LineWidth', 0.75);
hold(app.axOverview,'on');

thr = app.noiseFloor_dB + app.state.thrAboveNoise_dB;

% Green styling for threshold/accepted visualization
cThr = [0.10 0.65 0.10]; % green
yl = [min(envPlot) max(envPlot)];

% Light green shading above threshold
patch(app.axOverview, ...
    [t(1) t(end) t(end) t(1)], ...
    [thr thr yl(2) yl(2)], ...
    [0.90 1.00 0.90], 'EdgeColor','none', 'FaceAlpha',0.30);

% Threshold line (GREEN dashed)
yline(app.axOverview, thr, '--', 'Color', cThr, 'LineWidth', 2);

% Optional: highlight envelope above threshold in green
above = envPlot > thr;
if any(above)
    envHi = envPlot; envHi(~above) = NaN;
    plot(app.axOverview, t, envHi, 'Color', cThr, 'LineWidth', 1.0);
end

% -----------------------------
% Call dots at the top:
%   - BLUE = kept calls (working list)
%   - RED  = excluded candidates (fail threshold/bandwidth)
% -----------------------------
yTop = yl(2);
yDotKeep = yTop - 0.5;  % blue kept dots
yTxtKeep = yTop - 1.3;  % numbers under kept dots
yDotBad  = yTop - 0.2;  % red excluded dots slightly higher so they are distinct

cKeep = [0.0 0.45 0.85];  % blue
cBad  = [0.85 0.10 0.10]; % red

% ---- 1) Plot KEPT calls (blue dots + numbers)
for kk = 1:numel(app.state.calls_on)
    tt = (app.state.calls_on(kk)-1)/app.fs;

    plot(app.axOverview, tt, yDotKeep, 'o', ...
        'MarkerFaceColor', cKeep, ...
        'MarkerEdgeColor', cKeep, ...
        'MarkerSize', 6);

    text(app.axOverview, tt, yTxtKeep, sprintf('%d',kk), ...
        'HorizontalAlignment','center','VerticalAlignment','top', ...
        'FontSize',9,'FontWeight','bold', ...
        'Color', cKeep, 'Clipping','on');
end

% ---- 2) Plot EXCLUDED candidates (red dots only)
% We infer exclusion from the candidate pool masks.
if isfield(app.state,'calls_on_fixed') && ~isempty(app.state.calls_on_fixed)

    % autoMask includes bandwidth mask if present (same logic as applyFilter_v7)
    autoMask = app.state.autoKeep_fixed(:);
    if isfield(app.state,'bwOk_fixed') && ~isempty(app.state.bwOk_fixed)
        autoMask = autoMask & app.state.bwOk_fixed(:);
    end
    keepMask = autoMask | app.state.manualKeep_fixed(:);

    excludedIdx = find(~keepMask);
    if ~isempty(excludedIdx)
        for ii = 1:numel(excludedIdx)
            j = excludedIdx(ii);
            tt = (app.state.calls_on_fixed(j)-1)/app.fs;

            plot(app.axOverview, tt, yDotBad, 'o', ...
                'MarkerFaceColor', cBad, ...
                'MarkerEdgeColor', cBad, ...
                'MarkerSize', 4);
        end
    end
end

xlabel(app.axOverview,'Time (s)');
ylabel(app.axOverview,'Env (dB)');

% Refresh list window + selected view
krgui.refreshTable_v7(mainFig);
krgui.refreshSelectedText_v7(mainFig);
krgui.redrawSelected_v7(mainFig);

hold(app.axOverview,'off');
end