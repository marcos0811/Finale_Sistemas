function [x_eq] = ecualizador(x_original, x_procesada, fs_procesada, opcion, G_dB)
    % Validar que G_dB tenga 6 elementos
    if length(G_dB) ~= 6
        error('G_dB debe tener 6 valores');
    end

    % Transformar ganancias dB a factor lineal
    G = 10.^(G_dB/20);

    f = linspace(-fs_procesada/2, fs_procesada/2, length(x_procesada));
    X = fftshift(fft(x_procesada));

    % Definir filtros banda con factor de ganancia
    F0 = G(1) * ((abs(f) >= 16)    & (abs(f) < 60));
    F1 = G(2) * ((abs(f) >= 60)    & (abs(f) < 250));
    F2 = G(3) * ((abs(f) >= 250)   & (abs(f) < 2000));
    F3 = G(4) * ((abs(f) >= 2000)  & (abs(f) < 4000));
    F4 = G(5) * ((abs(f) >= 4000)  & (abs(f) < 6000));
    F5 = G(6) * ((abs(f) >= 6000)  & (abs(f) < 16000));

    H = F0 + F1 + F2 + F3 + F4 + F5;

    if opcion == 'd'
        X_eq = X .* H;
    else
        X_eq = X .* H';
    end

    x_eq = real(ifft(ifftshift(X_eq)));
end
