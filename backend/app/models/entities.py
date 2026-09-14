import uuid
from datetime import datetime, date
from decimal import Decimal
from sqlalchemy import Column, String, Numeric, Integer, Date, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base

class Customer(Base):
    __tablename__ = "customers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name = Column(String(255), nullable=False)
    national_id = Column(String(14), unique=True, nullable=False, index=True)
    phone_number = Column(String(20), unique=True, nullable=False)
    address = Column(String(500), nullable=True)
    monthly_income = Column(Numeric(12, 2), nullable=False, default=Decimal("0.00"))
    credit_limit = Column(Numeric(12, 2), nullable=False, default=Decimal("0.00"))
    status = Column(String(20), default="active")
    created_at = Column(DateTime, default=datetime.utcnow)

    contracts = relationship("InstallmentContract", back_populates="customer")

class InstallmentContract(Base):
    __tablename__ = "installment_contracts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    contract_number = Column(String(50), unique=True, nullable=False, index=True)
    customer_id = Column(UUID(as_uuid=True), ForeignKey("customers.id"), nullable=False)
    product_name = Column(String(255), nullable=False, default="سلعة عامة")
    total_cash_price = Column(Numeric(12, 2), nullable=False)
    down_payment = Column(Numeric(12, 2), nullable=False)
    financed_amount = Column(Numeric(12, 2), nullable=False)
    interest_rate_percent = Column(Numeric(5, 2), nullable=False)
    total_contract_amount = Column(Numeric(12, 2), nullable=False)
    months_count = Column(Integer, nullable=False)
    monthly_installment = Column(Numeric(12, 2), nullable=False)
    start_date = Column(Date, nullable=False, default=date.today)
    status = Column(String(20), default="active")
    created_at = Column(DateTime, default=datetime.utcnow)

    customer = relationship("Customer", back_populates="contracts")
    schedules = relationship("InstallmentSchedule", back_populates="contract", cascade="all, delete-orphan")

class InstallmentSchedule(Base):
    __tablename__ = "installment_schedules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    contract_id = Column(UUID(as_uuid=True), ForeignKey("installment_contracts.id"), nullable=False)
    installment_index = Column(Integer, nullable=False)
    due_date = Column(Date, nullable=False)
    amount_due = Column(Numeric(12, 2), nullable=False)
    amount_paid = Column(Numeric(12, 2), default=Decimal("0.00"))
    status = Column(String(20), default="unpaid")
    paid_at = Column(DateTime, nullable=True)

    contract = relationship("InstallmentContract", back_populates="schedules")