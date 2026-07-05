%% Compressive Sensing Project
% Course: Communication Systems Lab
% Date: 2025-03-08
% =========================================================================
% COMPRESSED SENSING DEMONSTRATION USING MATLAB BUILT-IN SPEECH SIGNAL
% =========================================================================
% This program demonstrates compressed sensing reconstruction of a speech signal
% from far fewer samples than required by the Nyquist sampling theorem.


clear; close all; clc; 

%% 1. LOAD AND PREPARE SPEECH SIGNAL
% -------------------------------------------------------------------------
% We'll use MATLAB's built-in speech signal for this demonstration

% Load the built-in speech signal 'mtlb' (MATLAB train bell)
load mtlb;  
x = mtlb;  % Store signal in variable x
fs = 7418; % Sampling frequency in Hz (specific to this built-in signal)

% Determine signal length and create time vector
N = length(x); % Total number of samples in signal
t = (0:N-1)/fs; % Time vector in seconds

% Ensure N is integer for proper indexing (fixes colon operator warning)
N = floor(N);
x = x(1:N); % Truncate signal to integer length
t = t(1:N); % Adjust time vector accordingly

% Normalize signal to [-1, 1] range for better numerical stability
x = x/max(abs(x));

% Plot original signal in time and frequency domains
figure('Name', 'Original Speech Signal', 'Color', 'white', 'Position', [100 100 900 600]);

% Time domain plot
subplot(2,1,1);
plot(t, x);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Speech Signal (Time Domain)');
grid on;
xlim([0 t(end)]);

% Frequency domain plot (shows signal sparsity)
X = abs(fft(x))/N; % Normalized FFT
f = linspace(0, fs, N); % Frequency vector
subplot(2,1,2);
plot(f(1:floor(N/2)), X(1:floor(N/2))); % Plot only positive frequencies
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Frequency Spectrum');
grid on;
xlim([0 fs/2]); % Show up to Nyquist frequency

%% 2. COMPRESSED SENSING PARAMETERS
% -------------------------------------------------------------------------
% Set up parameters for compressed sensing acquisition

compression_ratio = 0.3; % Fraction of Nyquist samples to use (30%)
M = floor(compression_ratio * N); % Number of measurements (must be integer)
K = 100; % Estimated sparsity (number of significant DCT coefficients)

% Display acquisition parameters
disp(['Original signal length: ', num2str(N)]);
disp(['Compressed measurements: ', num2str(M)]);
disp(['Compression ratio: ', num2str(compression_ratio)]);

%% 3. CREATE MEASUREMENT MATRIX
% -------------------------------------------------------------------------
% The measurement matrix determines how we sample the signal

% Random Gaussian measurement matrix (common choice for CS)
% Each entry is i.i.d. Gaussian random variable
Phi = randn(M, N)/sqrt(M); % Normalized by sqrt(M) for proper scaling

% Alternative: Random sampling matrix (selects random time samples)
% Uncomment to use instead of Gaussian matrix
% random_indices = randperm(N, M);
% Phi = zeros(M, N);
% for i = 1:M
%     Phi(i, random_indices(i)) = 1;
% end

% Take compressed measurements (y = Φx)
y = Phi * x;

% Visualize the measurement matrix
figure('Name', 'Measurement Matrix', 'Color', 'white');
imagesc(Phi);
colormap(gray);
colorbar;
title('Measurement Matrix \Phi');
xlabel('Signal Length N');
ylabel('Measurements M');

%% 4. SPARSE REPRESENTATION BASIS
% -------------------------------------------------------------------------
% Speech signals are sparse in the DCT domain (few significant coefficients)

% Create DCT basis matrix (type II DCT)
Psi = dctmtx(N)'; % Transpose gives analysis (forward transform) matrix

% Combined sensing matrix (A = ΦΨ)
A = Phi * Psi; % Relates sparse coefficients to measurements

%% 5. SPARSE RECOVERY USING L1 MINIMIZATION
% -------------------------------------------------------------------------
% Reconstruct sparse coefficients by solving min ||s||_1 s.t. y = As

tic; % Start timer to measure reconstruction time
s = zeros(N,1); % Initialize solution vector

% Attempt different solvers in order of preference:

% Option 1: Try l1magic package if available (most accurate)
if exist('l1eq_pd.m', 'file')
    try
        s = l1eq_pd(s, A, [], y, 1e-3); % Primal-dual interior point method
    catch
        warning('l1magic failed, trying alternative methods');
    end
end

