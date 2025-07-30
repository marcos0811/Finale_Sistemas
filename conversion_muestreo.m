function [x_out, fs_out] = conversion_muestreo(x_in, fs_in, tipo, factor)
    % x_in: señal original (en tiempo discreto)
    % fs_in: frecuencia de muestreo original
    % tipo: 'decimacion' o 'expansion'
    % factor: valor entero de M o L
    % x_out: señal convertida
    % fs_out: nueva frecuencia de muestreo

    % Validar tipo
    if ~any(strcmp(tipo, {'decimacion', 'expansion'}))
        error('El tipo debe ser ''decimacion'' o ''expansion''.');
    end

    if factor <= 1
        % Si el factor es 1 o menor, no hacer nada
        x_out = x_in;
        fs_out = fs_in;
        fprintf('Factor igual o menor a 1. No se realizó %s.\n', tipo);
        return;
    end

    % ----------------------------------------
    % DECIMACIÓN ↓M
    % ----------------------------------------
    if strcmp(tipo, 'decimacion')
        M = factor;
        % Filtro anti-aliasing (pasabajo)
        h = fir1(128, 1/M); % Filtro FIR de orden 128
        x_filtrada = filter(h, 1, x_in); % Señal filtrada
        x_out = x_filtrada(1:M:end); % Muestreo cada M
        fs_out = fs_in / M;
        label = sprintf('Decimación por M = %d', M);
    
    % ----------------------------------------
    % EXPANSIÓN ↑L
    % ----------------------------------------
    elseif strcmp(tipo, 'expansion')
        L = factor;
        % Insertar ceros entre muestras
        x_exp = zeros(1, length(x_in)*L);
        x_exp(1:L:end) = x_in; % Insertar cada muestra
        % Filtro de interpolación (pasabajo)
        h = fir1(128, 1/L); 
        x_out = filter(h, 1, x_exp); % Señal interpolada
        fs_out = fs_in * L;
        label = sprintf('Expansión por L = %d', L);
    end

    % ----------------------------------------
    % GRAFICAR RESULTADOS
    % ----------------------------------------
    t_out = linspace(0, length(x_out)/fs_out, length(x_out));
    figure;
    subplot(2,1,1);
    plot(t_out, x_out);
    title(['Señal después de ', tipo]);
    xlabel('Tiempo [s]');
    ylabel('Amplitud');
    grid on;

    % Espectro
    Xf = fftshift(fft(x_out));
    f = linspace(-fs_out/2, fs_out/2, length(Xf));
    subplot(2,1,2);
    plot(f, abs(Xf)/max(abs(Xf)));
    title(['Espectro después de ', tipo, ' (', label, ')']);
    xlabel('Frecuencia [Hz]');
    ylabel('Magnitud Normalizada');
    grid on;

    % Mostrar frecuencia resultante
    % fprintf('Frecuencia de muestreo después de %s: %.2f Hz\n', tipo, fs_out);
end