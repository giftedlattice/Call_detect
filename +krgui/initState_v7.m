function app = initState_v7(sig, fs, opts, meta)
%INITSTATE_V7 Initialize analysis + detection + candidate pool. No UI here.
% Auto-start threshold: baseline initThrAboveNoise_dB + optional bump to satisfy constraints.
%
% IMPORTANT UPDATE:
%   We compute a bandwidth validity mask (bwOk_fixed) for each candidate ONCE.
%   This mask is always applied when building the working list, so bandwidth==0 calls vanish
%   from GUI + export (unless user forces keep via manualKeep).
%
% MANUAL FREQUENCY UPDATE:
%   We now keep per-candidate manual start/end frequency overrides:
%       state.startFreq_manual_fixed_kHz
%       state.endFreq_manual_fixed_kHz
%   These are NaN until user drags a spectrogram point.

rear  = sig(:,1);
Nsamp = size(sig,1);

% Rear-only bandpass for detection envelope
xBP = kr.bandpass3(rear, fs, opts.bpHz);

% Envelope in amplitude (Hilbert) + smoothing
env = abs(hilbert(xBP));
env = movmean(env, max(1, round((opts.envSmooth_ms/1000)*fs)));
env_dB = 20*log10(env + eps);

% Robust noise floor in dB
noiseFloor_dB = median(env_dB);

% -------------------------------------------------------
% Initial detection ONCE (candidate bounds)
% -------------------------------------------------------
thrDetect = opts.initThrAboveNoise_dB;
[cOn, cOff] = kr.detectCalls_dB(env_dB, fs, noiseFloor_dB, thrDetect, opts);
[cOn, cOff] = krgui.scrubBounds_v7(cOn, cOff, Nsamp);

% Optional: refine bounds to main burst to trim echoes
if isfield(opts,'boundRefine_enable') && opts.boundRefine_enable && ~isempty(cOn)
    for k = 1:numel(cOn)
        [cOn(k), cOff(k)] = krgui.refineBoundsMainBurst_v7(env_dB, fs, cOn(k), cOff(k), opts);
    end
    [cOn, cOff] = krgui.scrubBounds_v7(cOn, cOff, Nsamp);
end

% -------------------------------------------------------
% Precompute bandwidth validity mask for each candidate
% -------------------------------------------------------
minBW = 0.0;
if isfield(opts,'autoThr_minBandwidth_kHz')
    minBW = opts.autoThr_minBandwidth_kHz;
end
bwOk_fixed = computeBandwidthOkMask(rear, fs, cOn, cOff, opts, minBW);

% -------------------------------------------------------
% Auto-start threshold (ADDITIVE constraints)
% -------------------------------------------------------
thrStart = opts.initThrAboveNoise_dB;

if isfield(opts,'autoThr_enable') && opts.autoThr_enable && numel(cOn) >= 1
    thrStart = bumpThresholdToSatisfyConstraints(env_dB, noiseFloor_dB, fs, cOn, cOff, bwOk_fixed, opts, thrStart);
end

% -------------------------------------------------------
% State
% -------------------------------------------------------
state = struct();
state.thrAboveNoise_dB = thrStart;

state.calls_on_fixed  = cOn;
state.calls_off_fixed = cOff;

% Manual override per candidate (Toggle forces keep)
state.manualKeep_fixed = false(numel(cOn),1);

% Store bandwidth mask (always applied)
state.bwOk_fixed = bwOk_fixed;

% NEW: manual frequency override arrays per fixed candidate
state.startFreq_manual_fixed_kHz = nan(numel(cOn),1);
state.endFreq_manual_fixed_kHz   = nan(numel(cOn),1);

% Auto keep mask at START threshold (threshold-only; bw mask applied later)
state.autoKeep_fixed = krgui.computeAutoKeepMask_v7(env_dB, noiseFloor_dB, thrStart, cOn, cOff);

% Working list (kept)
[state.calls_on, state.calls_off, state.dispToFixed] = krgui.applyFilter_v7(state);

% GUI interaction state
state.selectedIdx = min(1, max(1, numel(state.calls_on)));
state.mode = "none";
state.accepted = false;

% App container
app = struct();
app.sig = sig;
app.fs = fs;
app.opts = opts;
app.meta = meta;
app.rear = rear;
app.env_dB = env_dB;
app.noiseFloor_dB = noiseFloor_dB;
app.Nsamp = Nsamp;
app.state = state;
end

% =====================================================================
% Compute bandwidth OK mask once (candidate-level)
% =====================================================================
function bwOk = computeBandwidthOkMask(rear, fs, cOn, cOff, opts, minBW_kHz)
N = numel(rear);
bwOk = true(numel(cOn),1);

for i = 1:numel(cOn)
    a = max(1, min(N, cOn(i)));
    b = max(1, min(N, cOff(i)));
    if b <= a
        bwOk(i) = false;
        continue;
    end

    segR = rear(a:b);
    r = kr.feature_ridgeFreqs_v7(segR, fs, opts);

    bw = r.max_kHz - r.min_kHz;  % ridge bandwidth across active bins
    bwOk(i) = isfinite(bw) && (bw > minBW_kHz);
end
end

% =====================================================================
% Bump threshold upward until constraints satisfied
% =====================================================================
function thrOut = bumpThresholdToSatisfyConstraints(env_dB, noiseFloor_dB, fs, cOn, cOff, bwOk_fixed, opts, thrBaseline)

thrMax = opts.autoThr_searchMax_dB;
step   = opts.autoThr_step_dB;

thrOut = thrBaseline;

if satisfiesConstraints(env_dB, noiseFloor_dB, fs, cOn, cOff, bwOk_fixed, thrOut, opts)
    return;
end

for thr = thrBaseline:step:thrMax
    if satisfiesConstraints(env_dB, noiseFloor_dB, fs, cOn, cOff, bwOk_fixed, thr, opts)
        thrOut = thr;
        return;
    end
end

thrOut = thrMax;
end

function ok = satisfiesConstraints(env_dB, noiseFloor_dB, fs, cOn, cOff, bwOk_fixed, thrAboveNoise_dB, opts)

autoKeep = krgui.computeAutoKeepMask_v7(env_dB, noiseFloor_dB, thrAboveNoise_dB, cOn, cOff);

% Apply bandwidth constraint as well for evaluating IPI
keepMask = autoKeep & bwOk_fixed;

onKept = cOn(keepMask);

% ---- Constraint #1: min IPI
okIPI = true;
if isfield(opts,'autoThr_minIPI_ms') && numel(onKept) >= 2
    ipi_ms = diff(onKept) / fs * 1000;
    okIPI = all(ipi_ms >= opts.autoThr_minIPI_ms);
end

% ---- Constraint #2: bandwidth already enforced by keepMask
okBW = true;
if isfield(opts,'autoThr_noZeroBW_enable') && opts.autoThr_noZeroBW_enable
    okBW = all(bwOk_fixed(keepMask));
end

ok = okIPI && okBW;
end