function [meta, ok] = promptMeta_v7(defaultMeta)
%PROMPTMETA_V7 Metadata dialog with persistent condition dropdown + editor.

if nargin < 1 || isempty(defaultMeta)
    defaultMeta = struct();
end

% Load conditions list (persistent)
conds = krgui.loadConditions_v7([""]);

% defaults

defBat   = string(getField_(defaultMeta,'bat',"bat1"));
defDate  = string(getField_(defaultMeta,'date',string(datetime('today','Format','yyyy-MM-dd'))));
defTrial = string(getField_(defaultMeta,'trial',"01"));
defCond  = string(getField_(defaultMeta,'condition',""));
defCatch = logical(getField_(defaultMeta,'catchTrial',false));
defTemp  = getField_(defaultMeta,'temperature_C',NaN);
defHum   = getField_(defaultMeta,'humidity_pct',NaN);

% Build dialog
d = dialog('Name','Enter metadata','Units','normalized','Position',[0.33 0.30 0.34 0.45]);

uicontrol(d,'Style','text','Units','normalized','Position',[0.06 0.88 0.25 0.06], ...
    'String','Bat','HorizontalAlignment','left');
edtBat = uicontrol(d,'Style','edit','Units','normalized','Position',[0.33 0.88 0.61 0.06], ...
    'String',char(defBat));

uicontrol(d,'Style','text','Units','normalized','Position',[0.06 0.79 0.25 0.06], ...
    'String','Date (YYYY-MM-DD)','HorizontalAlignment','left');
edtDate = uicontrol(d,'Style','edit','Units','normalized','Position',[0.33 0.79 0.61 0.06], ...
    'String',char(defDate));

uicontrol(d,'Style','text','Units','normalized','Position',[0.06 0.70 0.25 0.06], ...
    'String','Trial','HorizontalAlignment','left');
edtTrial = uicontrol(d,'Style','edit','Units','normalized','Position',[0.33 0.70 0.61 0.06], ...
    'String',char(defTrial));

% Condition dropdown + Edit button
uicontrol(d,'Style','text','Units','normalized','Position',[0.06 0.60 0.25 0.06], ...
    'String','Condition','HorizontalAlignment','left');

popupCond = uicontrol(d,'Style','popupmenu','Units','normalized','Position',[0.33 0.61 0.44 0.06], ...
    'String',cellstr(conds));

btnEditCond = uicontrol(d,'Style','pushbutton','Units','normalized','Position',[0.79 0.61 0.15 0.06], ...
    'String','Edit...');

% Set default condition selection
idx = find(conds == defCond, 1, 'first');
if isempty(idx)
    % if default isn't in list, add it (so it can be selected)
    if defCond ~= ""
        conds = unique([conds; defCond], 'stable');
        popupCond.String = cellstr(conds);
        idx = find(conds == defCond, 1, 'first');
    else
        idx = 1;
    end
end
popupCond.Value = idx;

% Catch trial checkbox
chkCatch = uicontrol(d,'Style','checkbox','Units','normalized','Position',[0.33 0.52 0.61 0.06], ...
    'String','Catch trial', 'Value', double(defCatch));

% Temperature + humidity
uicontrol(d,'Style','text','Units','normalized','Position',[0.06 0.42 0.25 0.06], ...
    'String','Temp (°C)','HorizontalAlignment','left');
edtTemp = uicontrol(d,'Style','edit','Units','normalized','Position',[0.33 0.42 0.61 0.06], ...
    'String',numToStr_(defTemp));

uicontrol(d,'Style','text','Units','normalized','Position',[0.06 0.33 0.25 0.06], ...
    'String','Humidity (%)','HorizontalAlignment','left');
edtHum = uicontrol(d,'Style','edit','Units','normalized','Position',[0.33 0.33 0.61 0.06], ...
    'String',numToStr_(defHum));

% OK / Cancel
btnOK = uicontrol(d,'Style','pushbutton','Units','normalized','Position',[0.54 0.08 0.18 0.10], ...
    'String','OK','FontWeight','bold');
btnCancel = uicontrol(d,'Style','pushbutton','Units','normalized','Position',[0.76 0.08 0.18 0.10], ...
    'String','Cancel');

ok = false;
meta = struct();

btnEditCond.Callback = @(~,~) doEditConditions();
btnOK.Callback = @(~,~) doOK();
btnCancel.Callback = @(~,~) doCancel();

uiwait(d);

if isvalid(d)
    delete(d);
end

    function doEditConditions()
        % Open editor
        [condsNew, okEdit] = krgui.editConditionsDialog_v7(conds);
        if ~okEdit
            return;
        end

        % Always keep a blank option at top
        condsNew = string(condsNew(:));                % force column
        condsNew = condsNew(condsNew ~= "");           % drop blanks
        condsNew = unique(condsNew, 'stable');         % keep order, remove duplicates
        
        conds = [""; condsNew];                        % IMPORTANT: vertical concat (column)

        % Save to config
        krgui.saveConditions_v7(conds);

        % Refresh popup while preserving selection if possible
        current = string(popupCond.String{popupCond.Value});
        popupCond.String = cellstr(conds);
        idx2 = find(conds == current, 1, 'first');
        if isempty(idx2), idx2 = 1; end
        popupCond.Value = idx2;
    end

    function doOK()
        meta = struct();
        meta.bat   = strtrim(string(edtBat.String));
        meta.date  = strtrim(string(edtDate.String));
        meta.trial = strtrim(string(edtTrial.String));

        meta.condition = string(popupCond.String{popupCond.Value});
        meta.catchTrial = logical(chkCatch.Value);

        meta.temperature_C = str2double(strtrim(string(edtTemp.String)));
        if ~isfinite(meta.temperature_C), meta.temperature_C = NaN; end

        meta.humidity_pct = str2double(strtrim(string(edtHum.String)));
        if ~isfinite(meta.humidity_pct), meta.humidity_pct = NaN; end

        % Gentle defaults
        if meta.bat == "", meta.bat = "bat1"; end
        if meta.date == "", meta.date = string(datetime('today','Format','yyyy-MM-dd')); end
        if meta.trial == "", meta.trial = "01"; end

        ok = true;
        uiresume(d);
    end

    function doCancel()
        ok = false;
        meta = struct();
        uiresume(d);
    end
end

% -------------------------
% small helpers
% -------------------------
function v = getField_(s, field, fallback)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    v = s.(field);
else
    v = fallback;
end
end

function s = numToStr_(x)
if isempty(x) || ~isfinite(x)
    s = '';
else
    s = num2str(x);
end
end