% Option 2: Try CVX convex optimization package if available
if all(s == 0) && exist('cvx_begin.m', 'file')
    try
        cvx_begin quiet
            variable s_cvx(N) % Optimization variable
            minimize(norm(s_cvx,1)) % L1 minimization
            subject to
                A*s_cvx == y % Measurement constraint
        cvx_end
        s = s_cvx;
    catch
        warning('CVX failed, trying built-in methods');
    end
end

% Option 3: Use MATLAB's built-in linear programming (most accessible)
if all(s == 0)
    opts = optimoptions('linprog', 'Display', 'off');
    
    % Reformulate L1 minimization as linear program:
    % min ||s||_1 becomes min sum(t) s.t. -t ≤ s ≤ t
    f = [zeros(N,1); ones(N,1)]; % Objective: [0 for s; 1 for t]
    Aeq = [A, -A]; % Equality constraints [A -A][s; t] = y
    lb = [-Inf(N,1); zeros(N,1)]; % Lower bounds: s unbounded, t ≥ 0
    ub = Inf(2*N,1); % Upper bounds: no upper limit
    
    sol = linprog(f, [], [], Aeq, y, lb, ub, opts);
    s = sol(1:N) - sol(N+1:2*N); % Recover s from solution
end

reconstruction_time = toc; % Measure reconstruction time

% Reconstruct signal from sparse coefficients (x = Ψs)
x_rec = Psi * s;

%% 6. RESULTS VISUALIZATION
% -------------------------------------------------------------------------
% Compare original and reconstructed signals

figure('Name', 'Reconstruction Results', 'Color', 'white', 'Position', [100 100 1200 800]);

% Time domain comparison (zoomed in segment)
subplot(3,2,1);
plot(t, x, 'b', 'LineWidth', 1.5);
hold on;
plot(t, x_rec, 'r--', 'LineWidth', 1);
xlabel('Time (s)');
ylabel('Amplitude');
title('Time Domain Comparison');
legend('Original', 'Reconstructed');
grid on;
xlim([0.2 0.25]); % Zoom to show detail

% Frequency domain comparison
X_rec = abs(fft(x_rec))/N;
subplot(3,2,2);
plot(f(1:floor(N/2)), X(1:floor(N/2)), 'b', 'LineWidth', 1.5);
hold on;
plot(f(1:floor(N/2)), X_rec(1:floor(N/2)), 'r--', 'LineWidth', 1);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Frequency Domain Comparison');
legend('Original', 'Reconstructed');
grid on;
xlim([0 4000]); % Focus on lower frequencies where speech energy concentrates

% Reconstruction error
subplot(3,2,3);
plot(t, abs(x - x_rec));
xlabel('Time (s)');
ylabel('Error');
title('Reconstruction Error');
grid on;

% Sparse coefficients in DCT domain
subplot(3,2,4);
stem(abs(s), 'filled', 'MarkerSize', 2);
xlabel('Coefficient Index');
ylabel('Magnitude');
title('Sparse Coefficients in DCT Domain');
xlim([0 1000]); % Show first 1000 coefficients (most energy here)
grid on;

% Spectrogram comparison (time-frequency analysis)
nfft = 256; % FFT size
window = hamming(nfft); % Window function
noverlap = round(0.75*nfft); % Overlap between segments

% Original spectrogram
subplot(3,2,5);
spectrogram(x, window, noverlap, nfft, fs, 'yaxis');
title('Original Spectrogram');
colorbar off;

% Reconstructed spectrogram
subplot(3,2,6);
spectrogram(x_rec, window, noverlap, nfft, fs, 'yaxis');
title('Reconstructed Spectrogram');
colorbar off;

%% 7. AUDIO PLAYBACK (OPTIONAL)
% -------------------------------------------------------------------------
% Listen to original and reconstructed signals

disp('Playing original speech...');
soundsc(x, fs); % Play original signal
pause(length(x)/fs + 1); % Wait for playback to finish

disp('Playing reconstructed speech...');
soundsc(x_rec, fs); % Play reconstructed signal

%% 8. PERFORMANCE METRICS
% -------------------------------------------------------------------------
% Calculate quantitative reconstruction quality metrics

% Mean Squared Error (MSE)
mse = mean((x - x_rec).^2);

% Signal-to-Noise Ratio (SNR) in dB
snr = 10*log10(mean(x.^2)/mean((x - x_rec).^2));

% Display metrics
disp(['Reconstruction time: ', num2str(reconstruction_time), ' seconds']);
disp(['Mean Squared Error: ', num2str(mse)]);
disp(['Signal-to-Noise Ratio: ', num2str(snr), ' dB']);