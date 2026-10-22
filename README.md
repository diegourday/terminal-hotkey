# Terminal Hotkey

Miniapp para Windows: **Alt+Q** trae al frente Windows Terminal y restaura la ventana si esta minimizada. Recuerda la ultima ventana usada por el atajo; si se cierra, busca otra existente. Si no hay ninguna, abre el perfil Ubuntu en `/home/diegourday`. Conserva el aspecto del perfil existente.

Sin ventana principal ni icono junto al reloj. Un unico proceso en segundo plano escucha el atajo. Inicia con Windows mediante un acceso directo en la carpeta Inicio. Si Alt+Q ya esta ocupado, informa del conflicto. Para detenerla temporalmente, finaliza TerminalHotkey desde el Administrador de tareas; para volver a activarla, ejecuta `%LOCALAPPDATA%\TerminalHotkey\TerminalHotkey.exe`.

## Requisitos

Windows 10/11, Windows Terminal, WSL Ubuntu y .NET Framework 4.x (incluido en Windows). Para desarrollar: WSL, Node.js y pnpm. No requiere base de datos, servidor ni paquetes externos.

## Compilar e instalar desde WSL

```sh
cd /home/diegourday/code/terminal-hotkey
pnpm install
pnpm run build
pnpm run app:install
```

El codigo se mantiene en WSL. Se usa el compilador de .NET Framework de Windows y se instala el ejecutable en `%LOCALAPPDATA%\TerminalHotkey`. No necesita administrador.

La compilacion genera `dist/TerminalHotkey.exe`. Esta carpeta se excluye de Git; el repositorio contiene el codigo fuente y los scripts para reconstruir e instalar la app.

## Configuracion

El atajo Alt+Q, el perfil Ubuntu y la carpeta inicial `/home/diegourday` se definen en `src/Program.cs`. Para cambiarlos, edita ese archivo, vuelve a compilar y ejecuta `pnpm run app:install` para actualizar la instalacion.

## Verificacion

`pnpm run verify` simula Alt+Q y comprueba que reutiliza una terminal existente sin crear ventanas, que la trae al frente, que restaura una terminal minimizada, que solo hay una instancia de la app y que el acceso de Inicio apunta al ejecutable instalado. Si no hay ninguna terminal abierta, tambien verifica la apertura de Ubuntu. Requiere una instalacion activa. Deja la terminal al frente.

## Desinstalar la app

```sh
pnpm run app:uninstall
```

Elimina el ejecutable y el acceso de Inicio. El estado de diagnostico permanece en `%LOCALAPPDATA%\TerminalHotkey\status.txt`.

## Implementacion

C# con Windows Forms y RegisterHotKey. No captura ni registra texto escrito. El atajo no se repite al mantenerlo pulsado. Windows Terminal se lanza con `wt.exe -w new -p Ubuntu -d "\\wsl$\Ubuntu\home\diegourday"`.

Referencias: [RegisterHotKey](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey), [Windows Terminal CLI](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments).
