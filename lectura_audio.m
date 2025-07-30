function [x, fs, t] = lectura_audio(nombre_archivo)
    if ~isfile(nombre_archivo)
        error('El archivo "%s" no se encuentra en la carpeta actual.', nombre_archivo);
    end

    [audioData, fs] = audioread(nombre_archivo);

    if size(audioData, 2) == 2
        x = 0.5 * (audioData(:,1) + audioData(:,2)).';
    else
        x = audioData.';
    end

    duration = length(x) / fs;
    t = linspace(0, duration, length(x));
end
