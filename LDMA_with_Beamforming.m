clc; clear; close all;

%% Parameters
nfc_default_range = 15;
area_size = 50;
min_distance = 8;
num_fixed_antennas = 4;
num_channels = 3;
max_users = 200;
mobility_enabled = true;
entry_rate = 10;
exit_rate = 5;
simulation_steps = 10;

user_count = 0; 
user_locations = [];

grid_size = ceil(sqrt(num_fixed_antennas));
spacing = area_size / (grid_size - 1);
[x_grid, y_grid] = meshgrid(linspace(0, area_size, grid_size), linspace(0, area_size, grid_size));
antenna_positions = [x_grid(:), y_grid(:)];
antenna_positions = antenna_positions(1:num_fixed_antennas, :);

spectrum_efficiency_history = zeros(simulation_steps, num_channels);
interference_history = zeros(simulation_steps, num_channels);

%% Simulation
for step = 1:simulation_steps
    new_users = rand(min(entry_rate, max_users - user_count), 2) * area_size;
    user_locations = [user_locations; new_users];
    user_count = size(user_locations, 1);

    if user_count > exit_rate
        exit_indices = randperm(user_count, exit_rate);
        user_locations(exit_indices, :) = [];
        user_count = size(user_locations, 1);
    end

    channel_assignment = zeros(user_count, 1);
    for i = 1:user_count
        for j = 1:num_channels
            distances = sqrt(sum((user_locations - user_locations(i,:)).^2, 2));  
            nearby_users = find(distances < min_distance & channel_assignment == j);
            if isempty(nearby_users)
                channel_assignment(i) = j;
                break;
            end
        end
    end

    total_interference = zeros(num_channels, 1);
    for i = 1:num_channels
        users_in_channel = find(channel_assignment == i);
        if length(users_in_channel) > 1
            for j = 1:length(users_in_channel)
                for k = j+1:length(users_in_channel)
                    distance = norm(user_locations(users_in_channel(j), :) - user_locations(users_in_channel(k), :));
                    if distance < nfc_default_range
                        interference = 1 / distance;
                        total_interference(i) = total_interference(i) + interference;
                    end
                end
            end
        end
    end

    interference_history(step, :) = total_interference;

    spectrum_efficiency = zeros(num_channels, 1);
    for i = 1:num_channels
        spectrum_efficiency(i) = sum(channel_assignment == i) / user_count * 100;
    end

    spectrum_efficiency_history(step, :) = spectrum_efficiency;

    if mobility_enabled
        user_movement = (rand(user_count, 2) - 0.5) * 2;
        user_locations = user_locations + user_movement;
        user_locations = max(min(user_locations, area_size), 0);
    end
end

% Plot interference history
figure;
hold on;
colors = lines(num_channels);
for i = 1:num_channels
    plot(1:simulation_steps, interference_history(:, i), 'LineWidth', 2, 'Color', colors(i, :));
end
title('Interference Over Time');
xlabel('Simulation Step');
ylabel('Total Interference');
legend(arrayfun(@(x) ['Channel ' num2str(x)], 1:num_channels, 'UniformOutput', false));
grid on;

% Average interference display
average_interference = mean(interference_history, 1);
disp('Average Interference:');
disp(array2table(average_interference, 'VariableNames', arrayfun(@(x) ['Channel ' num2str(x)], 1:num_channels, 'UniformOutput', false)));

% Plot spectrum efficiency
figure;
hold on;
for i = 1:num_channels
    plot(1:simulation_steps, spectrum_efficiency_history(:, i), 'LineWidth', 2, 'Color', colors(i, :));
end
title('Spectrum Efficiency Over Time');
xlabel('Simulation Step');
ylabel('Spectrum Efficiency (%)');
legend(arrayfun(@(x) ['Channel ' num2str(x)], 1:num_channels, 'UniformOutput', false));
grid on;

% Average spectrum efficiency display
average_spectrum_efficiency = mean(spectrum_efficiency_history, 1);
disp('Average Spectrum Efficiency:');
disp(array2table(average_spectrum_efficiency, 'VariableNames', arrayfun(@(x) ['Channel ' num2str(x)], 1:num_channels, 'UniformOutput', false)));
