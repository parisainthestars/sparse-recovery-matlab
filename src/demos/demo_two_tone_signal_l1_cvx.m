% Compressed Sensing Demonstration
% Signal: 0.7*cos(150*pi*t) + 0.3*cos(3000*pi*t)

clear all; close all; clc;

%% Signal Parameters
fs = 10000;             % Sampling frequency (Hz)
T = 0.1;                % Duration (seconds)
N = fs * T;             % Number of samples
t = linspace(0, T, N);  % Time vector

% Original signal
f1 = 150;               % First frequency (Hz)
f2 = 3000;              % Second frequency (Hz)
x = 0.7*cos(2*pi*f1*t) + 0.3*cos(2*pi*f2*t);

% Plot original signal
figure('Name', 'Original Signal', 'Color', 'white');
subplot(2,1,1);
plot(t, x);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Signal in Time Domain');
grid on;

% Frequency domain
X = fft(x)/N;
f = linspace(0, fs, N);
subplot(2,1,2);
plot(f(1:N/2), abs(X(1:N/2)));
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Frequency Domain');
grid on;
xlim([0 4000]);

%% Compressed Sensing Parameters
M = 300;                % Number of measurements (compressed)
K = 2;                  % Sparsity level (we know there are 2 frequencies)

%% Step 1: Random Sampling
% Create random measurement matrix (Gaussian)
Phi = randn(M, N);

% Take compressed measurements
y = Phi * x';

% Plot measurement process
figure('Name', 'Measurement Process', 'Color', 'white');
imagesc(Phi);
colormap(gray);
colorbar;
title('Measurement Matrix \Phi');
xlabel('Signal Length N');
ylabel('Measurements M');

%% Step 2: Reconstruction using L1 Minimization
% We'll use the DCT basis as our sparse representation basis
Psi = dctmtx(N)';

% Create the sensing matrix
A = Phi * Psi;

% Solve the L1 minimization problem using Basis Pursuit
% Using CVX toolbox for convex optimization
cvx_begin quiet
    variable s(N) complex;
    minimize(norm(s,1));
    subject to
        A*s == y;
cvx_end

% Reconstruct the signal
x_rec = Psi * s;

%% Step 3: Results Comparison
% Plot original vs reconstructed signal in time domain
figure('Name', 'Reconstruction Results', 'Color', 'white');
subplot(2,2,1);
plot(t, x, 'b', 'LineWidth', 1.5);
hold on;
plot(t, real(x_rec), 'r--', 'LineWidth', 1);
xlabel('Time (s)');
ylabel('Amplitude');
title('Time Domain Comparison');
legend('Original', 'Reconstructed');
grid on;
xlim([0 0.02]);

% Plot original vs reconstructed in frequency domain
X_rec = fft(x_rec)/N;
subplot(2,2,2);
plot(f(1:N/2), abs(X(1:N/2)), 'b', 'LineWidth', 1.5);
hold on;
plot(f(1:N/2), abs(X_rec(1:N/2)), 'r--', 'LineWidth', 1);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Frequency Domain Comparison');
legend('Original', 'Reconstructed');
grid on;
xlim([0 4000]);

% Plot reconstruction error
subplot(2,2,3);
plot(t, abs(x' - x_rec));
xlabel('Time (s)');
ylabel('Error');
title('Reconstruction Error');
grid on;

% Plot sparse coefficients
subplot(2,2,4);
stem(abs(s), 'filled', 'MarkerSize', 3);
xlabel('Coefficient Index');
ylabel('Magnitude');
title('Sparse Coefficients in DCT Domain');
xlim([0 5000]);
grid on;

%% Step 4: Measurement vs Reconstruction Tradeoff
% Calculate reconstruction error for different M values
M_values = round(linspace(50, 800, 20));
errors = zeros(size(M_values));

for i = 1:length(M_values)
    % Take measurements
    Phi_temp = randn(M_values(i), N);
    y_temp = Phi_temp * x';
    
    % Reconstruct
    A_temp = Phi_temp * Psi;
    
    cvx_begin quiet
        variable s_temp(N) complex;
        minimize(norm(s_temp,1));
        subject to
            A_temp*s_temp == y_temp;
    cvx_end
    
    x_temp = Psi * s_temp;
    errors(i) = norm(x' - x_temp)/norm(x);
end

% Plot error vs measurements
figure('Name', 'Measurement Tradeoff', 'Color', 'white');
plot(M_values, errors, 'b-o', 'LineWidth', 2);
xlabel('Number of Measurements (M)');
ylabel('Normalized Reconstruction Error');
title('Reconstruction Error vs Number of Measurements');
grid on;