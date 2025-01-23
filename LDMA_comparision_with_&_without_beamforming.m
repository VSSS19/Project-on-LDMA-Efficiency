clc; clear; close all;

% Run simulation with beamforming
disp('Running simulation WITH beamforming...');
[throughput_with_beamforming, user_locations_with_beamforming] = run_simulation(true);

% Run simulation without beamforming
disp('Running simulation WITHOUT beamforming...');
[throughput_without_beamforming, user_locations_without_beamforming] = run_simulation(false);

% Plot throughput comparison
figure;
plot(throughput_with_beamforming, '-o', 'LineWidth', 2, 'Color', 'b');
hold on;
plot(throughput_without_beamforming, '-x', 'LineWidth', 2, 'Color', 'r');
title('Throughput Comparison: With vs Without Beamforming');
xlabel('Simulation Step');
ylabel('Throughput');
legend('With Beamforming', 'Without Beamforming');
grid on;

% Plot region with antennas and users
figure;

% Shaded region for beamforming (left side)
fill([0, 5, 5, 0], [0, 0, 50, 50], 'b', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
hold on;

% Shaded region for no beamforming (right side)
fill([5, 10, 10, 5], [0, 0, 50, 50], 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');

% Users with beamforming (Region 1 - x < 5)
users_region_1 = user_locations_with_beamforming(user_locations_with_beamforming(:, 1) < 5, :);
% Users without beamforming (Region 2 - x >= 5)
users_region_2 = user_locations_without_beamforming(user_locations_without_beamforming(:, 1) >= 5, :);

% Plot users and antennas
scatter(users_region_1(:, 1), users_region_1(:, 2), 30, 'b', 'filled');
scatter(users_region_2(:, 1), users_region_2(:, 2), 30, 'r', 'filled');
antenna_positions = [2, 2; 8, 8];
scatter(antenna_positions(:, 1), antenna_positions(:, 2), 100, 'k', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 2);

% Annotate antennas
for i = 1:size(antenna_positions, 1)
    text(antenna_positions(i, 1) + 0.2, antenna_positions(i, 2), ['Antenna ' num2str(i)], 'Color', 'k', 'FontSize', 10);
end

title('Users and Antennas with Beamforming and Without Beamforming');
xlabel('X Position');
ylabel('Y Position');
legend('Region 1 (Beamforming)', 'Region 2 (No Beamforming)', 'Users with Beamforming', 'Users without Beamforming', 'Antennas', 'Location', 'best');
axis([0 10 0 50]);
grid on;
hold off;

%% Simulation function with optional beamforming
function [throughput_history, user_locations] = run_simulation(use_beamforming)
    % Parameters
    nfc_default_range = 15;
    area_size = 50;
    num_channels = 3;
    max_users = 200;
    entry_rate = 10;
    exit_rate = 5;
    simulation_steps = 10;
    user_count = 0;
    user_locations = [];
    throughput_history = zeros(simulation_steps, 1);

    for step = 1:simulation_steps
        % User entry and exit updates
        new_users = rand(min(entry_rate, max_users - user_count), 2) * area_size;
        user_locations = [user_locations; new_users];
        user_count = size(user_locations, 1);
        if user_count > exit_rate
            exit_indices = randperm(user_count, exit_rate);
            user_locations(exit_indices, :) = [];
            user_count = size(user_locations, 1);
        end

        % Channel assignment
        channel_assignment = zeros(user_count, 1);
        for i = 1:user_count
            for j = 1:num_channels
                distances = sqrt(sum((user_locations - user_locations(i,:)).^2, 2));
                nearby_users = find(distances < nfc_default_range & channel_assignment == j);
                if isempty(nearby_users)
                    channel_assignment(i) = j;
                    break;
                end
            end
        end
        
        % Throughput calculation
        throughput = sum(channel_assignment > 0) / num_channels;
        if use_beamforming
            throughput = throughput * 1.2;  
        end
        
        throughput_history(step) = throughput;
    end
end
