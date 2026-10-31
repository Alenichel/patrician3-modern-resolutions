# Patrician III ultrawide 3440x1440

Patch locale per Patrician III inglese Steam (app 33570), Windows, PowerShell 5.1.
Modifica lo slot **1280x1024**, che mantiene quel nome nelle opzioni.
Il menu principale conserva le dimensioni originali; la risoluzione cambia in partita.

## Stato

La partita a 3440x1440 funziona, confermata dall'utente il 31 ottobre 2026.
Le 12 costanti della risoluzione sono state applicate e rilette in memoria.
Correzione della mappa del mare: il fondale originale e largo 2400 pixel,
meno del viewport ultrawide di 3156. La tela viene estesa a 3440 pixel
con una zona neutra a destra. I 4.320.000 pixel della geografia originale
restano nelle stesse coordinate, con la stessa palette; non si allarga
il territorio navigabile. L'utente ha confermato che la ripetizione e risolta.

La camera orizzontale del mare viene centrata a **-378** quando il viewport
e largo 3156: la mappa di 2400 pixel lascia 378 pixel per lato.
Il fondale, le citta, le navi e le coordinate del mouse usano lo stesso
offset. Sono corretti entrambi i limiti: posizionamento della camera e
aggiornamento dello scorrimento, che altrimenti reimpostava X a zero.
Il limite originale resta attivo per le altre larghezze.
Il centraggio aggiornato e il pannello laterale sono stati verificati nel
gioco e confermati funzionanti dall'utente il 31 ottobre 2026.

Il pannello laterale inferiore viene esteso a 284x840 senza allungare
il bassorilievo della nave: illustrazione e cornici mantengono i pixel
originali; lo spazio aggiunto usa il legno e i bordi dell'asset originale.

## Installazione e avvio

**Avvio dalla repository:** doppio clic su **`Avvia-Mod.cmd`**, a gioco chiuso.
Installa/aggiorna gli script e rigenera le risorse dalla copia locale, poi
avvia Steam e la patch. Confermare la richiesta UAC di PowerShell.

Non contiene un `.exe` universale: il launcher e un file `.cmd` che usa
PowerShell e l'installazione Steam originale. Funziona con la versione
verificata e il monitor 3440x1440; versioni o risoluzioni diverse richiedono
una verifica. La repository non include l'eseguibile proprietario del gioco.

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
- Ricerca di nove firme univoche, verifica prima di scrivere, rilettura dopo la scrittura.
- Cinque coppie larghezza/altezza e due confronti della larghezza.
- Due piccoli hook dei limiti della camera e dello scorrimento mare; applicano il centraggio
  solo al viewport 3156 e mantiene il limite originale negli altri casi.
- BMP indicizzati 8 bit, palette originale, ridimensionamento nearest neighbour.
- Versione verificata: SHA256 di entrambi gli EXE originali
  `21ACA7AE64AB3B8C8D55C9C4E547E311EE4EDE4E9E62BB6E8B7FD8DE180EA60A`.
- Risoluzione per ora fissata a 3440x1440. Le firme diverse causano l'arresto della patch.

## Fonti

- [Guida di Raydell e lavoro originale di brotkohl et al.](https://steamcommunity.com/sharedfiles/filedetails/?id=382413909)
- [Annotazioni delle modifiche binarie di dsedivec](https://github.com/dsedivec/P3WideScreen/blob/master/binary-changes.txt)
- [Formato CPR, Patrician 3 Insights](https://p3modding.github.io/file-formats/cpr.html)

Script creati con assistenza di Codex. Repository locale, non pubblicata.

## Verifica risorse

Con Python 3, dopo l'installazione:

```powershell
python tests/check_seamap.py 'C:\Program Files (x86)\Steam\steamapps\common\Patrician III' 'C:\Program Files (x86)\Steam\steamapps\common\Patrician III\mods-ultrawide\prepared'
```

Il test verifica i pixel geografici originali, la palette, lo spazio aggiunto
e la corrispondenza tra immagine e rettangolo della texture.

Il test del codice macchina della camera richiede `pip install unicorn`:

```powershell
python tests/check_camera.py
```

Esegue il generatore di byte usato dal launcher e prova il codice x86 in
40 casi: camera ultrawide a -378 anche dopo lo scorrimento, limite originale
alle altre larghezze, camera verticale invariata. Questo test passa;
il centraggio e stato anche confermato visivamente nel gioco dall'utente.

`tests/check_panel.py` accetta gli stessi due percorsi di `check_seamap.py`:
verifica che nave, cornici superiore/inferiore e palette del pannello
mantengano i pixel originali, senza stiramento.
