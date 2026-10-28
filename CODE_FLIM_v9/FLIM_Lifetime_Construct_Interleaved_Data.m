function [H, new_t_axis] = FLIM_Lifetime_Construct_Interleaved_Data(Lifetime_data_4D, dt, time_shift,method)
% Construct interleaved fluorescence decay data and generate a new time axis
%
% Inputs:
%   Lifetime_data : W × L × extend_length_back × num_cycle
%   dt            : exposure time per frame
%   time_shift    : slight temporal offset of each cycle relative to the first cycle
%
% Outputs:
%   H             : W × L × (extend_length_back * num_cycle)
%   new_t_axis    : 1 × (extend_length_back * num_cycle)
%
% Notes:
%   - The function interleaves frames from all cycles into H.
%   - The new time axis accounts for dt and the cycle-specific time shift.
%

[W,L,extend_length_back,num_cycle] = size(Lifetime_data_4D);
H = zeros(W,L,extend_length_back*num_cycle);
switch lower(method)
                case 'accum' % --- Nonlinear exponential fitting ---
                new_t_axis = 0:dt:(size(Lifetime_data_4D,3)-1)*dt;
                H = squeeze(sum(Lifetime_data_4D,4));
                
                case 'all' % --- Nonlinear exponential fitting ---
                    % Initialize outputs
                    H = zeros(W,L,extend_length_back*num_cycle);
                    new_t_axis = zeros(1,extend_length_back*num_cycle,'double'); % ensure double precision
                    
                    % Construct interleaved data
                    for t = 1:extend_length_back
                        for c = 1:num_cycle
                            idx = (t-1)*num_cycle + c;       % linear index in H
                            H(:,:,idx) = Lifetime_data_4D(:,:,t,c);
                            
                            % Accumulate time using double precision
                            new_t_axis(idx) = (t-1)*dt + (c-1)*time_shift;
                        end
                    end
end


end
