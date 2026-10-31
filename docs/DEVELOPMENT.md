# Sviluppo e distribuzione

[Torna alla presentazione](../README.md)

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
Sviluppato con assistenza di OpenAI Codex. La copertina del README e generata con ImageGen; per la grafica in gioco,
le immagini vengono adattate localmente dagli originali.

Codice originale della mod sotto licenza MIT, vedi `LICENSE`.
Gioco e risorse grafiche restano dei rispettivi titolari.
