function [I_descattering, Scattering_mask] = FLIM_Intensity_Descattering(Intensity_Map, window_radius, lambda, gamma, ImgPath)
% FLIM_dehaze_gray_guided - Gray-guided de-scattering for FLIM intensity images
%
% Syntax:
%   [I_descattering, Scattering_mask] = FLIM_Descattering(Intensity_Map, window_radius, lambda, gamma, ImgPath)
%
% Inputs:
%   Intensity_Map   - 2D or 3D FLIM intensity image (double, single, or uint16)
%   window_radius   - Window radius for local dark channel estimation
%   lambda          - Regularization parameter for guided estimation
%   gamma           - Standard deviation for Gaussian smoothing
%   ImgPath          - Path to save processed results
%
% Outputs:
%   I_descattering  - De-scattered FLIM intensity image (normalized to [0,1])
%   Scattering_mask - Estimated scattering contribution map
%
% Description:
%   This function performs gray-guided de-scattering on a FLIM intensity image.
%   Steps:
%       1. Gaussian smoothing and normalization;
%       2. Local dark channel estimation using a square window of size 2*window_radius-1;
%       3. Scattering contribution estimation using local statistics;
%       4. Recover de-scattered intensity image based on estimated scattering.

    % Step 1: Preprocessing (Gaussian smoothing + normalization)
    I = im2single(imgaussfilt(Intensity_Map, gamma));
    scale = max(I(:)) - min(I(:)) + eps;
    I = (I - min(I(:))) / scale;

    % Step 2: Local dark channel prior
    se = strel('square', 2*window_radius-1);
    if ndims(I) == 3
        d = min(cat(3, ...
            imerode(I(:,:,1), se), ...
            imerode(I(:,:,2), se), ...
            imerode(I(:,:,3), se)), [], 3);
    else
        d = imerode(I, se);
    end

    % Step 3: Scattering estimation
    f_mean  = imboxfilt(d, 2*window_radius+1);
    g_mean  = imboxfilt(I, 2*window_radius+1);
    g2_mean = imboxfilt(I.^2, 2*window_radius+1);
    fg_mean = imboxfilt(d.*I, 2*window_radius+1);

    covar = fg_mean - g_mean.*f_mean;
    var_g = g2_mean - g_mean.^2;
    a = covar ./ (var_g + lambda + eps);
    b = f_mean - a.*g_mean;
    Scattering_mask = a.*I + b;

    % Step 4: Recover de-scattered intensity
    theta = (I - Scattering_mask) ./ (1 - Scattering_mask + eps);
    theta = 1 / max(theta(:));
    I_descattering = theta * scale * (I - Scattering_mask) ./ (1 - Scattering_mask + eps);
    disp('FLIM descaterring finished.');

    %% save
    save(fullfile(ImgPath, 'I_descattering.mat'), 'I_descattering');
    save(fullfile(ImgPath, 'Scattering_mask.mat'), 'Scattering_mask');
    I_descattering = uint16(I_descattering.*60000);
    imwrite(I_descattering, fullfile(ImgPath, 'I_descattering.tif'));
end
