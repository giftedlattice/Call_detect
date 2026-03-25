function onOK_v7(mainFig)
app = guidata(mainFig);
app.state.accepted = true;
guidata(mainFig, app);
uiresume(mainFig);
end