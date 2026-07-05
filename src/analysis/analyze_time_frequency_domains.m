%% Time-Frequency Domain Analysis
% Course: Communication Systems Lab
% Date: 2025-03-08

%% CLEAR
clc;
clear;
close all;

figure;  % Create a single figure for all plots

%% ============================
% 1. Voice Signal (Time Domain)
% ============================
load handel.mat;                         % Load built-in 'y' and 'Fs' variables
voice_signal = y;
Fs_voice = Fs;
t_voice = (0:length(voice_signal) - 1) / Fs_voice;

% Bit size for time domain (assuming 16 bits per sample)
bits_per_sample = 16;                    % Common bit depth for audio
time_domain_bits = length(voice_signal) * bits_per_sample;

% Frequency Domain of Voice Signal
voice_fft = fft(voice_signal);
freq_domain_bits = length(voice_fft) * bits_per_sample;

% Plot Time Domain and Frequency Domain
plot_signal(t_voice, voice_signal, Fs_voice, 'Voice Signal', 1);

% Display Bit Size for Voice Signal
fprintf('Voice Signal Bit Size:\n');
fprintf('Time Domain: %d bits\n', time_domain_bits);
fprintf('Frequency Domain: %d bits\n\n', freq_domain_bits);

%% ============================
% 2. Image Signal
% ============================
img = imread('peppers.png');             % Load a built-in image
img_gray = rgb2gray(img);                % Convert to grayscale

% Bit size for original image (assuming 8 bits per pixel for grayscale)
[rows, cols] = size(img_gray);
img_time_domain_bits = rows * cols * 8;  % 8 bits per pixel

% Frequency Domain of Image
img_fft = fft2(double(img_gray));        % 2D FFT of the image
img_fft_shifted = fftshift(log(abs(img_fft) + 1));

% Bit size for frequency domain (assuming same bit depth)
img_freq_domain_bits = numel(img_fft) * 8;  % 8 bits per transformed value

% Plot Image and Frequency Domain
subplot(2, 2, 3);
imshow(img_gray);
title('Original Image Signal');
% Display pixel count under the image
text(size(img_gray, 2) / 2, size(img_gray, 1) + 20, ...
    ['Pixels: ', num2str(rows * cols)], ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

subplot(2, 2, 4);
imshow(uint8(mat2gray(img_fft_shifted) * 255));
title('Frequency Domain of Image Signal');
% Display pixel count under the frequency domain image
text(size(img_fft_shifted, 2) / 2, size(img_fft_shifted, 1) + 20, ...
    ['Pixels: ', num2str(numel(img_fft))], ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

% Display Bit Size for Image Signal
fprintf('Image Signal Bit Size:\n');
fprintf('Time Domain: %d bits\n', img_time_domain_bits);
fprintf('Frequency Domain: %d bits\n', img_freq_domain_bits);

%% ============================
% Function to Plot Time and Frequency Domain
% ============================
function plot_signal(t, signal, Fs, title_text, index)
    N = length(signal);
    f = (-N/2:N/2-1) * (Fs / N);        % Frequency vector

    % Compute FFT and shift zero frequency to center
    signal_fft = fftshift(fft(signal));
    signal_magnitude = abs(signal_fft) / N;

    % Plot Time Domain
    subplot(2, 2, (index - 1) * 2 + 1);
    plot(t, signal);
    title([title_text, ' (Time Domain)']);
    xlabel('Time (s)');
    ylabel('Amplitude');

    % Plot Frequency Domain
    subplot(2, 2, (index - 1) * 2 + 2);
    plot(f, signal_magnitude);
    title([title_text, ' (Frequency Domain)']);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
end