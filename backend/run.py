import os
import sys

# ضمان مسار المشروع
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import uvicorn

if __name__ == "__main__":
    # قراءة المنفذ الذي يفرضه ريلواي بدقة
    port = int(os.environ.get("PORT", 8000))
    print(f"Starting server on 0.0.0.0:{port}")
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, proxy_headers=True, forwarded_allow_ips="*")
