function roi = clearROIs(roi)
%CLEARROIS Delete existing ROI objects/listeners (if any) and return a clean struct.

if nargin == 0 || isempty(roi)
    roi = struct( ...
        'on',[],'off',[],'lisOn',[],'lisOff',[], ...
        'startFreqPt',[],'endFreqPt',[], ...
        'lisStartFreq',[],'lisEndFreq',[], ...
        'startFreqTxt',[],'endFreqTxt',[]);
    return;
end

% delete listeners
try
    if isfield(roi,'lisOn') && ~isempty(roi.lisOn), delete(roi.lisOn); end
    if isfield(roi,'lisOff') && ~isempty(roi.lisOff), delete(roi.lisOff); end
    if isfield(roi,'lisStartFreq') && ~isempty(roi.lisStartFreq), delete(roi.lisStartFreq); end
    if isfield(roi,'lisEndFreq') && ~isempty(roi.lisEndFreq), delete(roi.lisEndFreq); end
catch
end

% delete ROI graphics
try
    if isfield(roi,'on') && ~isempty(roi.on) && isvalid(roi.on), delete(roi.on); end
    if isfield(roi,'off') && ~isempty(roi.off) && isvalid(roi.off), delete(roi.off); end
    if isfield(roi,'startFreqPt') && ~isempty(roi.startFreqPt) && isvalid(roi.startFreqPt), delete(roi.startFreqPt); end
    if isfield(roi,'endFreqPt') && ~isempty(roi.endFreqPt) && isvalid(roi.endFreqPt), delete(roi.endFreqPt); end
    if isfield(roi,'startFreqTxt') && ~isempty(roi.startFreqTxt) && isgraphics(roi.startFreqTxt), delete(roi.startFreqTxt); end
    if isfield(roi,'endFreqTxt') && ~isempty(roi.endFreqTxt) && isgraphics(roi.endFreqTxt), delete(roi.endFreqTxt); end
catch
end

roi = struct( ...
    'on',[],'off',[],'lisOn',[],'lisOff',[], ...
    'startFreqPt',[],'endFreqPt',[], ...
    'lisStartFreq',[],'lisEndFreq',[], ...
    'startFreqTxt',[],'endFreqTxt',[]);
end