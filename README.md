# Patrician III Ultrawide

![Patrician III Ultrawide: un porto anseatico illustrato, una nave mercantile e il titolo della mod a 3440 × 1440](assets/readme-cover.png)

**Il commercio anseatico, sul tuo schermo ultrawide.**

Una mod per giocare a **Patrician III a 3440 × 1440**, con una mappa del mare
centrata e una barra laterale dalle proporzioni corrette. Questa repository
contiene la patch, il launcher Windows e gli strumenti per creare un pacchetto
pronto da condividere con chi possiede il gioco.

> **Compatibilità:** Windows 10/11 · Patrician III inglese Steam · monitor principale 3440 × 1440.

## Cosa cambia

| Funzione | Risultato |
| --- | --- |
| Risoluzione ultrawide | La vista di gioco usa 3440 × 1440. |
| Mappa del mare | Nessuna ripetizione dello sfondo; mappa centrata anche durante lo scorrimento. |
| Barra laterale | Cornici e illustrazione conservano le proporzioni originali. |
| Launcher dedicato | Trova il gioco nelle librerie Steam e prepara la mod automaticamente. |
| Backup e ripristino | Conserva gli originali e permette di tornare alla versione standard. |

La mappa mantiene la scala originale, con spazio neutro ai lati: il territorio
non viene deformato. Il menu principale conserva le dimensioni originali.
Risoluzione, centraggio e barra laterale sono stati verificati in partita.

## Inizia a giocare

### Se hai ricevuto il pacchetto ZIP

1. Estrai **Patrician3-Ultrawide-1.0.0.zip** in una cartella a tua scelta.
2. Apri **Patrician3Ultrawide.exe**.
3. Controlla la cartella trovata automaticamente; usa **Sfoglia** se necessario.
4. A gioco chiuso, premi **Avvia mod** e conferma la richiesta UAC di Windows.
5. Attendi **Patch attiva**, poi carica una partita.

**Nelle opzioni lascia 1280 × 1024:** è il nome originale dello slot che la
patch trasforma in 3440 × 1440.

Non servono Python, compilatori o mod loader. Il launcher usa .NET Framework
e PowerShell presenti sui normali Windows 10/11.

### Se hai clonato questa repository

Apri **Avvia-Mod.cmd**: compila il launcher se manca, poi lo avvia.
Per creare lo ZIP distribuibile, esegui **Build.ps1** con PowerShell.
Gli artefatti vengono scritti in `dist/`.

**Usa il launcher a ogni sessione.** Il pulsante **Gioca** di Steam, da solo,
non applica la patch in memoria.

## Come funziona

Il launcher avvia il gioco tramite Steam e applica la correzione della
risoluzione in memoria. Le immagini e gli INI necessari vengono generati
localmente dalla copia del gioco dell'utente.

Gli eseguibili e gli archivi originali restano invariati; i salvataggi non
vengono modificati. Il pacchetto distribuito contiene il codice della mod
e la documentazione, senza risorse proprietarie estratte dal gioco.

## Tornare al gioco originale

Chiudi il gioco, riapri **Patrician3Ultrawide.exe** e premi **Ripristina originale**.

Il primo backup si trova in `mods-ultrawide/backup-originali`, nella cartella
del gioco. Non cancellarlo: contiene la configurazione e le risorse preesistenti
necessarie al ripristino. La configurazione torna allo stato del primo backup.

## Compatibilità e problemi comuni

- È supportata la **versione inglese Steam 1.1** verificata dal progetto.
- Il monitor principale deve essere già impostato a **3440 × 1440**.
- Versioni o risoluzioni diverse vengono rifiutate con un messaggio esplicito.
- Completa il primo avvio Steam e **P3Setup** prima di usare la mod.
- Chiudi il gioco prima di avviare, aggiornare o ripristinare.
- Altre mod che modificano gli stessi INI o le stesse immagini possono entrare in conflitto.
- Il launcher non è firmato digitalmente: Windows può richiedere una verifica della provenienza.

I dettagli degli errori compaiono nella finestra del launcher. Il log è in
`%LOCALAPPDATA%/Patrician3Ultrawide/last-operation.log`; quello della patch
è in `mods-ultrawide/runtime.log`, nella cartella del gioco.

## Per chi sviluppa o distribuisce la mod

- [Compilazione, struttura tecnica e test](docs/DEVELOPMENT.md)
- [Istruzioni incluse nel pacchetto](DISTRIBUZIONE.txt)
- [Controlli della release](RELEASE-CHECKS.md)
- [Changelog](CHANGELOG.md)

Distribuisci lo **ZIP prodotto dalla build** e il checksum `SHA256SUMS.txt`.
Le cartelle del gioco, `prepared` e `backup-originali` devono restare locali.

## Crediti

Basata sulla ricerca di brotkohl et al., sulla [guida di Raydell](https://steamcommunity.com/sharedfiles/filedetails/?id=382413909),
sulle [annotazioni di dsedivec](https://github.com/dsedivec/P3WideScreen/blob/master/binary-changes.txt)
e sulla [documentazione P3Modding](https://p3modding.github.io/).
Sviluppata con assistenza di OpenAI Codex.

La copertina è un'illustrazione originale generata con **ImageGen**, non uno
screenshot del gioco. [Prompt e provenienza dell'immagine](assets/GENERATION.md).
Le risorse grafiche usate in partita vengono adattate dagli originali locali.

Codice della mod sotto [licenza MIT](LICENSE). Gioco e risorse proprietarie
restano dei rispettivi titolari. Questo è un progetto della community.
