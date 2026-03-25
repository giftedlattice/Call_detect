function deleteBatDateTrialSet()
%DELETEBATDATETRIALSET Delete one trial set from the KR bat SQLite database.
%
% Works with the schema created by:
%   +krdb/initDb_v7.m
%   +krdb/exportTrial_v7.m
%
% Tables:
%   bats   (bat_id, bat_code)
%   trials (trial_id, bat_id, date, trial, source_mat, ...)
%   calls  (trial_id, ...)
%
% Behavior:
%   - Looks for Bats.sqlite in the same folder as this .m file
%   - If not found, lets the user choose a .sqlite file
%   - Lists trial entries by joining bats + trials
%   - Deletes the selected trial row
%   - Calls delete automatically via ON DELETE CASCADE
%   - Optionally removes orphan bats with no remaining trials

    thisFolder = fileparts(mfilename('fullpath'));
    dbPath = fullfile(thisFolder, 'Bats.sqlite');

    if ~isfile(dbPath)
        [f,p] = uigetfile({'*.sqlite;*.db;*.sqlite3','SQLite DB (*.sqlite, *.db, *.sqlite3)'}, ...
                          'Select Bats.sqlite', thisFolder);
        if isequal(f,0)
            fprintf('Delete canceled: no database selected.\n');
            return;
        end
        dbPath = fullfile(p,f);
    end

    fprintf('Using database: %s\n', dbPath);

    conn = sqlite(dbPath, 'connect');
    cleanupObj = onCleanup(@() close(conn)); %#ok<NASGU>

    exec(conn, 'PRAGMA foreign_keys = ON;');

    % Confirm required tables exist
    tbls = fetch(conn, 'SELECT name FROM sqlite_master WHERE type="table";');
    tblNames = normalizeFetchToStrings(tbls);

    need = ["bats","trials","calls"];
    missing = need(~ismember(need, tblNames));
    if ~isempty(missing)
        error('DB missing required tables: %s', strjoin(cellstr(missing), ', '));
    end

    % Pull all trial identities using the real schema
    sql = [ ...
        'SELECT ' ...
        't.trial_id, ' ...
        'b.bat_code, ' ...
        't."date", ' ...
        't."trial", ' ...
        't.source_mat, ' ...
        '(SELECT COUNT(*) FROM calls c WHERE c.trial_id = t.trial_id) AS nCalls ' ...
        'FROM trials t ' ...
        'JOIN bats b ON t.bat_id = b.bat_id ' ...
        'ORDER BY b.bat_code, t."date", t."trial", t.trial_id;' ];

    rows = fetch(conn, sql);

    if isempty(rows)
        fprintf('No trials found in the database.\n');
        return;
    end

    if istable(rows)
        rowsCell = table2cell(rows);
    else
        rowsCell = rows;
    end

    nRows = size(rowsCell, 1);
    labels = strings(nRows, 1);

    for i = 1:nRows
        trial_id   = doubleValue(rowsCell{i,1});
        bat_code   = stringifyValue(rowsCell{i,2});
        dateVal    = stringifyValue(rowsCell{i,3});
        trialVal   = stringifyValue(rowsCell{i,4});
        sourceMat  = stringifyValue(rowsCell{i,5});
        nCalls     = doubleValue(rowsCell{i,6});

        [~, srcName, srcExt] = fileparts(sourceMat);
        srcShort = [srcName srcExt];
        if strlength(string(srcShort)) == 0
            srcShort = "<none>";
        end

        labels(i) = sprintf(['trial_id=%d | Bat=%s | Date=%s | Trial=%s | ' ...
                             'Calls=%d | Source=%s'], ...
                             trial_id, bat_code, dateVal, trialVal, nCalls, srcShort);
    end

    [idx, tf] = listdlg( ...
        'PromptString', 'Select one Bat / Date / Trial set to delete:', ...
        'SelectionMode', 'single', ...
        'ListString', cellstr(labels), ...
        'ListSize', [900 420]);

    if ~tf || isempty(idx)
        fprintf('Delete canceled by user.\n');
        return;
    end

    trial_id  = doubleValue(rowsCell{idx,1});
    bat_code  = stringifyValue(rowsCell{idx,2});
    dateVal   = stringifyValue(rowsCell{idx,3});
    trialVal  = stringifyValue(rowsCell{idx,4});
    sourceMat = stringifyValue(rowsCell{idx,5});
    nCalls    = doubleValue(rowsCell{idx,6});

    msg = sprintf([ ...
        'Delete this trial set?\n\n' ...
        'trial_id: %d\n' ...
        'Bat: %s\n' ...
        'Date: %s\n' ...
        'Trial: %s\n' ...
        'Source: %s\n' ...
        'Associated calls: %d\n\n' ...
        'This will delete the trial row, and all calls linked to it.\n' ...
        'This cannot be undone.' ], ...
        trial_id, bat_code, dateVal, trialVal, sourceMat, nCalls);

    choice = questdlg(msg, 'Confirm Delete', 'Delete', 'Cancel', 'Cancel');
    if ~strcmp(choice, 'Delete')
        fprintf('Delete canceled by user.\n');
        return;
    end

    % Delete the selected trial.
    % Calls should be deleted automatically via ON DELETE CASCADE.
    exec(conn, sprintf('DELETE FROM trials WHERE trial_id=%d;', trial_id));

    fprintf('Deleted trial_id=%d for Bat=%s, Date=%s, Trial=%s\n', ...
        trial_id, bat_code, dateVal, trialVal);

    % Optional cleanup: remove orphan bats with no remaining trials
    orphanSQL = [ ...
        'DELETE FROM bats ' ...
        'WHERE bat_id NOT IN (SELECT DISTINCT bat_id FROM trials);' ];
    exec(conn, orphanSQL);

    % Report remaining counts
    nTrials = fetchScalar(conn, 'SELECT COUNT(*) FROM trials;');
    nCalls  = fetchScalar(conn, 'SELECT COUNT(*) FROM calls;');
    nBats   = fetchScalar(conn, 'SELECT COUNT(*) FROM bats;');

    fprintf('Remaining in DB: bats=%d, trials=%d, calls=%d\n', nBats, nTrials, nCalls);

    % Optional:
    % exec(conn, 'VACUUM;');
end

% -------------------------------------------------------------------------
function names = normalizeFetchToStrings(x)
    if istable(x)
        x = table2cell(x);
    end

    if isempty(x)
        names = strings(0,1);
        return;
    end

    if iscell(x)
        names = strings(size(x,1),1);
        for i = 1:size(x,1)
            names(i) = string(x{i,1});
        end
    else
        names = string(x);
    end
end

function out = stringifyValue(v)
    if ismissingLike(v)
        out = "<missing>";
    elseif isstring(v)
        out = char(v);
    elseif ischar(v)
        out = v;
    elseif isnumeric(v)
        out = num2str(v);
    elseif isdatetime(v)
        out = char(string(v));
    else
        out = char(string(v));
    end
end

function tf = ismissingLike(v)
    tf = false;
    try
        tf = ismissing(v);
    catch
    end
    if isempty(v)
        tf = true;
    end
end

function v = doubleValue(x)
    if isnumeric(x)
        v = double(x);
    elseif isstring(x) || ischar(x)
        v = str2double(string(x));
    else
        v = double(x);
    end
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
        if isfinite(vn)
            v = vn;
        end
    end
end