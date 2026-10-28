function [Intensity_Map,Noise_Map] = FLIM_Intensity_Recon(Image_Saturation, Image_Baseline, alpha, ImgPath)
% FLIM_PreProcessing - Preprocess raw FLIM (Fluorescence Lifetime Imaging) data
%
% Syntax:
%   [Intensity_Map, Noise_Map] = FLIM_Intensity_Recon(Image_Saturation, Image_Baseline, alpha, ImgPath)
%
% Inputs:
%   Image_Saturation - 3D matrix (len x wid x N) of saturated images
%   Image_Baseline   - 3D matrix (len x wid x M) of baseline images
%   alpha            - Noise correction coefficient
%   ImgPath          - Path to save processed results
%
% Outputs:
%   Intensity_Map    - Normalized integrated intensity map (uint16)
%   Noise_Map        - Estimated baseline noise map (ΔN or \hat{N})
%
% Description:
%   1. Compute the estimated baseline image (Noise_Map) from Image_Baseline
%   2. Correct Image_Saturation using Noise_Map to reduce noise
%   3. Integrate along the temporal axis to obtain summed intensity
%   4. Normalize summed intensity to range [0, 60000]
%   5. Save the results as .tif and .mat files

    % Step 1: Compute estimated baseline (Noise_Map)
    Noise_Map = mean(Image_Baseline, 3);
    imwrite(uint16(Noise_Map), fullfile(ImgPath, 'Noise_Map.tif'));

    % Step 2: Noise correction
    intensity_image_denoise = Image_Saturation - alpha * Noise_Map;

    % Step 3: Integrate along time axis
    Intensity_Map = sum(intensity_image_denoise, 3);
    save(fullfile(ImgPath, 'Intensity_Map.mat'), 'Intensity_Map');

    % Step 4: Normalize to [0, 60000]
    min_value = min(Intensity_Map(:));
    max_value = max(Intensity_Map(:));
    new_min = 0;
    new_max = 60000;
    normalized_matrix = (Intensity_Map - min_value) / (max_value - min_value) * (new_max - new_min) + new_min;
    Intensity_Map = uint16(normalized_matrix);

    % Step 5: Save normalized integrated intensity map
    imwrite(Intensity_Map, fullfile(ImgPath, 'Intensity_Map.tif'));

    disp('FLIM PreProcessing finished.');

end
