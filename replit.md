# AIGateway

Proxy LiteLLM davanti a tutte le chiamate AI di Casello (repo
TwentIvan/Casello-Agent-Hub), con prompt caching sui context pack degli
agenti.

## Run & Operate

- `pip install -r requirements.txt` — installa LiteLLM (`litellm[proxy]`)
- `litellm --config config.yaml --host 0.0.0.0 --port $PORT` — avvia il proxy
- Secrets richiesti: `LITELLM_MASTER_KEY`, `OPENAI_API_KEY`,
  `ANTHROPIC_API_KEY`, `DATABASE_URL`

## Where things live

- `config.yaml` — model_list, routing e settings LiteLLM (unica fonte di
  verità per i modelli esposti)
- `README.md` — procedura completa di setup, virtual key, smoke test e
  ripuntamento di Casello

## Gotchas

- Deploy come **Reserved VM**, mai Autoscale: niente cold start, stato
  persistente.
- `config.yaml` deve restare sincronizzato con i `model` usati dagli agenti
  in Casello.

## User preferences

- Lingua: italiano per documentazione e commenti
