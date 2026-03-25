function refreshTable_v7(mainFig)
app = guidata(mainFig);

% Choose a fixed linear scale for power display (constant across all files)
SCALE = 1e9;
SCALE_LABEL = sprintf('(x%.0e)', SCALE);

% If nothing kept, show empty table with export column headers (+ display cols)
if isempty(app.state.calls_on)
    T = kr.deriveCallTable_full(app.sig, app.fs, struct([]), app.meta, app.opts);

    Tdisp = addAmpDisplayColumns(T, SCALE);

    app.tbl.Data = cell(0, width(Tdisp));
    app.tbl.ColumnName = Tdisp.Properties.VariableNames;

    try, app.tbl.ColumnWidth = 'auto'; catch, end
    guidata(mainFig, app);
    return;
end

% Build calls struct from WORKING list (kept calls only)
n = numel(app.state.calls_on);
calls = repmat(struct( ...
    'on_samp',[], ...
    'off_samp',[], ...
    'startFreq_manual_kHz',NaN, ...
    'endFreq_manual_kHz',NaN), n, 1);

for k = 1:n
    fixedIdx = app.state.dispToFixed(k);

    calls(k).on_samp  = app.state.calls_on(k);
    calls(k).off_samp = app.state.calls_off(k);

    if isfield(app.state,'startFreq_manual_fixed_kHz') && numel(app.state.startFreq_manual_fixed_kHz) >= fixedIdx
        calls(k).startFreq_manual_kHz = app.state.startFreq_manual_fixed_kHz(fixedIdx);
    end

    if isfield(app.state,'endFreq_manual_fixed_kHz') && numel(app.state.endFreq_manual_fixed_kHz) >= fixedIdx
        calls(k).endFreq_manual_kHz = app.state.endFreq_manual_fixed_kHz(fixedIdx);
    end
end

% Generate export-accurate table
T = kr.deriveCallTable_full(app.sig, app.fs, calls, app.meta, app.opts);

% Build a DISPLAY table
Tdisp = addAmpDisplayColumns(T, SCALE);

% Convert to cell for uitable and sanitize types
data = table2cell(Tdisp);
data = sanitizeForUITable(data);

% Apply to UI
app.tbl.Data = data;

vars = Tdisp.Properties.VariableNames;
vars = annotateScaledHeaders(vars, SCALE_LABEL);
app.tbl.ColumnName = vars;

try, app.tbl.ColumnWidth = 'auto'; catch, end
guidata(mainFig, app);
end

% =====================================================================
% Helpers
% =====================================================================
function Tdisp = addAmpDisplayColumns(T, SCALE)
Tdisp = T;

ampNames = {'peakAmp_rear','peakAmp_left','peakAmp_right'};
for i = 1:numel(ampNames)
    nm = ampNames{i};
    if ~ismember(nm, Tdisp.Properties.VariableNames)
        return;
    end
end

Tdisp.peakAmp_rear_scaled  = Tdisp.peakAmp_rear  * SCALE;
Tdisp.peakAmp_left_scaled  = Tdisp.peakAmp_left  * SCALE;
Tdisp.peakAmp_right_scaled = Tdisp.peakAmp_right * SCALE;

Tdisp.peakAmp_rear_dB  = toDbSafe(Tdisp.peakAmp_rear);
Tdisp.peakAmp_left_dB  = toDbSafe(Tdisp.peakAmp_left);
Tdisp.peakAmp_right_dB = toDbSafe(Tdisp.peakAmp_right);

origVars = T.Properties.VariableNames;
extraVars = {'peakAmp_rear_scaled','peakAmp_left_scaled','peakAmp_right_scaled', ...
             'peakAmp_rear_dB','peakAmp_left_dB','peakAmp_right_dB'};
Tdisp = Tdisp(:, [origVars, extraVars]);
end

function y = toDbSafe(x)
y = nan(size(x));
mask = isfinite(x) & (x > 0);
y(mask) = 10*log10(x(mask));
end

function names = annotateScaledHeaders(names, scaleLabel)
for i = 1:numel(names)
    if endsWith(names{i}, '_scaled')
        names{i} = [names{i} ' ' scaleLabel];
    elseif endsWith(names{i}, '_dB')
        names{i} = [names{i} ' (dB)'];
    end
end
end

function c = sanitizeForUITable(c)
for i = 1:numel(c)
    v = c{i};

    if isa(v,'string')
        if isscalar(v)
            c{i} = char(v);
        else
            c{i} = char(strjoin(v, ","));
        end

    elseif isa(v,'categorical')
        c{i} = char(string(v));

    elseif isa(v,'datetime') || isa(v,'duration')
        c{i} = char(string(v));

    elseif iscell(v)
        try
            c{i} = char(string(v));
        catch
            c{i} = char(class(v));
        end
    end
end
end