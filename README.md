# ManteniPro

Aplicación web Flask para equipos, órdenes de trabajo y dashboard.

## Ejecución local

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
flask --app app init-db
flask --app app run
```

Usuario inicial local: `admin`  
Contraseña inicial local: `Admin123!`

## Render

El repositorio incluye `render.yaml`, `Procfile` y `requirements.txt`.

1. Sube esta carpeta a GitHub.
2. En Render selecciona **New > Blueprint**.
3. Conecta el repositorio.
4. Render creará el servicio web y PostgreSQL.
5. Revisa en Render la variable `ADMIN_PASSWORD`, generada durante el despliegue.

También puedes crear un Web Service manualmente:

- Build: `pip install -r requirements.txt`
- Start: `gunicorn app:app`

## Seguridad

Cambia las credenciales iniciales y nunca publiques claves reales en GitHub.
