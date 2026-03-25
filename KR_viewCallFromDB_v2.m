function KR_viewCallFromDB_v2()
%KR_viewCallFromDB_v2 Standalone DB viewer (WAVEFORM-first):
% 1) Pick bat/date/trial from DB
% 2) Pick a call (call_number) from that trial
% 3) Show REAR waveform around the call with on/off bounds (primary)
% 4) Also shows a small optional spectrogram figure (secondary; can be removed)
%
% Assumptions:
% - DB "KR_callDetectTool_v7.sqlite" lives in the same folder as this file (or you can browse)
% - trials.source_mat stored in DB points to a valid .mat on this machine (else you browse)
% - MAT contains variable "sig" (Nx1/Nx2/Nx3) and optional "fs"

clc;

% -----------------------------
% Locate DB
% -----------------------------
toolRoot = fileparts(mfilename('fullpath'));
defaultDb = fullfile(toolRoot, "Bats.sqlite");

if exist(defaultDb, 'file') ~= 2
    [f,p] = uigetfile('*.sqlite', 'Select Bats.sqlite');
    if isequal(f,0), return; end
    dbPath = fullfile(p,f);
else
    dbPath = defaultDb;
end

conn = sqlite(char(dbPath), 'connect');

% -----------------------------
% Pick a trial (bat/date/trial)
% -----------------------------
trialSQL = ['SELECT t.trial_id, b.bat_code, t."date", t."trial", t.condition, t.source_mat, t.fs_hz ' ...
            'FROM trials t JOIN bats b ON t.bat_id=b.bat_id ' ...
            'ORDER BY b.bat_code, t."date", t."trial", t.trial_id;'];
trials = fetch(conn, trialSQL);

if isempty(trials) || (istable(trials) && height(trials)==0)
    close(conn);
    errordlg('No trials found in DB.', 'Empty DB');
    return;
end

% Normalize to table for easier handling
if ~istable(trials)
    trials = cell2table(trials);
end

% Name columns if needed (sqlite fetch sometimes gives default Var1..)
if width(trials) < 7
    close(conn);
    errordlg('Unexpected trials query result shape.', 'DB Error');
    return;
end

% Best-effort label columns
trials.Properties.VariableNames(1:7) = {'trial_id','bat_code','date','trial','condition','source_mat','fs_hz'};

items = strings(height(trials),1);
for i = 1:height(trials)
    items(i) = sprintf('%s | %s | trial %s | cond=%s | id=%d', ...
        string(trials.bat_code(i)), string(trials.date(i)), string(trials.trial(i)), ...
        string(trials.condition(i)), double(trials.trial_id(i)));
end

[idxTrial, ok] = listdlg( ...
    'PromptString','Select a trial:', ...
    'SelectionMode','single', ...
    'ListString',cellstr(items), ...
    'ListSize',[700 400]);

if ~ok
    close(conn);
    return;
end

trial_id = double(trials.trial_id(idxTrial));
bat_code = string(trials.bat_code(idxTrial));
dateStr  = string(trials.date(idxTrial));
trialStr = string(trials.trial(idxTrial));
condStr  = string(trials.condition(idxTrial));
source_mat = string(trials.source_mat(idxTrial));
fs_db = double(trials.fs_hz(idxTrial));

% -----------------------------
% Pick a call within trial
% -----------------------------
callSQL = ['SELECT call_id, call_number, on_samp, off_samp, timestamp_s, duration_ms ' ...
           'FROM calls WHERE trial_id=' num2str(trial_id) ' ORDER BY call_number;'];
callsT = fetch(conn, callSQL);
close(conn);

if isempty(callsT) || (istable(callsT) && height(callsT)==0)
    errordlg(sprintf('No calls found for trial_id=%d.', trial_id), 'No calls');
    return;
end

if ~istable(callsT)
    callsT = cell2table(callsT);
end

% Label columns
callsT.Properties.VariableNames(1:min(width(callsT),6)) = {'call_id','call_number','on_samp','off_samp','timestamp_s','duration_ms'};

callItems = strings(height(callsT),1);
for i = 1:height(callsT)
    callItems(i) = sprintf('#%d | call_id=%d | t=%.4f s | dur=%.2f ms', ...
        double(callsT.call_number(i)), double(callsT.call_id(i)), ...
        double(callsT.timestamp_s(i)), double(callsT.duration_ms(i)));
end

[idxCall, ok] = listdlg( ...
    'PromptString',sprintf('Select a call (trial_id=%d):', trial_id), ...
    'SelectionMode','single', ...
    'ListString',cellstr(callItems), ...
    'ListSize',[650 420]);

