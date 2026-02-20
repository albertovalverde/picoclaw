# PicoClaw Local Quickstart (Sin Docker / Sin Emulador)

Este documento describe la ejecucion manual de PicoClaw directamente desde este repositorio usando Groq.

## Alcance

- Sin Docker
- Sin QEMU/emulacion
- Ejecucion nativa en tu sistema (Linux amd64)

## Requisitos

- Go instalado (`go version`)
- API key de Groq (`gsk_...`)

## 1) Crear config real de PicoClaw

PicoClaw usa `~/.picoclaw/config.json` (no usa directamente `config/config.example.json`).

```bash
mkdir -p ~/.picoclaw
cp config/config.example.json ~/.picoclaw/config.json
```

Verifica que el default sea `groq-gpt-oss-120b` y que exista:

```json
{
  "agents": {
    "defaults": {
      "model": "groq-gpt-oss-120b"
    }
  },
  "model_list": [
    {
      "model_name": "groq-gpt-oss-120b",
      "model": "groq/openai/gpt-oss-120b",
      "api_key": "gsk_tu_api_key",
      "api_base": "https://api.groq.com/openai/v1"
    }
  ]
}
```

## 2) Compilar binario local

```bash
make build
```

Binario esperado:

```text
build/picoclaw-linux-amd64
```

## 3) Ejecutar manualmente

Modo one-shot:

```bash
./build/picoclaw-linux-amd64 agent -m "hola"
```

Modo interactivo:

```bash
./build/picoclaw-linux-amd64 agent
```

Ver version:

```bash
./build/picoclaw-linux-amd64 version
```

## Troubleshooting rapido

Error: `./build/picoclaw-linux-amd64: No existe el archivo o el directorio`

```bash
make build
ls -la build
```

Error de autenticacion o endpoint de Groq

```bash
curl https://api.groq.com/openai/v1/models \
  -H "Authorization: Bearer gsk_tu_api_key"
```
