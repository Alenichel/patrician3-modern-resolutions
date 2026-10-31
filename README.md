# Patrician III Ultrawide

Mod per **Patrician III inglese Steam**, Windows 10/11, monitor principale **3440x1440**.
Include la risoluzione ultrawide, mappa del mare senza ripetizioni e centrata
anche durante lo scorrimento, e pannello laterale con proporzioni corrette.
Queste modifiche sono state confermate nel gioco dall'utente.

## Per giocare

1. Estrai `Patrician3-Ultrawide-1.0.0.zip` in una cartella a tua scelta.
2. Apri **Patrician3Ultrawide.exe**.
3. Il launcher trova il gioco nelle librerie Steam; se necessario scegli la cartella con **Sfoglia**.
4. A gioco chiuso, premi **Avvia mod** e conferma UAC.
5. Attendi **Patch attiva**, poi carica una partita.

Non servono Python, compilatori o mod loader. Il launcher usa .NET Framework
e PowerShell gia presenti sui normali Windows 10/11. Il menu principale
rimane alla dimensione originale. L'opzione grafica da lasciare selezionata
e **1280x1024**, il nome originale dello slot modificato.

Usa il launcher a ogni sessione: il normale pulsante **Gioca** di Steam non
applica la patch in memoria. Il launcher non modifica la risoluzione di Windows:
se il monitor principale non e a 3440x1440, si ferma con una spiegazione.
Non sono dichiarate compatibili altre lingue, altre versioni o altri monitor.
Il controllo SHA256 rifiuta gli eseguibili non riconosciuti prima di modificare i file.

## Ripristino

Chiudi il gioco, apri lo stesso EXE e premi **Ripristina originale**.
Il backup iniziale di config e delle sole risorse modificate resta in
`mods-ultrawide/backup-originali` nella cartella del gioco e non viene
sovrascritto dagli aggiornamenti. Non cancellarlo. Il ripristino riporta
anche le preferenze di `P2.cfg` allo stato del primo backup.

I salvataggi non vengono modificati. Archivi ed eseguibili originali non
vengono modificati. Le risorse disattivate sono conservate in `disabled-*`.
Mod che toccano gli stessi INI o le stesse immagini possono entrare in conflitto.

## Problemi e log

- Completa il primo avvio di Steam e il configuratore P3Setup prima di usare la mod.
- Chiudi il gioco prima di avviare, aggiornare o ripristinare.
- Controlla la versione inglese Steam e il monitor principale a 3440x1440.
- Leggi i dettagli nella finestra o in `%LOCALAPPDATA%/Patrician3Ultrawide/last-operation.log`.
- Il log della patch e in `mods-ultrawide/runtime.log` nella cartella del gioco.
- L'EXE non e firmato digitalmente: Windows puo richiedere una verifica della provenienza.

## Sviluppo e distribuzione

Il codice sorgente non contiene file del gioco. Il launcher incorpora gli script
e genera le immagini e gli INI dalla copia locale dell'utente. Nessun download
e nessuna sostituzione dell'eseguibile proprietario sono necessari.

Per compilare con il compilatore .NET Framework incluso in Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build.ps1
```

Oppure apri `Avvia-Mod.cmd` nella repository: compila se serve e apre il launcher.
La build produce in `dist/` l'EXE, lo ZIP, le istruzioni, la licenza, il changelog
e `SHA256SUMS.txt`. Distribuisci lo ZIP e il suo checksum, **non la cartella del
gioco e non le cartelle `prepared` o `backup-originali`**. Nessuna pubblicazione
online e automatica.

Per usare gli script direttamente:

```powershell
$game = 'D:\SteamLibrary\steamapps\common\Patrician III'
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-Mod.ps1 -GamePath $game
powershell -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -GamePath $game
```

La versione supportata ha questo SHA256 di `Patrician3.exe`:
`21aca7ae64ab3b8c8d55c9c4e547e311ee4ede4e9e62bb6e8b7fd8de180ea60a`.
La patch verifica nove firme univoche e rilegge ogni scrittura in memoria.
L'offset della camera e -378 per il viewport largo 3156; i due limiti del
motore mantengono il comportamento originale alle altre larghezze.

## Verifiche

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/check_install_restore.ps1 -GamePath $game
python tests/check_camera.py
python tests/check_seamap.py $game "$game\mods-ultrawide\prepared"
python tests/check_panel.py $game "$game\mods-ultrawide\prepared"
```

Solo il test del codice x86 richiede `pip install unicorn`; gli utenti della
release non ne hanno bisogno. I test verificano i due hook in 40 casi, i pixel
della mappa e del pannello, backup ripetuti, ripristino, conservazione di
salvataggi e file estranei e rifiuto di versioni diverse. La build verifica
che tutte le risorse incorporate siano presenti.

## Crediti e licenza

Ricerca originale di brotkohl et al., [guida di Raydell](https://steamcommunity.com/sharedfiles/filedetails/?id=382413909),
[annotazioni di dsedivec](https://github.com/dsedivec/P3WideScreen/blob/master/binary-changes.txt)
e [documentazione P3Modding](https://p3modding.github.io/).
Sviluppato con assistenza di OpenAI Codex. Nessuna nuova grafica generata con IA:
le immagini vengono adattate localmente dagli originali.

Codice originale della mod sotto licenza MIT, vedi `LICENSE`.
Gioco e risorse grafiche restano dei rispettivi titolari.
