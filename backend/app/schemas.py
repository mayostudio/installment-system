from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import date, datetime
from uuid import UUID
from decimal import Decimal

class CustomerCreate(BaseModel):
    full_name: str
    national_id: str = Field(..., min_length=14, max_length=14)
    phone_number: str
    address: str
    monthly_income: Decimal
    credit_limit: Decimal = Decimal("0.00")

class CustomerResponse(CustomerCreate):
    id: UUID
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class ScheduleResponse(BaseModel):
    id: UUID
    installment_index: int
    due_date: date
    amount_due: Decimal
    amount_paid: Decimal
    status: str

    class Config:
        from_attributes = True

class ContractCreate(BaseModel):
    customer_id: UUID
    contract_number: str
    product_name: str = "سلعة عامة"
    total_cash_price: Decimal
    down_payment: Decimal
    interest_rate_percent: Decimal
    months_count: int
    start_date: date = Field(default_factory=date.today)

class ContractResponse(BaseModel):
    id: UUID
    contract_number: str
    customer_id: UUID
    product_name: str
    financed_amount: Decimal
    total_contract_amount: Decimal
    monthly_installment: Decimal
    months_count: int
    start_date: date
    status: str
    schedules: List[ScheduleResponse] = []

    class Config:
        from_attributes = True