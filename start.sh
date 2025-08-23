#!/bin/bash
cd /root/CrmServer/crm_project
source .venv/bin/activate
exec uvicorn backend.app.main:app --host 0.0.0.0 --port 8001
