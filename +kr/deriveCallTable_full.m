function T = deriveCallTable_full(sig, fs, calls, meta, opts)
%DERIVECALLTABLE_FULL Export table for detected calls (modular version).
%
% Metadata columns:
%   bat, date, trial, condition, catchTrial, temperature_C, humidity_pct
%
% Frequency conventions:
%   startFreq_kHz  = final start frequency for the call
%   endFreq_kHz    = final end frequency for the call
%
% Final frequency logic:
%   If calls(k).startFreq_manual_kHz exists and is finite, use it.
%   Otherwise use the automatic ridge start frequency.
%
%   If calls(k).endFreq_manual_kHz exists and is finite, use it.
%   Otherwise use the automatic ridge end frequency.
%
% Bandwidth and slope:
%   bandwidth_kHz      = max(ridge)-min(ridge) across active time bins
%   slope_kHz_per_ms   = (endFreq_kHz - startFreq_kHz) / duration_ms  (signed)

n = numel(calls);

% -------------------------
% Safe metadata extraction
% -------------------------
batVal = "";
if isstruct(meta) && isfield(meta,'bat')
    batVal = string(meta.bat);
end

dateVal = "";
if isstruct(meta) && isfield(meta,'date')
    dateVal = string(meta.date);
end

trialVal = "";
if isstruct(meta) && isfield(meta,'trial')
    trialVal = string(meta.trial);
end

condVal = "";
if isstruct(meta) && isfield(meta,'condition')
    condVal = string(meta.condition);
end

catchVal = false;
if isstruct(meta) && isfield(meta,'catchTrial')
    catchVal = logical(meta.catchTrial);
end

tempVal = NaN;
if isstruct(meta) && isfield(meta,'temperature_C')
    tempVal = double(meta.temperature_C);
end

humVal = NaN;
if isstruct(meta) && isfield(meta,'humidity_pct')
    humVal = double(meta.humidity_pct);
end

bat   = repmat(batVal,   n, 1);
date  = repmat(dateVal,  n, 1);
trial = repmat(trialVal, n, 1);

condition     = repmat(condVal,  n, 1);
catchTrial    = repmat(catchVal, n, 1);
temperature_C = repmat(tempVal,  n, 1);
humidity_pct  = repmat(humVal,   n, 1);

call_number = (1:n)';

% -------------------------
% Output variables
% -------------------------
timestamp_s = nan(n,1);
timestamp_left_s  = nan(n,1);
timestamp_right_s = nan(n,1);
duration_ms = nan(n,1);
ipi_ms      = nan(n,1);

peakFreq_kHz = nan(n,1);

startFreq_kHz = nan(n,1);
endFreq_kHz   = nan(n,1);

bandwidth_kHz = nan(n,1);
slope_kHz_per_ms = nan(n,1);

peakAmp_rear  = nan(n,1);
peakAmp_left  = nan(n,1);
peakAmp_right = nan(n,1);

Nsamp = size(sig,1);

for k = 1:n
    on  = max(1, min(Nsamp, calls(k).on_samp));
    off = max(1, min(Nsamp, calls(k).off_samp));
    if off <= on
        continue;
    end

    % Timing (rear)
    timestamp_s(k) = (on-1)/fs;
    duration_ms(k) = ((off-on)+1)/fs*1000; % inclusive

    if k < n
        ipi_ms(k) = ((calls(k+1).on_samp-1) - (on-1))/fs*1000;
    end

    segR  = sig(on:off,1);
    segL  = sig(on:off,2);
    segRR = sig(on:off,3);

    % Left/right timing only if finite samples exist
    if any(isfinite(segL))
        [~, iPkL] = max(abs(segL), [], 'omitnan');
        timestamp_left_s(k) = (on + iPkL - 2)/fs;
    end
    if any(isfinite(segRR))
        [~, iPkR] = max(abs(segRR), [], 'omitnan');
        timestamp_right_s(k) = (on + iPkR - 2)/fs;
    end

    % Peak frequency from Welch (rear)
    fPeak = kr.feature_peakFreqWelch_v7(segR, fs, opts);
    peakFreq_kHz(k) = fPeak;

    % Automatic ridge features
    r = kr.feature_ridgeFreqs_v7(segR, fs, opts);

    startFreq_auto = r.start_kHz;
    endFreq_auto   = r.end_kHz;

    % Manual overrides if present
    startFreq_manual = NaN;
    endFreq_manual   = NaN;

    if isfield(calls(k), 'startFreq_manual_kHz') && isfinite(calls(k).startFreq_manual_kHz)
        startFreq_manual = calls(k).startFreq_manual_kHz;
    end

    if isfield(calls(k), 'endFreq_manual_kHz') && isfinite(calls(k).endFreq_manual_kHz)
        endFreq_manual = calls(k).endFreq_manual_kHz;
    end

    % Final exported values
    if isfinite(startFreq_manual)
        startFreq_kHz(k) = startFreq_manual;
    else
        startFreq_kHz(k) = startFreq_auto;
    end

    if isfinite(endFreq_manual)
        endFreq_kHz(k) = endFreq_manual;
    else
        endFreq_kHz(k) = endFreq_auto;
    end

    % Bandwidth from ridge min/max across active bins
    if isfinite(r.min_kHz) && isfinite(r.max_kHz)
        bandwidth_kHz(k) = r.max_kHz - r.min_kHz;
    end

    % Slope uses final exported start/end
    if isfinite(startFreq_kHz(k)) && isfinite(endFreq_kHz(k)) && duration_ms(k) > 0
        slope_kHz_per_ms(k) = (endFreq_kHz(k) - startFreq_kHz(k)) / duration_ms(k);
    end

    % Amplitudes at rear peak frequency
    if isfinite(fPeak)
        amps = kr.feature_peakAmpsAtPeakFreq_v7(segR, segL, segRR, fs, opts, fPeak);
        peakAmp_rear(k)  = amps.rear;
        peakAmp_left(k)  = amps.left;
        peakAmp_right(k) = amps.right;
    end
end

% -------------------------
% Final table
% -------------------------
T = table( ...
    bat, date, trial, condition, catchTrial, temperature_C, humidity_pct, call_number, ...
    timestamp_s, timestamp_left_s, timestamp_right_s, ...
    duration_ms, ipi_ms, ...
    peakFreq_kHz, ...
    startFreq_kHz, endFreq_kHz, ...
    bandwidth_kHz, slope_kHz_per_ms, ...
    peakAmp_rear, peakAmp_left, peakAmp_right);

end