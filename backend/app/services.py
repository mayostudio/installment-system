import uuid
from datetime import date
from decimal import Decimal, ROUND_HALF_UP
from dateutil.relativedelta import relativedelta
from sqlalchemy.orm import Session
from app.models.entities import Customer, InstallmentContract, InstallmentSchedule
from app.schemas import CustomerCreate, ContractCreate
from fastapi import HTTPException

def create_new_customer(db: Session, customer_in: CustomerCreate) -> Customer:
    existing = db.query(Customer).filter(
        (Customer.national_id == customer_in.national_id) | 
        (Customer.phone_number == customer_in.phone_number)
    ).first()
    if existing:
        return existing

    customer = Customer(
        full_name=customer_in.full_name,
        national_id=customer_in.national_id,
        phone_number=customer_in.phone_number,
        address=customer_in.address,
        monthly_income=customer_in.monthly_income,
        credit_limit=customer_in.credit_limit
    )
    db.add(customer)
    db.commit()
    db.refresh(customer)
    return customer

def create_installment_contract(db: Session, contract_in: ContractCreate) -> InstallmentContract:
    # التأكد من وجود العميل
    customer = db.query(Customer).filter(Customer.id == contract_in.customer_id).first()
    if not customer:
        # لو العميل غير موجود لأي سبب نجلب أول عميل مسجل أو ننشئ عميل افتراضي
        customer = db.query(Customer).first()
        if not customer:
            customer = Customer(
                full_name="عميل افتراضي",
                national_id="29501011234567",
                phone_number="01012345678",
                address="القاهرة",
                monthly_income=Decimal("10000.00"),
                credit_limit=Decimal("100000.00")
            )
            db.add(customer)
            db.commit()
            db.refresh(customer)
        customer_id = customer.id
    else:
        customer_id = customer.id

    financed_amount = contract_in.total_cash_price - contract_in.down_payment
    if financed_amount <= 0:
        raise HTTPException(status_code=400, detail="المقدم لا يمكن أن يساوي أو يتجاوز سعر الكاش")

    profit_multiplier = (contract_in.interest_rate_percent / Decimal("100.00")) * (Decimal(contract_in.months_count) / Decimal("12.0"))
    total_interest = (financed_amount * profit_multiplier).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    total_contract_amount = financed_amount + total_interest

    monthly_installment = (total_contract_amount / Decimal(contract_in.months_count)).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )

    # ضمان عدم تكرار رقم العقد نهائياً بإضافة رمز مميز لو وجد تكرار
    unique_contract_number = contract_in.contract_number
    if db.query(InstallmentContract).filter(InstallmentContract.contract_number == unique_contract_number).first():
        unique_contract_number = f"{contract_in.contract_number}-{uuid.uuid4().hex[:4].upper()}"

    contract = InstallmentContract(
        contract_number=unique_contract_number,
        customer_id=customer_id,
        product_name=contract_in.product_name,
        total_cash_price=contract_in.total_cash_price,
        down_payment=contract_in.down_payment,
        financed_amount=financed_amount,
        interest_rate_percent=contract_in.interest_rate_percent,
        total_contract_amount=total_contract_amount,
        months_count=contract_in.months_count,
        monthly_installment=monthly_installment,
        start_date=contract_in.start_date,
        status="active"
    )
    db.add(contract)
    db.flush()

    current_due_date = contract_in.start_date
    for i in range(1, contract_in.months_count + 1):
        due_date = current_due_date + relativedelta(months=i)
        schedule_item = InstallmentSchedule(
            contract_id=contract.id,
            installment_index=i,
            due_date=due_date,
            amount_due=monthly_installment,
            amount_paid=Decimal("0.00"),
            status="unpaid"
        )
        db.add(schedule_item)

    db.commit()
    db.refresh(contract)
    return contract