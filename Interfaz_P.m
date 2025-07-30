function audio_gui()
    % Cremos figura principal
    fig = uifigure('Name','Procesamiento Audio','Position',[100 100 950 600]);

    % --- Entrada de nombre de archivo ---
    lblArchivo = uilabel(fig,'Position',[20 550 150 22],'Text','Archivo audio (.wav):');
    edtArchivo = uieditfield(fig,'text','Position',[170 550 200 22]);

    % Botones para cargar y reproducir audio
    btnCargar = uibutton(fig,'push','Position',[380 555 120 30],'Text','Cargar Audio');
    btnReproducir = uibutton(fig,'push','Position',[510 555 120 30],'Text','Reproducir Audio', 'Enable','off');

    % Checkbox para indicar si el archivo está cargado
    chkCargado = uicheckbox(fig,'Position',[380 525 150 22],'Text','Archivo cargado','Value',false,'Enable','off');

    % Etiquetas para mostrar info separada (nombre, duración, frecuencia)
    lblNombre = uilabel(fig,'Position',[20 520 600 22],'Text','Nombre: ');
    lblDuracion = uilabel(fig,'Position',[20 490 600 22],'Text','Duración: ');
    lblFs = uilabel(fig,'Position',[20 460 600 22],'Text','Frecuencia de muestreo: ');

    % Opción Decimación o Interpolación (dropdown)
    lblOpc = uilabel(fig,'Position',[20 420 180 22],'Text','Decimación o Interpolación:');
    ddOpc = uidropdown(fig,'Position',[210 420 120 22],'Items',{'Decimación','Interpolación'});

    % Factor de conversión (numérico)
    lblFactor = uilabel(fig,'Position',[20 380 180 22],'Text','Factor de conversión:');
    edtFactor = uieditfield(fig,'numeric','Position',[210 380 120 22],'Limits',[1 Inf],'RoundFractionalValues',true);

    % Etiquetas y sliders para ganancias de 6 bandas
    bandas = {
        'Sub-Bass (16–60 Hz)', ...
        'Bass (60–250 Hz)', ...
        'Low Mids (250–2000 Hz)', ...
        'High Mids (2000–4000 Hz)', ...
        'Presence (4000–6000 Hz)', ...
        'Brilliance (6000–16000 Hz)'
    };
    sliders = gobjects(1,6); % preallocación

    y_pos = 340; % posición vertical inicial para el primer slider
    for i = 1:6
        uilabel(fig,'Position',[20 y_pos 180 22],'Text',bandas{i});
        sliders(i) = uislider(fig,'Position',[210 y_pos+10 200 3],'Limits',[-24 24],'Value',0);
        y_pos = y_pos - 40;
    end

    % Botón para procesar
    btnProcesar = uibutton(fig,'push','Position',[430 490 150 30],'Text','Procesar Audio','Enable','off','FontWeight','bold');
    % Label para mostrar frecuencia de muestreo después de conversión
    lblFsConvertida = uilabel(fig, 'Position', [20 80 400 22], 'Text', '');

    % Callbacks
    btnCargar.ButtonPushedFcn = @(btn,event) cargarAudio();
    btnReproducir.ButtonPushedFcn = @(btn,event) reproducirAudio();
    btnProcesar.ButtonPushedFcn = @(btn,event) procesarAudio();

    % Ejes para graficar señal y espectro
    ax1 = uiaxes(fig,'Position',[440 290 490 200]);
    ax1.Title.String = 'Señal';

    ax2 = uiaxes(fig,'Position',[440 80 490 200]);
    ax2.Title.String = 'Espectro';

    % Variables para guardar audio y fs
    data = struct('x',[],'fs',[],'x_proc',[],'fs_proc',[],'x_eq',[]);


    %% Función para cargar audio
    function cargarAudio()
        archivo = edtArchivo.Value;
        if isempty(archivo)
            uialert(fig,'Debe ingresar el nombre del archivo.','Error');
            return;
        end
    
        % Aquí llamamos a la función personalizada lectura_audio
        try
            [audioData, fs, ] = lectura_audio(archivo);
        catch ME
            uialert(fig,sprintf('Error al leer el archivo: %s', ME.message),'Error');
            return;
        end

        data.x = audioData;
        data.fs = fs;
        data.x_proc = [];
        data.fs_proc = [];
        data.x_eq = [];

        % Actualizar las etiquetas dee informacion
        lblNombre.Text = sprintf('Nombre: %s', archivo);
        lblDuracion.Text = sprintf('Duración: %.2f segundos', length(audioData)/fs);
        lblFs.Text = sprintf('Frecuencia de muestreo: %.2f Hz', fs);

        % Marcamos checkbox y activar botón reproducir y procesar
        chkCargado.Value = true;
        btnReproducir.Enable = 'on';
        btnProcesar.Enable = 'on';

        % Mostramos señal y espectro original
        plotSignalAndSpectrum(ax1, ax2, data.x, data.fs);
    end

    %% Función reproducir audio cargado
    function reproducirAudio()
        if isempty(data.x)
            uialert(fig,'Primero cargue un archivo.','Error');
            return;
        end
        sound(data.x, data.fs);
    end


    %% Función procesar audio 
    function procesarAudio()
        if isempty(data.x)
            uialert(fig,'Primero cargue un archivo.','Error');
            return;
        end

        tipo = lower(ddOpc.Value);
        if strcmp(tipo,'decimación')
            tipo_proc = 'decimacion';
        else
            tipo_proc = 'expansion';
        end

        factor = edtFactor.Value;
        if isempty(factor) || factor < 1 || mod(factor,1)~=0
            uialert(fig,'Ingrese un factor entero positivo válido.','Error');
            return;
        end
        
        % llamamos a la funcion conversion de muestreo
        [x_proc, fs_proc] = conversion_muestreo(data.x, data.fs, tipo_proc, factor);
        data.x_proc = x_proc;
        data.fs_proc = fs_proc;

        % Mostrar en interfaz gráfica el resultado de muestreo
        lblFsConvertida.Text = sprintf('Frecuencia de muestreo después de %s: %.2f Hz', tipo_proc, fs_proc);


        % Obtener ganancias de los sliders
        G_dB = zeros(1,6);
        for i = 1:6
            G_dB(i) = sliders(i).Value;
        end

        % Llamamos a la funcion ecualizador pasando las ganancias
        data.x_eq = ecualizador(data.x, data.x_proc, data.fs_proc, tipo(1), G_dB);

        % Reproducimos los audios procesados y ecualizados
        sound(data.x_proc, data.fs_proc);
        pause(length(data.x_proc)/data.fs_proc + 0.5);
        sound(data.x_eq, data.fs_proc);

        % Actualizamos la info en interfaz (solo mensaje general)
        lblInfo.Text = sprintf('%s aplicado. Nueva Fs = %.2f Hz', ddOpc.Value, fs_proc);
        
        % Graficamos el procesado y ecualizado en una nueva figura
        plotSignalsComparison();

        % Actualizamos los gráficos en los paneles
        plotSignalAndSpectrum(ax1, ax2, data.x_eq, data.fs_proc);
    end
    
    %% Funcion para graficar
    function plotSignalAndSpectrum(axSignal, axSpec, signal, fs)
        % Señal
        t = (0:length(signal)-1)/fs;
        plot(axSignal, t, signal);
        axSignal.Title.String = 'Señal';
        axSignal.XLabel.String = 'Tiempo [s]';
        axSignal.YLabel.String = 'Amplitud';
        grid(axSignal,'on');

        % Espectro
        nfft = 2^nextpow2(length(signal));
        f = linspace(-fs/2, fs/2, nfft);
        Y = abs(fftshift(fft(signal, nfft)));
        Y = Y / max(Y);
        plot(axSpec, f, Y);
        axSpec.Title.String = 'Espectro';
        axSpec.XLabel.String = 'Frecuencia [Hz]';
        axSpec.YLabel.String = 'Magnitud Normalizada';
        grid(axSpec,'on');
    end
    
    %% Funcino para graficar
    function plotSignalsComparison()
        figure('Name','Comparación de Señales','NumberTitle','off','Position',[100 100 700 600]);
        %Original
        subplot(3,1,1);
        plot((0:length(data.x)-1)/data.fs, data.x);
        title('Original');
        xlabel('Tiempo [s]');
        ylabel('Amplitud');
        grid on;
        %Procesada
        subplot(3,1,2);
        plot((0:length(data.x_proc)-1)/data.fs_proc, data.x_proc);
        title('Procesada');
        xlabel('Tiempo [s]');
        ylabel('Amplitud');
        grid on;

        %Ecualizada
        subplot(3,1,3);
        plot((0:length(data.x_eq)-1)/data.fs_proc, data.x_eq);
        title('Ecualizada');
        xlabel('Tiempo [s]');
        ylabel('Amplitud');
        grid on;
    end
end
