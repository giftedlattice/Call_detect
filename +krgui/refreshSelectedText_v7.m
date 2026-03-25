function refreshSelectedText_v7(mainFig)
app = guidata(mainFig);

n = numel(app.state.calls_on);
if n == 0
    app.txtSel.String = 'Selected: (none)';
    guidata(mainFig, app);
    return;
end

k = max(1, min(app.state.selectedIdx, n));
onS  = app.state.calls_on(k);
offS = app.state.calls_off(k);
[onS, offS] = krgui.scrubBounds_v7(onS, offS, app.Nsamp);

tOn  = (onS - 1) / app.fs;
tOff = (offS - 1) / app.fs;
dur_ms = ((offS - onS) + 1) / app.fs * 1000;

app.txtSel.String = sprintf( ...
    'Selected #%d (KEPT)\n on=%d (%.6f s)\n off=%d (%.6f s)\n dur=%.3f ms', ...
    k, onS, tOn, offS, tOff, dur_ms);

guidata(mainFig, app);
end