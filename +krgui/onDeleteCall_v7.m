function onDeleteCall_v7(mainFig)
% Delete selected call permanently from candidate pool.

app = guidata(mainFig);

if isempty(app.state.calls_on)
    return;
end

kDisp = max(1, min(app.state.selectedIdx, numel(app.state.calls_on)));
fixedIdx = app.state.dispToFixed(kDisp);

keep = true(numel(app.state.calls_on_fixed),1);
keep(fixedIdx) = false;

app.state.calls_on_fixed  = app.state.calls_on_fixed(keep);
app.state.calls_off_fixed = app.state.calls_off_fixed(keep);
app.state.manualKeep_fixed = app.state.manualKeep_fixed(keep);

if isfield(app.state,'bwOk_fixed') && ~isempty(app.state.bwOk_fixed)
    app.state.bwOk_fixed = app.state.bwOk_fixed(keep);
end

if isfield(app.state,'startFreq_manual_fixed_kHz') && ~isempty(app.state.startFreq_manual_fixed_kHz)
    app.state.startFreq_manual_fixed_kHz = app.state.startFreq_manual_fixed_kHz(keep);
end

if isfield(app.state,'endFreq_manual_fixed_kHz') && ~isempty(app.state.endFreq_manual_fixed_kHz)
    app.state.endFreq_manual_fixed_kHz = app.state.endFreq_manual_fixed_kHz(keep);
end

app.state.autoKeep_fixed = krgui.computeAutoKeepMask_v7( ...
    app.env_dB, app.noiseFloor_dB, app.state.thrAboveNoise_dB, ...
    app.state.calls_on_fixed, app.state.calls_off_fixed);

[app.state.calls_on, app.state.calls_off, app.state.dispToFixed] = krgui.applyFilter_v7(app.state);

n = numel(app.state.calls_on);
app.state.selectedIdx = max(1, min(kDisp, max(1,n)));

guidata(mainFig, app);
krgui.redrawAll_v7(mainFig);
end