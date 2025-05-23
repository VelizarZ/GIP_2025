clear all% Define the objective function
function cost = computeRMS(parameters)
    % Extract optimization variables
    Kmax = parameters(1);  % Maximum spring coefficient
    Kmin = parameters(2);  % Minimum spring coefficient
    c = parameters(3);    % damping coefficient
    b = parameters(4);     % Inerter value (kg)

    % Update parameters in Simulink
    set_param('damper_model/VDD/Kmax', 'constant', num2str(Kmax)); 
    set_param('damper_model/VDD/Kmin', 'constant', num2str(Kmin)); 
    set_param('damper_model/KL3_spring', 'spr_rate', num2str(c)); 
    set_param('damper_model/KL3_inerter', 'B', num2str(b));

    % Run the simulation
    simOut = sim('damper_model.slx');

     % Extract acceleration data from the simulation output
    H2631 = simOut.Z2A2631; % Access the acceleration data (timeseries object)

    % Compute RMS of the filtered acceleration
    cost = rms(H2631); % Calculate RMS acceleration


    % Print current values for tracking
    fprintf('Kmax: %.2f, Kmin: %.2f, Damper: %.2f, Inerter: %.2f, RMS: %.6f\n', ...
            Kmax, Kmin, c, b, cost);
end

% Define bounds for the parameters
lower_bounds = [700, 70, 1, 1];   % [Cmax, Cmin, Spring stiffness, Inerter]
upper_bounds = [1000, 1000, 20000, 50]; % [Cmax, Cmin, Spring stiffness, Inerter]

% Initial guess for the parameters
initial_guess = [20000, 5000, 15000, 10]; % [Cmax, Cmin, Spring stiffness, Inerter]

% Set optimization options
options = optimoptions('patternsearch', 'Display', 'iter', ...
    'UseCompletePoll', true, 'UseCompleteSearch', true, ...
    'PollMethod', 'GPSPositiveBasis2N', 'MeshTolerance', 1e-3);

% Run the optimization using pattern search
[optimal_params, optimal_rms] = patternsearch(@computeRMS, initial_guess, [], [], [], [], ...
                                              lower_bounds, upper_bounds, [], options);

% Extract optimized values
optimal_Kmax = optimal_params(1);
optimal_Kmin = optimal_params(2);
optimal_c = optimal_params(3);
optimal_b = optimal_params(4);

fprintf('\nOptimal Kmax: %.2f N/m\n', optimal_Kmax);
fprintf('Optimal Kmin: %.2f N/m\n', optimal_Kmin);
fprintf('Optimal damping: %.2f Ns/m\n', optimal_c);
fprintf('Optimal Inerter: %.2f kg\n', optimal_b);
fprintf('Minimum RMS Acceleration: %.6f m/s^2\n', optimal_rms);

% Update the Simulink model with the optimized values
set_param('damper_model/VDD/Kmax', 'Gain', num2str(optimal_Kmax));
set_param('damper_model/VDD/Kmax', 'Gain', num2str(optimal_Kmin));
set_param('damper_model/KL3_spring', 'spr_rate', num2str(optimal_c));
set_param('damper_model/KL3_inerter', 'B', num2str(optimal_b));
