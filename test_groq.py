#!/usr/bin/env python3
import json
import os
import sys
import urllib.request
import urllib.error

API_KEY = os.getenv("GROQ_API_KEY", "").strip()
MODEL = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b")
API_BASE = os.getenv("GROQ_API_BASE", "https://api.groq.com/openai/v1").rstrip("/")

if not API_KEY:
    print("Falta GROQ_API_KEY")
    print('Uso: GROQ_API_KEY="gsk_..." python3 test_groq.py')
    sys.exit(1)

def call(method, url, payload=None):
    data = None
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
        "User-Agent": "curl/8.5.0",
        "Accept": "application/json",
    }
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            body = r.read().decode("utf-8", errors="replace")
            return r.status, body
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        return e.code, body
    except Exception as e:
        return 0, str(e)

# 1) Probar key listando modelos
list_url = f"{API_BASE}/models"
status, body = call("GET", list_url)
print(f"[LIST MODELS] HTTP {status}")
print(body[:800], "\n")

# 2) Probar chat completion simple
chat_url = f"{API_BASE}/chat/completions"
payload = {
    "model": MODEL,
    "messages": [
        {
            "role": "user",
            "content": "Please reply with exactly: OK",
        }
    ],
    "temperature": 0,
}
status, body = call("POST", chat_url, payload)
print(f"[CHAT COMPLETIONS] HTTP {status}")
print(body[:1200])

if status == 200:
    print("\nKey valida y modelo accesible en Groq.")
else:
    print("\nFallo. Si ves 401/invalid_api_key, la key no es valida.")
