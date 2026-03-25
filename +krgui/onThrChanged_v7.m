function onThrChanged_v7(mainFig)
app = guidata(mainFig);

app.state.thrAboveNoise_dB = app.sld.Value;
app.txtThr.String = sprintf('%.1f dB', app.state.thrAboveNoise_dB);

% Threshold-only keep mask (bw filter applied in applyFilter_v7)
app.state.autoKeep_fixed = krgui.computeAutoKeepMask_v7( ...
    app.env_dB, app.noiseFloor_dB, app.state.thrAboveNoise_dB, ...
    app.state.calls_on_fixed, app.state.calls_off_fixed);

[app.state.calls_on, app.state.calls_off, app.state.dispToFixed] = krgui.applyFilter_v7(app.state);

n = numel(app.state.calls_on);
app.state.selectedIdx = max(1, min(app.state.selectedIdx, max(1,n)));

guidata(mainFig, app);
krgui.redrawAll_v7(mainFig);
end