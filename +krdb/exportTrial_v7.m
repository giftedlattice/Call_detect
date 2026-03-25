function exportTrial_v7(dbPath, meta, fs, fullMat, calls, T)
%EXPORTTRIAL_V7 Write one trial (and its calls) to SQLite in a tidy schema.
% FIX: properly distinguishes trials/bats using quoted identifiers and strict fetch checks.

dbPath = char(string(dbPath));
krdb.initDb_v7(dbPath);

conn = sqlite(dbPath, 'connect');
exec(conn, 'PRAGMA foreign_keys = ON;');

% -------------------------
% 1) UPSERT bat
% -------------------------
bat_code = char(string(meta.bat));
exec(conn, ['INSERT OR IGNORE INTO bats(bat_code) VALUES(''' escapeSql(bat_code) ''');']);

batRows = fetch(conn, ['SELECT bat_id, bat_code FROM bats WHERE bat_code=''' escapeSql(bat_code) ''';']);
bat_id = fetchSingleInt(batRows, 1, 'bat_id lookup');
fprintf('[DB] bat_id=%d (bat=%s)\n', bat_id, bat_code);

% -------------------------
% 2) UPSERT trial
% -------------------------
dateStr  = char(safeStr(meta,'date',""));
trialStr = char(safeStr(meta,'trial',""));
condStr  = char(safeStr(meta,'condition',""));
catchTrial = safeBool(meta,'catchTrial',false);
tempC = safeNum(meta,'temperature_C',NaN);
humP  = safeNum(meta,'humidity_pct',NaN);
source_mat = char(string(fullMat));

% Insert if missing (NOTE: quote "date" and "trial")
sqlInsertTrial = [ ...
    'INSERT OR IGNORE INTO trials(bat_id,"date","trial",condition,catch_trial,temperature_C,humidity_pct,fs_hz,source_mat) VALUES(' ...
    num2str(bat_id) ',' ...
    '''' escapeSql(dateStr) ''',' ...
    '''' escapeSql(trialStr) ''',' ...
    '''' escapeSql(condStr) ''',' ...
    num2str(double(catchTrial)) ',' ...
    numOrNull(tempC) ',' ...
    numOrNull(humP) ',' ...
    num2str(fs) ',' ...
    '''' escapeSql(source_mat) '''' ...
    ');' ];
exec(conn, sqlInsertTrial);

% Update mutable fields
sqlUpdateTrial = [ ...
    'UPDATE trials SET ' ...
    'condition=''' escapeSql(condStr) ''',' ...
    'catch_trial=' num2str(double(catchTrial)) ',' ...
    'temperature_C=' numOrNull(tempC) ',' ...
    'humidity_pct=' numOrNull(humP) ',' ...
    'fs_hz=' num2str(fs) ' ' ...
    'WHERE bat_id=' num2str(bat_id) ' AND ' ...
    '"date"=''' escapeSql(dateStr) ''' AND ' ...
    '"trial"=''' escapeSql(trialStr) ''' AND ' ...
    'source_mat=''' escapeSql(source_mat) ''';' ];
exec(conn, sqlUpdateTrial);

% Fetch trial_id STRICTLY for this exact trial identity
trialRows = fetch(conn, [ ...
    'SELECT trial_id, bat_id, "date", "trial", source_mat FROM trials WHERE bat_id=' num2str(bat_id) ...
    ' AND "date"=''' escapeSql(dateStr) '''' ...
    ' AND "trial"=''' escapeSql(trialStr) '''' ...
    ' AND source_mat=''' escapeSql(source_mat) ''';' ]);

trial_id = fetchSingleInt(trialRows, 1, 'trial_id lookup');
fprintf('[DB] trial_id=%d (date=%s trial=%s)\n', trial_id, dateStr, trialStr);

% Debug: show most recent trials so you can confirm new rows exist
dbg = fetch(conn, 'SELECT trial_id, bat_id, "date", "trial" FROM trials ORDER BY trial_id DESC LIMIT 5;');
disp('[DB] latest trials:');
disp(dbg);

% -------------------------
% 3) Replace calls for this trial_id
% -------------------------
exec(conn, ['DELETE FROM calls WHERE trial_id=' num2str(trial_id) ';']);

n = min(numel(calls), height(T));
fprintf('[DB] inserting %d calls\n', n);

colnames = { ...
    'trial_id','call_number','on_samp','off_samp', ...
    'timestamp_s','duration_ms','ipi_ms', ...
    'peakFreq_kHz','startFreq_kHz','endFreq_kHz', ...
    'startFreq_low_kHz','startFreq_high_kHz', ...
    'endFreq_ridge_kHz','endFreq_low_kHz', ...
    'bandwidth_kHz','slope_kHz_per_ms', ...
    'peakAmp_rear','peakAmp_left','peakAmp_right'};

data = cell(n, numel(colnames));
for k = 1:n
    data{k,1} = trial_id;
    data{k,2} = k;
    data{k,3} = calls(k).on_samp;
    data{k,4} = calls(k).off_samp;

    data{k,5} = T.timestamp_s(k);
    data{k,6} = T.duration_ms(k);
    data{k,7} = T.ipi_ms(k);

    data{k,8}  = T.peakFreq_kHz(k);
    data{k,9}  = T.startFreq_kHz(k);
    data{k,10} = T.endFreq_kHz(k);

    data{k,11} = getTableOrNaN(T,'startFreq_low_kHz',k);
    data{k,12} = getTableOrNaN(T,'startFreq_high_kHz',k);
    data{k,13} = getTableOrNaN(T,'endFreq_ridge_kHz',k);
    data{k,14} = getTableOrNaN(T,'endFreq_low_kHz',k);

    data{k,15} = T.bandwidth_kHz(k);
    data{k,16} = T.slope_kHz_per_ms(k);

    data{k,17} = T.peakAmp_rear(k);
    data{k,18} = T.peakAmp_left(k);
    data{k,19} = T.peakAmp_right(k);
end

insert(conn, 'calls', colnames, data);

nTrials = fetchScalar(conn, 'SELECT COUNT(*) FROM trials;');
nCalls  = fetchScalar(conn, 'SELECT COUNT(*) FROM calls;');
fprintf('[DB] DONE. trials=%d calls=%d\n', nTrials, nCalls);

close(conn);
end

% -------------------------
% Helpers
% -------------------------
function s = escapeSql(x)
s = char(x);
s = strrep(s, '''', '''''');
end

function v = fetchScalar(conn, sql)
res = fetch(conn, sql);
if istable(res)
    v = res{1,1};
else
    v = res{1};
end
if ischar(v) || isstring(v)
    vn = str2double(string(v));
    if isfinite(vn), v = vn; end
end
end

function out = safeStr(meta, field, fallback)
out = string(fallback);
if isstruct(meta) && isfield(meta, field)
    out = string(meta.(field));
end
end

function out = safeBool(meta, field, fallback)
out = logical(fallback);
if isstruct(meta) && isfield(meta, field)
    out = logical(meta.(field));
end
end

function out = safeNum(meta, field, fallback)
out = fallback;
if isstruct(meta) && isfield(meta, field)
    out = double(meta.(field));
end
end

function s = numOrNull(x)
if ~isfinite(x), s = 'NULL'; else, s = num2str(x); end
end

function v = getTableOrNaN(T, varName, k)
if ismember(varName, T.Properties.VariableNames)
    v = T.(varName)(k);
else
    v = NaN;
end
end

function val = fetchSingleInt(rows, colIdx, ctx)
% Ensures exactly one-row result, otherwise throws.
if istable(rows)
    n = height(rows);
    if n ~= 1
        error('DB %s expected 1 row, got %d', ctx, n);
    end
    val = rows{1,colIdx};
else
    % cell array
    if size(rows,1) ~= 1
        error('DB %s expected 1 row, got %d', ctx, size(rows,1));
    end
    val = rows{1,colIdx};
end
val = double(val);
end
