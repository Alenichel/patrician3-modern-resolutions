# Patrician III ultrawide 3440x1440

Patch locale per Patrician III inglese Steam (app 33570), Windows, PowerShell 5.1.
Modifica lo slot **1280x1024**, che mantiene quel nome nelle opzioni.
Il menu principale conserva le dimensioni originali; la risoluzione cambia in partita.

## Stato

La partita a 3440x1440 funziona, confermata dall'utente il 31 ottobre 2026.
Le 12 costanti della risoluzione sono state applicate e rilette in memoria.
**Problema aperto:** la mappa del mondo appare ripetuta; da correggere.

## Installazione e avvio

Da PowerShell nella repository, a gioco chiuso:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -GamePath 'C:\Program Files (x86)\Steam\steamapps\common\Patrician III'
```

Poi aprire `Avvia Patrician Ultrawide.cmd` dalla cartella del gioco e confermare UAC.
Attendere il messaggio `Patch 3440x1440 applicata` prima di iniziare o caricare una partita.
Usare **1280x1024** nelle opzioni. Usare questo launcher a ogni sessione.
Il gioco su questa macchina gira come amministratore: il launcher richiede gli stessi privilegi.

L'installer genera le immagini e gli INI leggendo l'archivio CPR della propria copia.
Non servono eseguibili modificati scaricati. I file del gioco non sono inclusi nella repository.
Il primo avvio conserva config e risorse preesistenti in `mods-ultrawide/backup-originali`.
Il backup non viene sovrascritto dagli aggiornamenti.

## Ripristino

A gioco chiuso:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -GamePath 'C:\Program Files (x86)\Steam\steamapps\common\Patrician III'
```

Le risorse modificate vengono spostate in una cartella `disabled-*`, gli originali ripristinati.
Gli eseguibili non sono modificati e le modifiche al codice spariscono alla chiusura.
I salvataggi non vengono modificati dal ripristino.

## Metodo e compatibilita

- Avvio normale da Steam; nessuna modifica ai controlli di proprieta.
- Ricerca di sette firme univoche, verifica prima di scrivere, rilettura dopo la scrittura.
- Cinque coppie larghezza/altezza e due confronti della larghezza.
- BMP indicizzati 8 bit, palette originale, ridimensionamento nearest neighbour.
- Versione verificata: SHA256 di entrambi gli EXE originali
  `21ACA7AE64AB3B8C8D55C9C4E547E311EE4EDE4E9E62BB6E8B7FD8DE180EA60A`.
- Risoluzione per ora fissata a 3440x1440. Le firme diverse causano l'arresto della patch.

## Fonti

- [Guida di Raydell e lavoro originale di brotkohl et al.](https://steamcommunity.com/sharedfiles/filedetails/?id=382413909)
- [Annotazioni delle modifiche binarie di dsedivec](https://github.com/dsedivec/P3WideScreen/blob/master/binary-changes.txt)
- [Formato CPR, Patrician 3 Insights](https://p3modding.github.io/file-formats/cpr.html)

Script creati con assistenza di Codex. Repository locale, non pubblicata.
