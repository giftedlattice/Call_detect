function onCancel_v7(mainFig)
if ishandle(mainFig)
    app = guidata(mainFig);
    app.state.accepted = false;
    guidata(mainFig, app);
    uiresume(mainFig);
end
end