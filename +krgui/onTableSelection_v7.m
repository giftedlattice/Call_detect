function onTableSelection_v7(mainFig, evt)
if isempty(evt.Indices)
    return;
end
app = guidata(mainFig);

row = evt.Indices(1);
row = max(1, min(row, numel(app.state.calls_on)));
app.state.selectedIdx = row;

guidata(mainFig, app);
krgui.redrawSelected_v7(mainFig);
krgui.refreshSelectedText_v7(mainFig);
end