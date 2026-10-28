# Neoduction_iOSAudio_Test

An iOS audio R&D sandbox from the NEODUCTION era (2014): an Xcode experiment app (`sample/AudioSample`) written in Objective-C/Objective-C++ that exercises **Core Audio** — `AVAudioSession` configuration (sample rate 22050, 2.5 ms hardware buffers, playback vs. play&record categories, Bluetooth input), low-latency **RemoteIO** audio-unit rendering callbacks and playback of a bundled WAV file, with step-by-step Spanish comments documenting each call.

The `docs/` folder gathers the reference material used for learning:

- `aurioTouch/` — Apple's official sample demonstrating the Remote I/O audio unit (oscilloscope/FFT/sonogram views). © Apple Inc.
- `CoreAudioOverview.pdf` — Apple's Core Audio overview document. © Apple Inc.
- `Using RemoteIO audio unit.html` — locally saved copy of Michael Tyson's classic tutorial *"Using the RemoteIO audio unit"* (A Tasty Pixel blog). © Michael Tyson.

The `neoduction.zip` archive contains a snapshot of the original project folder and is attached as a GitHub Release asset.

> **This project is shared ONLY for educational purposes. Its use, direct or derived, for professional or economic purposes is not permitted.**

For security reasons, some parts of the project may have been edited or removed (local IDE state, macOS metadata forks). Third-party reference material remains credited to its original authors.

## Requirements / How to run

- **macOS + Xcode** (Swift 4.x–5 / iOS SDK era of Xcode 5–6; 32/64-bit iOS) to open `sample/AudioSample/AudioSample.xcodeproj`.
- The demo app plays `ejemplo.wav` through the RemoteIO unit; experiments with microphone input are commented in the code (`AVAudioSessionCategoryPlayAndRecord`).
- `aurioTouch` builds with its own Xcode project inside `docs/`.

## DISCLAIMER

This software is provided without any warranty of any kind, and no liability is accepted for errors or damages resulting from its use.

> **AI training**: the use of the content of this repository (code, assets, documentation) to train or fine-tune machine learning models or AI systems is expressly **not permitted**. All of the repository is licensed under CC-BY-NC-4.0 (see the `LICENSE` file).

---

# Neoduction_iOSAudio_Test

Sandbox de investigación de audio en iOS de la etapa NEODUCTION (2014): app experimental de Xcode (`sample/AudioSample`) escrita en Objective-C/Objective-C++ que ejercita **Core Audio** — configuración de `AVAudioSession` (sample rate 22050, buffers de hardware de 2,5 ms, categorías playback vs. play&record, entrada Bluetooth), callbacks de render del audio unit **RemoteIO** a baja latencia y reproducción de un WAV incluido, con comentarios en español paso a paso documentando cada llamada.

La carpeta `docs/` recoge el material de referencia usado para el estudio:

- `aurioTouch/` — sample oficial de Apple que demuestra el Remote I/O audio unit (vistas de osciloscopio/FFT/sonograma). © Apple Inc.
- `CoreAudioOverview.pdf` — documento de introducción a Core Audio de Apple. © Apple Inc.
- `Using RemoteIO audio unit.html` — copia local del tutorial clásico de Michael Tyson *"Using the RemoteIO audio unit"* (blog A Tasty Pixel). © Michael Tyson.

El archivo `neoduction.zip` contiene una instantánea de la carpeta original del proyecto y se adjunta como recurso del Release de GitHub.

> **Este proyecto se comparte SOLO con valor educativo. No está permitido su uso (directo o derivado) para fines profesionales o económicos.**

Por motivos de seguridad, es posible que algunas partes del proyecto se encuentren editadas o eliminadas (estado local del IDE, metadatos macOS). El material de referencia de terceros mantiene el crédito a sus autores originales.

## Requisitos / Cómo ejecutar

- **macOS + Xcode** (era Xcode 5–6, SDK iOS) para abrir `sample/AudioSample/AudioSample.xcodeproj`.
- La app demo reproduce `ejemplo.wav` a través del RemoteIO; las pruebas con micrófono están comentadas en el código (`AVAudioSessionCategoryPlayAndRecord`).
- `aurioTouch` se compila con su propio proyecto Xcode dentro de `docs/`.

## AVISO

No se presta ningún tipo de garantía ni se acepta responsabilidad alguna por su uso, ante posibles errores o daños que puedan producirse.

> **Entrenamiento de IA**: no se permite expresamente el uso del contenido de este repositorio (código, recursos, documentación) para entrenar o ajustar (*fine-tune*) modelos de aprendizaje automático o sistemas de IA. Todo el repositorio se publica con licencia CC-BY-NC-4.0 (ver el archivo `LICENSE`).
