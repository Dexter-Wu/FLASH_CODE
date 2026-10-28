function [I_enhancement, est_back_crop] = FLIM_Intensity_BackgroundRemoval(I, avg_size, beta, ImgPath)
% FLIM_BackgroundRemoval - Iterative background estimation and removal for FLIM images (simplified)
%
% Syntax:
%   [I_enhancement, est_back_crop] = FLIM_BackgroundRemoval(I, avg_size, beta)
%
% Inputs:
%   I        - Input image (grayscale or RGB)
%   avg_size - Averaging filter size for iterative background estimation
%   beta     - Iteration stop threshold coefficient (relative to max intensity)
%   ImgPath             - Path to save results (optional)
%
% Outputs:
%   I_enhancement - Background-subtracted image
%   est_back_crop - Estimated background image

    warning('off');

    % Convert to double
    I = double(I);

    % Initialize background estimate
    est_back = I;
    I_add_back = I;

    % Iterative background estimation
    f_avg = fspecial('average', [avg_size, avg_size]);
    max_val = max(I(:));
    iter_th = beta * max_val;
    iter_num = 100;

    for i = 1:iter_num
        est_back_avg = imfilter(est_back, f_avg, 'replicate');
        est_back(est_back > est_back_avg) = est_back_avg(est_back > est_back_avg);

        est_back_crop_curr = est_back;

        if i > 1
            max_error = max(abs(est_back_crop_curr(:) - est_back_crop_last(:)));
            if max_error < iter_th
                break;
            end
        end
        est_back_crop_last = est_back_crop_curr;
    end

    % Subtract estimated background
    I_enhancement = I_add_back - est_back_crop_curr;
    I_enhancement(I_enhancement < 0) = 0;

    % Output cropped estimated background
    est_back_crop = est_back_crop_curr;

    %% save
    save(fullfile(ImgPath, 'I_enhancement.mat'), 'I_enhancement');
    save(fullfile(ImgPath, 'est_back_crop.mat'), 'est_back_crop');
    I_descattering = uint16(I_enhancement);
    imwrite(I_descattering, fullfile(ImgPath, 'I_enhancement.tif'));

end
