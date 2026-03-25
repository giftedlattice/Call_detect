function wireCallbacks_v7(mainFig)
% wireCallbacks_v7 Attach callbacks. Callbacks operate via guidata(mainFig).

app = guidata(mainFig);

% Main controls
app.sld.Callback   = @(~,~) krgui.onThrChanged_v7(mainFig);
app.btnOK.Callback = @(~,~) krgui.onOK_v7(mainFig);
app.btnX.Callback  = @(~,~) krgui.onCancel_v7(mainFig);

% List controls
app.btnAdd.Callback    = @(~,~) krgui.onAddButton_v7(mainFig);   % time-entry Add
app.btnToggle.Callback = @(~,~) krgui.onToggleManual_v7(mainFig);
app.btnDelete.Callback = @(~,~) krgui.onDeleteCall_v7(mainFig);

% Table selection
app.tbl.CellSelectionCallback = @(~,evt) krgui.onTableSelection_v7(mainFig, evt);

% IMPORTANT: disable click-to-add (prevents onClickAdd_v7 from firing)
set(mainFig,'WindowButtonDownFcn',[]);

guidata(mainFig, app);
end