function intensity_image = FLIM_Extraction_Intensity(Database_all,Initial_point,extend_length_back,impulse_period,freq,num_cycle)
% FLIM_Extraction_Intensity_Progress - Extract intensity images for FLIM with progress bar
%
%   Input arguments:
%       Database_all        - 3D data matrix (len × wid × Img_length), typically a time sequence
%       Initial_point       - Starting index for extraction
%       extend_length_back  - Number of frames to extract each cycle
%       impulse_duty        - Excitation pulse period
%       freq                - Repetition frequency
%       num_cycle           - Number of extraction cycles
%       Img_length          - Total number of frames

%
%   Output:
%       intensity_image     - 3D intensity image (len × wid × extend_length_back*num_cycle)
%
%   Description:
%       This function periodically extracts segments from the time series
%       and concatenates them into a new 3D matrix. A graphical progress
%       bar (waitbar) is displayed to indicate the progress of the cycles.
%
%   Example:
%       img = FLIM_Extraction_Intensity_Progress(Database_all,100,50,10,2,5,1000,'C:\results');
    Img_length = size(Database_all,3);
    intensity_image = [];   % Initialize as empty
    disp('FLIM intensity extraction is running...');

    % Starting index
    mark_temp_all = Initial_point; 

    % Initialize progress bar
    h = waitbar(0,'FLIM intensity extraction in progress...');
    tic
    % Cycle extraction
    for k = 1:num_cycle

        if mark_temp_all + extend_length_back -1 > Img_length
            break;
        end

        % Extract segment
        intensity_image_temp = Database_all(:,:,mark_temp_all : mark_temp_all + extend_length_back -1);

        % Concatenate results
        intensity_image = cat(3,intensity_image,intensity_image_temp);

        % Update starting point
        mark_temp_all = mark_temp_all + impulse_period*freq;

        if mark_temp_all > Img_length
            break;
        end

        % Update progress bar
        waitbar(k/num_cycle, h, sprintf('Cycle %d / %d', k, num_cycle));
    end

    % Close progress bar
    close(h);
    elapsed_time = toc;   % stop timer
    disp(['FLIM intensity extraction finished in ', num2str(elapsed_time, '%.2f'), ' seconds.']);
end
