function [condsOut, ok] = editConditionsDialog_v7(condsIn)
%EDITCONDITIONSDIALOG_V7 Small dialog to add/remove conditions.

condsIn = string(condsIn(:));
condsIn(condsIn=="") = []; % remove blank from editor view

d = dialog('Name','Edit conditions','Units','normalized','Position',[0.35 0.35 0.30 0.40]);

uicontrol(d,'Style','text','Units','normalized','Position',[0.05 0.90 0.90 0.08], ...
    'String','Conditions list (add/remove):','HorizontalAlignment','left');

lst = uicontrol(d,'Style','listbox','Units','normalized','Position',[0.05 0.30 0.90 0.60], ...
    'String', cellstr(condsIn), 'FontSize',11);

edt = uicontrol(d,'Style','edit','Units','normalized','Position',[0.05 0.20 0.65 0.07], ...
    'String','', 'FontSize',11);

btnAdd = uicontrol(d,'Style','pushbutton','Units','normalized','Position',[0.72 0.20 0.23 0.07], ...
    'String','Add');

btnDel = uicontrol(d,'Style','pushbutton','Units','normalized','Position',[0.05 0.11 0.30 0.07], ...
    'String','Remove');

btnOK = uicontrol(d,'Style','pushbutton','Units','normalized','Position',[0.55 0.04 0.18 0.07], ...
    'String','OK','FontWeight','bold');

btnCancel = uicontrol(d,'Style','pushbutton','Units','normalized','Position',[0.77 0.04 0.18 0.07], ...
    'String','Cancel');

conds = condsIn;

btnAdd.Callback = @(~,~) doAdd();
btnDel.Callback = @(~,~) doDel();
btnOK.Callback = @(~,~) doOK();
btnCancel.Callback = @(~,~) doCancel();

ok = false;
uiwait(d);

if isvalid(d)
    delete(d);
end

condsOut = conds;

    function refreshList()
        lst.String = cellstr(conds);
        if isempty(conds)
            lst.Value = 1;
        else
            lst.Value = max(1, min(lst.Value, numel(conds)));
        end
    end

    function doAdd()
        s = strtrim(string(edt.String));
        if s == ""
            return;
        end
        conds = unique([conds; s], 'stable');
        edt.String = '';
        refreshList();
    end

    function doDel()
        if isempty(conds)
            return;
        end
        idx = max(1, min(lst.Value, numel(conds)));
        conds(idx) = [];
        refreshList();
    end

    function doOK()
        ok = true;
        uiresume(d);
    end

    function doCancel()
        ok = false;
        uiresume(d);
    end
end