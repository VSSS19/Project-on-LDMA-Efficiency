clc; clear; close all;

%% Parameters
nfc_default_range = 15;             
area_size = 100;                    
min_distance = 8;                   
num_fixed_antennas = 4;             
num_channels = 3;                   
max_users = 200;                    
mobility_enabled = true;            
entry_rate = 10;                    
exit_rate = 5;                      
simulation_steps = 30;              

user_count = 0; 
user_locations = [];  

grid_size = ceil(sqrt(num_fixed_antennas));  
spacing = area_size / (grid_size - 1);       

[x_grid, y_grid] = meshgrid(linspace(0, area_size, grid_size), linspace(0, area_size, grid_size));
antenna_positions = [x_grid(:), y_grid(:)];
antenna_positions = antenna_positions(1:num_fixed_antennas, :);  

video_filename = 'user_locations_video.avi';
video_writer = VideoWriter(video_filename);
open(video_writer);

%% Simulation loop
for step = 1:simulation_steps
    new_users = rand(min(entry_rate, max_users - user_count), 2) * area_size;
    user_locations = [user_locations; new_users];  
    user_count = size(user_locations, 1);

    if user_count > exit_rate
        exit_indices = randperm(user_count, exit_rate);  
        user_locations(exit_indices, :) = [];
        user_count = size(user_locations, 1);
    end

    half_area_x = area_size / 2;
    channel_assignment = zeros(user_count, 1);  
    beamforming_directions = zeros(num_fixed_antennas, 2);

    for i = 1:user_count
        if user_locations(i, 1) < half_area_x  
            for j = 1:num_channels
                distances = sqrt(sum((user_locations - user_locations(i,:)).^2, 2));  
                nearby_users = find(distances < min_distance & channel_assignment == j);
                if isempty(nearby_users)  
                    channel_assignment(i) = j;
                    break;
                end
            end

            for k = 1:num_fixed_antennas
                distances = sqrt(sum((user_locations - antenna_positions(k,:)).^2, 2));
                if ~isempty(distances)
                    [~, closest_user] = min(distances);  
                    beamforming_directions(k, :) = (user_locations(closest_user, :) - antenna_positions(k, :)) / norm(user_locations(closest_user, :) - antenna_positions(k, :));  
                end
            end
        else  
            for j = 1:num_channels
                distances = sqrt(sum((user_locations - user_locations(i,:)).^2, 2));  
                nearby_users = find(distances < min_distance & channel_assignment == j);
                if isempty(nearby_users)  
                    channel_assignment(i) = j;
                    break;
                end
            end
        end
    end

    figure(1);
    clf;
    hold on;
    colors = lines(num_channels);
    for i = 1:num_channels
        scatter(user_locations(channel_assignment == i, 1), user_locations(channel_assignment == i, 2), 100, colors(i,:), 'filled');
    end
    scatter(antenna_positions(:, 1), antenna_positions(:, 2), 200, 'k', 'x');

    for i = 1:num_fixed_antennas
        if antenna_positions(i, 1) < half_area_x  
            quiver(antenna_positions(i, 1), antenna_positions(i, 2), beamforming_directions(i, 1)*10, beamforming_directions(i, 2)*10, 'r', 'LineWidth', 1.5);
        end
    end
    
    plot([half_area_x, half_area_x], [0, area_size], 'k--', 'LineWidth', 2);  

    title(['Step ' num2str(step) ': User Locations and Channel Assignment (LDMA with/without Beamforming)']);
    xlabel('X Coordinate');
    ylabel('Y Coordinate');
    legend('Channel 1', 'Channel 2', 'Channel 3', 'Fixed Antennas', 'Beamforming Directions');
    grid on;
    
    frame = getframe(gcf);
    writeVideo(video_writer, frame);

    if mobility_enabled
        user_movement = (rand(user_count, 2) - 0.5) * 2;
        user_locations = user_locations + user_movement;
        user_locations = max(min(user_locations, area_size), 0);
    end
end

close(video_writer);
disp(['Video saved as: ' video_filename]);
