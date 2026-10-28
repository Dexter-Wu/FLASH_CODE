function FLIM_ShowPhasesImage(Image_Saturation, Image_Decay, Image_Baseline, ...
                              k1, k2, k3, num_show, num_cycle, cycle_length)
% FLIM_ShowPhasesImage - Display saturation/decay/baseline frames and map
%                        concatenated frames back to Database_all global indices.
%
% Usage:
%   FLIM_ShowPhasesImage(Image_Saturation, Image_Decay, Image_Baseline, ...
%                        k1, k2, k3, num_show, num_cycle, cycle_length)
%
% Inputs:
%   Image_Saturation  - 3D array (h x w x N_total) with saturation frames concatenated by cycle
%   Image_Decay       - 3D array (h x w x N_total) with decay frames concatenated by cycle
%   Image_Baseline    - 3D array (h x w x N_total) with baseline frames concatenated by cycle
%   k1, k2, k3        - starting frame indices (in Database_all) of each segment in the first cycle
%   num_show          - maximum number of frames to display from each segment (per row)
%   num_cycle         - number of cycles present in the data
%   cycle_length      - total number of frames per cycle in Database_all (e.g. 10)
%
% Notes:
%   - Each segment's 3rd dimension is assumed to be concatenated in cycle order:
%       [cycle1_frames, cycle2_frames, ...].
%   - This function computes per-cycle counts automatically from the concatenated
%     matrix sizes and num_cycle. Uneven last cycle lengths are supported.
%   - Titles show the true global frame index in Database_all: "Segment - Frame <idx>".
%   - All subplots share a single colorbar on the right aligned with the 3 rows.

    narginchk(9,9); % require exactly 9 inputs

    % Validate numeric integer-like inputs
    if ~isscalar(num_cycle) || num_cycle < 1 || floor(num_cycle) ~= num_cycle
        error('num_cycle must be a positive integer.');
    end
    if ~isscalar(cycle_length) || cycle_length < 1 || floor(cycle_length) ~= cycle_length
        error('cycle_length must be a positive integer.');
    end

    % Ensure inputs are 3D arrays
    if ndims(Image_Saturation) < 3 || ndims(Image_Decay) < 3 || ndims(Image_Baseline) < 3
        error('Image_* inputs must be 3D arrays (h x w x N_total).');
    end

    % Total available frames per segment (concatenated across cycles)
    nSatAll   = size(Image_Saturation, 3);
    nDecayAll = size(Image_Decay, 3);
    nBaseAll  = size(Image_Baseline, 3);

    % Compute per-cycle distribution (handles uneven division)
    sat_base = floor(nSatAll / num_cycle);
    sat_rem  = mod(nSatAll, num_cycle);
    sat_per_cycle = repmat(sat_base, 1, num_cycle);
    if sat_rem > 0
        sat_per_cycle(1:sat_rem) = sat_per_cycle(1:sat_rem) + 1;
    end

    decay_base = floor(nDecayAll / num_cycle);
    decay_rem  = mod(nDecayAll, num_cycle);
    decay_per_cycle = repmat(decay_base, 1, num_cycle);
    if decay_rem > 0
        decay_per_cycle(1:decay_rem) = decay_per_cycle(1:decay_rem) + 1;
    end

    base_base = floor(nBaseAll / num_cycle);
    base_rem  = mod(nBaseAll, num_cycle);
    base_per_cycle = repmat(base_base, 1, num_cycle);
    if base_rem > 0
        base_per_cycle(1:base_rem) = base_per_cycle(1:base_rem) + 1;
    end

    % How many frames to actually show (do not exceed available frames)
    nSat   = min(num_show, nSatAll);
    nDecay = min(num_show, nDecayAll);
    nBase  = min(num_show, nBaseAll);

    % Number of columns to layout (max of three rows)
    nCols = max([nSat, nDecay, nBase]);

    % Prepare figure and colormap (preserve original grayscale)
    figure('Name','FLIM Raw Data Overview','NumberTitle','off','Color','w','Position',[50 50 900 500]);
    colormap(gray);
    global_max = max([max(Image_Saturation(:)), max(Image_Decay(:)), max(Image_Baseline(:))]);

    % Preallocate handles
    axesHandles = gobjects(3 * nCols, 1);

    % Internal mapping: concatenated index p -> global Database_all index
    function [gidx, cyc, within] = map_global_index(p, k_start, per_cycle_vec)
        % per_cycle_vec is a 1 x num_cycle vector containing frames per cycle for that segment
        cumv = cumsum(per_cycle_vec);
        cyc = find(cumv >= p, 1, 'first');
        if isempty(cyc)
            % p beyond available concatenated frames (shouldn't happen due to n* caps)
            cyc = numel(per_cycle_vec);
        end
        prev_sum = cumv(cyc) - per_cycle_vec(cyc);
        within = p - prev_sum; % 1-based index within that cycle for this segment
        % Map to global Database_all index:
        % first-cycle start = k_start
        % offset = (cyc-1)*cycle_length + (within-1)
        gidx = k_start + (cyc - 1) * cycle_length + (within - 1);
    end

    % --- Plot Saturation row ---
    for p = 1:nSat
        [global_idx, ~, ~] = map_global_index(p, k1, sat_per_cycle);
        ax = subplot(3, nCols, p);
        imagesc(Image_Saturation(:,:,p));
        clim([0 global_max]);
        axis image off;
        t = title(sprintf('Saturation - Frame %d', int32(global_idx)));
        t.FontSize = 10; 
        axesHandles(p) = ax;
    end

    % --- Plot Decay row ---
    for p = 1:nDecay
        [global_idx, ~, ~] = map_global_index(p, k2, decay_per_cycle);
        ix = nCols + p;
        ax = subplot(3, nCols, ix);
        imagesc(Image_Decay(:,:,p));
        clim([0 global_max]);
        axis image off;
        t = title(sprintf('Decay - Frame %d', int32(global_idx)));
        t.FontSize = 10;
        axesHandles(ix) = ax;
    end

    % --- Plot Baseline row ---
    for p = 1:nBase
        [global_idx, ~, ~] = map_global_index(p, k3, base_per_cycle);
        ix = 2 * nCols + p;
        ax = subplot(3, nCols, ix);
        imagesc(Image_Baseline(:,:,p));
        clim([0 global_max]);
        axis image off;
        t = title(sprintf('Baseline - Frame %d', int32(global_idx)));
        t.FontSize = 10; 
        axesHandles(ix) = ax;
    end

    % --- Shared colorbar on the right (attach to the last valid axes) ---
    validIdx = find(arrayfun(@(h) isgraphics(h), axesHandles));
    if ~isempty(validIdx)
        lastAx = axesHandles(validIdx(end));
        cb = colorbar(lastAx, 'eastoutside');
        % Try to set a position that visually aligns with three rows (may be ignored on some versions)
        try
            cb.Position = [0.92 0.10 0.02 0.80];
        catch
            % ignore if not supported
        end
        cb.Ticks = linspace(0, global_max, 3);
        cb.Label.String = 'Intensity';
        cb.Label.FontSize = 12;
    end

    % Title for the figure
    try
        t = sgtitle(sprintf('FLIM Raw Data by Time Segment (cycles=%d, cycleLen=%d)', num_cycle, cycle_length));
        t.FontSize = 12;
    catch
        % sgtitle may not exist in very old MATLAB releases; ignore if unavailable
    end

end
