function onToggleManual_v7(mainFig)
app = guidata(mainFig);
if isempty(app.state.calls_on)
    return;
end

kDisp = max(1, min(app.state.selectedIdx, numel(app.state.calls_on)));
fixedIdx = app.state.dispToFixed(kDisp);

app.state.manualKeep_fixed(fixedIdx) = ~app.state.manualKeep_fixed(fixedIdx);

[app.state.calls_on, app.state.calls_off, app.state.dispToFixed] = krgui.applyFilter_v7(app.state);

newDisp = find(app.state.dispToFixed == fixedIdx, 1, 'first');
if ~isempty(newDisp)
    app.state.selectedIdx = newDisp;
else
    app.state.selectedIdx = max(1, min(app.state.selectedIdx, max(1, numel(app.state.calls_on))));
end

guidata(mainFig, app);
krgui.redrawAll_v7(mainFig);
end