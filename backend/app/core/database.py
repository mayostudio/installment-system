import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# دعم الـ UUID
try:
    import psycopg2.extras
    psycopg2.extras.register_uuid()
except Exception:
    pass

# الاتصال الدقيق بحاوية الدوكر الحالية
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://admin:adminpassword@localhost:5433/installment_system"
)

engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()