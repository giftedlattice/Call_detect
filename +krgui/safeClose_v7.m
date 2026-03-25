function safeClose_v7(app)
try, if isfield(app,'listFig') && ishandle(app.listFig), delete(app.listFig); end, catch, end
try, if isfield(app,'mainFig') && ishandle(app.mainFig), delete(app.mainFig); end, catch, end
end