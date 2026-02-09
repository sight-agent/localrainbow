# SITE.md — OpenMap Isochrone (MVP)

## Obiettivo
Una web app semplice che mostra una mappa (OpenStreetMap) e, dato un punto di partenza, visualizza:
- un **gradiente di colori** che rappresenta il tempo di viaggio (piu vicino = colore “freddo”, piu lontano = colore “caldo”)
- le **isocrone** principali a **10 / 20 / 30 minuti** come livelli leggibili sopra al gradiente

E possibile scegliere la modalita di viaggio `walk | bike | drive` (auto = `drive`).

L’app e l’API vengono servite da una **VPS** sotto HTTPS (nessun secret nel frontend).

## Esperienza Utente (Frontend)
### Aspetto
- Schermata principale: **mappa a tutto schermo**.
- In un pannello compatto: controlli essenziali.
- Stile pulito e “cartografico”: mappa + gradiente + isocrone sono protagonisti.
- Presente una piccola **legenda colori** (es. 0, 10, 20, 30 min).

### Controlli
- Selettore modalità: `walk | bike | drive`.
- Bottone: “Usa la mia posizione”.

### Interazione
- **Click sulla mappa**: imposta il punto di partenza.
- Compare un **marker** sul punto di partenza (trascinabile).
- Ad ogni cambio (click/drag/controlli) l’app richiede i dati e aggiorna gradiente + isocrone.

### Visualizzazione (Map Overlay)
- **Gradiente**: aree raggiungibili colorate in modo progressivo (tempo basso -> alto).
- **Isochrone 10/20/30**: ben distinguibili (bordi/riempimenti leggeri) sopra al gradiente.

### Stato e Messaggi
- Durante la richiesta: indicatore “Caricamento…”.
- In caso di errore: toast/avviso con messaggio semplice (es. “Server non raggiungibile”).

## Comportamento
- L’app parte centrata sull’Italia.
- Mantiene **solo il risultato piu recente**: se l’utente cambia punto/modalita rapidamente, le richieste vecchie vengono ignorate/annullate.
- Prestazioni accettabili su mobile: aggiornamento dopo drag con leggero debounce.

## Componenti Software
### Frontend (statico)
- HTML/CSS/JS (o framework leggero se gia presente nel repo).
- **Leaflet** per la mappa.
- **OpenStreetMap tiles** come base map.

### Backend (VPS)
- **Valhalla** per calcolo isocrone.
- Un piccolo **adapter API** che espone un endpoint semplice per il frontend e traduce la richiesta nel formato richiesto da Valhalla.
- **Reverse proxy** (Caddy o Nginx) per:
  - HTTPS
  - servire i file statici del frontend
  - inoltrare `/v1/isochrone` all’adapter
