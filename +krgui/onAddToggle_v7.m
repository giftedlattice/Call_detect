function onAddToggle_v7(mainFig)
app = guidata(mainFig);
if app.btnAdd.Value
    app.state.mode = "add";
else
    app.state.mode = "none";
end
guidata(mainFig, app);
end