if ~ok
    return;
end

call_id    = double(callsT.call_id(idxCall));
call_num   = double(callsT.call_number(idxCall));
on_samp    = double(callsT.on_samp(idxCall));
off_samp   = double(callsT.off_samp(idxCall));

% -----------------------------
% Load MAT (or prompt if missing)
% -----------------------------
if source_mat == "" || exist(source_mat, 'file') ~= 2
    [f,p] = uigetfile('*.mat', sprintf('MAT not found. Select source MAT for trial_id=%d', trial_id));
    if isequal(f,0), return; end
    source_mat = string(fullfile(p,f));
end

S = load(source_mat);

if ~isfield(S,'sig')
    errordlg('Selected MAT does not contain variable "sig".', 'Bad MAT file');
    return;
end

sig = normalizeSigTo3ch_local(S.sig);

fs = fs_db;
if isfield(S,'fs') && ~isempty(S.fs)
    fs = double(S.fs);
end
if ~isfinite(fs) || fs <= 0
    errordlg('Invalid fs in DB/MAT.', 'Bad sample rate');
    return;
end

Nsamp = size(sig,1);
on_samp  = max(1, min(Nsamp, round(on_samp)));
off_samp = max(1, min(Nsamp, round(off_samp)));
if off_samp < on_samp
    tmp = on_samp; on_samp = off_samp; off_samp = tmp;
end

rear = sig(:,1);

% -----------------------------
% Plot WAVEFORM around call (primary)
% -----------------------------
contextHalf_s = 0.25; % +/- 250 ms around call center (edit as desired)
center = round((on_samp + off_samp)/2);
ctxHalf = round(contextHalf_s * fs);
a = max(1, center - ctxHalf);
b = min(Nsamp, center + ctxHalf);

x = rear(a:b);
tt = (a:b)/fs;
t_on  = (on_samp-1)/fs;
t_off = (off_samp-1)/fs;

fig = figure('Color','w', ...
    'Name', sprintf('Waveform | bat=%s | %s trial=%s | call#%d | call_id=%d', ...
    bat_code, dateStr, trialStr, call_num, call_id));

ax = axes('Parent',fig);
plot(ax, tt, x, 'k'); hold(ax,'on');
xline(ax, t_on,  '--', 'LineWidth', 2);
xline(ax, t_off, '--', 'LineWidth', 2);
xlim(ax, [tt(1) tt(end)]);
xlabel(ax,'Time (s)');
ylabel(ax,'Amplitude');
title(ax, sprintf('REAR waveform | cond=%s | source=%s', condStr, source_mat), 'Interpreter','none');
hold(ax,'off');

% -----------------------------
% Optional: quick spectrogram (secondary)
% -----------------------------
doSpec = true; % set false if you never want spectrogram
if doSpec
    harmBand_kHz = [20 70];
    specWin  = 256;
    specOvl  = 192;
    specNfft = 512;

    fig2 = figure('Color','w', 'Name', sprintf('Spectrogram (optional) | call_id=%d', call_id));
    ax2 = axes('Parent',fig2);

    [Sx,F,Tt] = spectrogram(double(x), specWin, specOvl, specNfft, fs, 'yaxis');
    SdB = 20*log10(abs(Sx)+eps);
    FkHz = F/1000;

    imagesc(ax2, Tt + tt(1), FkHz, SdB);
    axis(ax2,'xy');
    ylim(ax2, harmBand_kHz);
    xlabel(ax2,'Time (s)');
    ylabel(ax2,'kHz');
    title(ax2, 'Spectrogram (rear)');

    v1 = prctile(SdB(:), 10);
    v2 = prctile(SdB(:), 99);
    if isfinite(v1) && isfinite(v2) && v2 > v1
        caxis(ax2, [v1 v2]);
    end

    hold(ax2,'on');
    xline(ax2, t_on,  '--', 'LineWidth', 2);
    xline(ax2, t_off, '--', 'LineWidth', 2);
    hold(ax2,'off');
end

end

% =========================
% Local helper: normalize sig to Nx3
% =========================
function sig3 = normalizeSigTo3ch_local(sigIn)
sigIn = double(sigIn);
if isvector(sigIn)
    sigIn = sigIn(:);
end
N = size(sigIn,1);
switch size(sigIn,2)
    case 1
        sig3 = [sigIn, nan(N,1), nan(N,1)];
    case 2
        sig3 = [sigIn(:,1), sigIn(:,2), nan(N,1)];
    case 3
        sig3 = sigIn;
    otherwise
        error('sig must be Nsamp x 1, 2, or 3.');
end
end
