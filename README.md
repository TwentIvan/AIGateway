# AIGateway — LiteLLM davanti a Casello

Proxy LiteLLM davanti a tutte le chiamate AI di [Casello](https://github.com/TwentIvan/Casello-Agent-Hub),
con prompt caching sui context pack degli agenti. Rollback in ogni momento
rimuovendo un solo secret nel deploy di Casello.

## 1. Setup di questo Repl

1. Secrets del Repl (pannello "Secrets", mai nel codice):
   - `LITELLM_MASTER_KEY` — genera un valore lungo e casuale (prefisso consigliato `sk-`); è la chiave admin, non va mai in Casello
   - `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` — le stesse usate oggi in Casello
   - `DATABASE_URL` — Postgres del Repl (add-on integrato di Replit, copia la connection string qui)
2. Il comando di run (`.replit`) installa le dipendenze e avvia il proxy:
   `pip install -r requirements.txt && litellm --config config.yaml --host 0.0.0.0 --port $PORT`
3. Deploy come **Reserved VM** (sempre acceso). Non usare Autoscale: il gateway
   non deve avere cold start né perdere stato. Si sceglie dalla UI Deployments
   di Replit, non da `.replit` — le opzioni cambiano spesso, verifica lì.

## 2. Virtual key (una per app, poi una per agente)

Per la settimana di misura basta una chiave per Casello:

```bash
curl -X POST https://<questo-repl>.replit.app/key/generate \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "key_alias": "casello",
    "metadata": {"app": "casello"},
    "max_budget": 100.0,
    "budget_duration": "30d"
  }'
```

Conserva la `key` restituita: è il valore di `AI_GATEWAY_API_KEY` in Casello.
La granularità per-agente (una virtual key per agente) è un'estensione
futura: per ora la telemetria per-agente viaggia nei tag (`caller`+`agentId`
in `ai-gateway.ts`).

## 3. Smoke test

```bash
curl https://<questo-repl>.replit.app/chat/completions \
  -H "Authorization: Bearer <virtual-key>" \
  -H "Content-Type: application/json" \
  -d '{"model": "openai/gpt-4o-mini", "messages": [{"role": "user", "content": "ping"}]}'
```

Ripeti con `"model": "anthropic/claude-opus-4-8"` per verificare il ramo Anthropic.

## 4. Ripuntamento Casello

Nei secrets del deploy di Casello aggiungi:

- `AI_GATEWAY_BASE_URL` = URL di questo Repl
- `AI_GATEWAY_API_KEY` = la virtual key del punto 2

Non serve toccare il codice: la modalità proxy esiste già in
`artifacts/api-server/src/lib/ai-gateway.ts` di Casello e ha priorità su
tutto. `OPENAI_API_KEY`/`ANTHROPIC_API_KEY` restano nell'app come paracadute.

**Rollback totale = cancellare `AI_GATEWAY_BASE_URL`.** Casello torna alle
chiamate dirette al deploy successivo.

## 5. Cosa misurare nella settimana

- **Spesa reale**: fonte di verità è lo spend log di LiteLLM (`GET
  /spend/logs`, o le tabelle nel Postgres di questo Repl), che prezza
  correttamente i token cachati. Casello non ha una tabella di pricing
  interna: usa LiteLLM come unica fonte per il totale.
- **Hit rate cache**: nei log di Casello (`ai-gateway.ts`) comparirà
  `cached=N`. Sui run ripetuti dello stesso agente deve salire dopo la prima
  chiamata. Vincolo Anthropic: i blocchi sotto ~1024 token non vengono
  cachati, quindi agenti con contesto scarno non beneficiano — atteso, non
  un bug.
- **Latenza**: `duration=` nei log di Casello; confronta la settimana
  prima/dopo per il costo del hop aggiuntivo.
- Criterio di uscita: se il risparmio sui run ripetitivi per agente è
  tangibile, il valore sta nel layer di contesto. Altrimenti hai comunque
  guadagnato fallback, multi-provider e virtual key.

## Note

- I `model_name` in `config.yaml` devono restare sincronizzati con il campo
  `model` che gli agenti usano in Casello (tabella `agents`): quando crei un
  agente con un nuovo model key, aggiungi la voce corrispondente qui.
- Il ramo diretto OpenAI/Anthropic in `ai-gateway.ts` di Casello resta
  intatto finché il proxy è attivo: è il paracadute del rollback.
