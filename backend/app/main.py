from datetime import date, datetime
from collections import defaultdict
from typing import List, Optional
from dateutil.relativedelta import relativedelta

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.core.database import engine, Base, get_db
from app.models.entities import Customer, InstallmentContract, InstallmentSchedule
from app.schemas import CustomerCreate, CustomerResponse, ContractCreate
from app.services import create_new_customer, create_installment_contract

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="منظومة إدارة التقسيط والحسابات",
    description="محرك العمليات المالية والجدولة الذكية للأقساط",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

class MonthlyPaymentRequest(BaseModel):
    schedule_ids: List[str]

class ContractUpdateRequest(BaseModel):
    product_name: Optional[str] = None
    total_cash_price: Optional[float] = None
    down_payment: Optional[float] = None
    interest_rate_percent: Optional[float] = None
    months_count: Optional[int] = None
    start_date: Optional[str] = None

@app.get("/", tags=["عام"])
def health_check():
    return {"status": "online", "system": "Installment Engine"}

@app.get("/dashboard/stats", tags=["لوحة التحكم"])
@app.get("/dashboard/stats/", tags=["لوحة التحكم"])
def get_dashboard_stats(db: Session = Depends(get_db)):
    today = date.today()
    this_month_key = today.strftime("%Y-%m")
    
    customers = db.query(Customer).all()
    contracts = db.query(InstallmentContract).all()
    schedules = db.query(InstallmentSchedule).all()

    total_portfolio_value = sum(float(c.total_contract_amount or 0.0) for c in contracts)
    total_collected = sum(float(s.amount_paid or 0.0) for s in schedules)
    
    unpaid_schedules = [s for s in schedules if s.status != "paid"]
    total_remaining_debt = sum(float(s.amount_due) - float(s.amount_paid or 0.0) for s in unpaid_schedules)
    
    # المتأخرات
    overdue_schedules = [s for s in unpaid_schedules if s.due_date and s.due_date < today]
    total_overdue_amount = sum(float(s.amount_due) - float(s.amount_paid or 0.0) for s in overdue_schedules)
    
    # مستهدف الشهر الحالي
    current_month_schedules = [s for s in schedules if s.due_date and s.due_date.strftime("%Y-%m") == this_month_key]
    current_month_target = sum(float(s.amount_due) for s in current_month_schedules)
    current_month_collected = sum(float(s.amount_paid or 0.0) for s in current_month_schedules if s.status == "paid")

    # نسبة التحصيل الإجمالية
    collection_rate = (total_collected / total_portfolio_value * 100) if total_portfolio_value > 0 else 0.0

    # قائمة بأبرز المتأخرين لتحصيلها
    overdue_customers_map = defaultdict(lambda: {"customer_name": "", "phone": "", "amount": 0.0, "count": 0})
    for s in overdue_schedules:
        con = db.query(InstallmentContract).filter(InstallmentContract.id == s.contract_id).first()
        if con:
            cust = db.query(Customer).filter(Customer.id == con.customer_id).first()
            if cust:
                entry = overdue_customers_map[cust.id]
                entry["customer_name"] = cust.full_name
                entry["phone"] = cust.phone_number
                entry["amount"] += (float(s.amount_due) - float(s.amount_paid or 0.0))
                entry["count"] += 1

    overdue_list = list(overdue_customers_map.values())
    overdue_list.sort(key=lambda x: x["amount"], reverse=True)

    # أحدث 5 عقود مسجلة
    recent_contracts = []
    latest_contracts = db.query(InstallmentContract).order_by(InstallmentContract.created_at.desc()).limit(5).all()
    for rc in latest_contracts:
        cust = db.query(Customer).filter(Customer.id == rc.customer_id).first()
        recent_contracts.append({
            "contract_number": rc.contract_number,
            "customer_name": cust.full_name if cust else "غير محدد",
            "product_name": rc.product_name,
            "monthly_installment": float(rc.monthly_installment),
            "created_at": str(rc.created_at).split(' ')[0]
        })

    return {
        "total_customers_count": len(customers),
        "total_contracts_count": len(contracts),
        "total_portfolio_value": total_portfolio_value,
        "total_collected": total_collected,
        "total_remaining_debt": total_remaining_debt,
        "total_overdue_amount": total_overdue_amount,
        "total_overdue_installments": len(overdue_schedules),
        "collection_rate": round(collection_rate, 1),
        "current_month_target": current_month_target,
        "current_month_collected": current_month_collected,
        "overdue_customers": overdue_list[:5],
        "recent_contracts": recent_contracts
    }

@app.post("/customers", tags=["العملاء"])
@app.post("/customers/", response_model=CustomerResponse, tags=["العملاء"])
def add_customer(customer: CustomerCreate, db: Session = Depends(get_db)):
    return create_new_customer(db, customer)

@app.get("/customers", tags=["العملاء"])
@app.get("/customers/", tags=["العملاء"])
def list_customers(db: Session = Depends(get_db)):
    today = date.today()
    customers = db.query(Customer).order_by(Customer.created_at.desc()).all()
    result = []
    
    for c in customers:
        contracts = db.query(InstallmentContract).filter(InstallmentContract.customer_id == c.id).all()
        
        total_debt = 0.0
        total_monthly_sum = 0.0
        total_overdue_count = 0
        contracts_details = []
        
        monthly_groups = defaultdict(lambda: {
            "due_date": None,
            "total_due": 0.0,
            "is_paid": True,
            "is_overdue": False,
            "schedule_ids": []
        })

        for con in contracts:
            schedules = db.query(InstallmentSchedule).filter(
                InstallmentSchedule.contract_id == con.id
            ).order_by(InstallmentSchedule.installment_index).all()

            paid_schedules = [s for s in schedules if s.status == "paid"]
            unpaid_schedules = [s for s in schedules if s.status != "paid"]
            
            next_due_date = "تم سداد الكل"
            for s in unpaid_schedules:
                if s.due_date:
                    next_due_date = str(s.due_date)
                    break

            total_debt += sum(float(s.amount_due) - float(s.amount_paid or 0.0) for s in unpaid_schedules)
            total_monthly_sum += float(con.monthly_installment)

            contracts_details.append({
                "id": str(con.id),
                "contract_number": con.contract_number,
                "product_name": getattr(con, 'product_name', 'سلعة عامة'),
                "total_cash_price": float(con.total_cash_price),
                "down_payment": float(con.down_payment),
                "financed_amount": float(con.financed_amount),
                "interest_rate_percent": float(con.interest_rate_percent),
                "total_contract_amount": float(con.total_contract_amount),
                "monthly_installment": float(con.monthly_installment),
                "months_count": con.months_count,
                "paid_months": len(paid_schedules),
                "remaining_months": len(unpaid_schedules),
                "next_due_date": next_due_date,
                "paid_amount": sum(float(s.amount_paid or 0.0) for s in schedules),
                "remaining_amount": sum(float(s.amount_due) - float(s.amount_paid or 0.0) for s in unpaid_schedules),
                "start_date": str(con.start_date)
            })

            for s in schedules:
                month_key = s.due_date.strftime("%Y-%m")
                group = monthly_groups[month_key]
                group["due_date"] = str(s.due_date)
                group["total_due"] += float(s.amount_due)
                group["schedule_ids"].append(str(s.id))
                
                if s.status != "paid":
                    group["is_paid"] = False
                    if s.due_date < today:
                        group["is_overdue"] = True

        sorted_months = []
        for m_key in sorted(monthly_groups.keys()):
            g = monthly_groups[m_key]
            if g["is_overdue"] and not g["is_paid"]:
                total_overdue_count += 1
            sorted_months.append({
                "month_key": m_key,
                "due_date": g["due_date"],
                "total_due": g["total_due"],
                "is_paid": g["is_paid"],
                "is_overdue": g["is_overdue"] and not g["is_paid"],
                "schedule_ids": g["schedule_ids"]
            })

        remaining_unpaid_months = sum(1 for m in sorted_months if not m["is_paid"])

        result.append({
            "id": str(c.id),
            "full_name": c.full_name,
            "national_id": c.national_id,
            "phone_number": c.phone_number,
            "address": c.address or "غير محدد",
            "contracts_count": len(contracts),
            "total_debt": total_debt,
            "total_monthly_sum": total_monthly_sum,
            "total_remaining_months": remaining_unpaid_months,
            "total_overdue_count": total_overdue_count,
            "has_overdue": total_overdue_count > 0,
            "contracts": contracts_details,
            "monthly_schedule": sorted_months,
            "created_at": str(c.created_at)
        })
    return result

@app.delete("/customers/{customer_id}", tags=["العملاء"])
@app.delete("/customers/{customer_id}/", tags=["العملاء"])
def delete_customer(customer_id: str, db: Session = Depends(get_db)):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="العميل غير موجود")
    
    contracts = db.query(InstallmentContract).filter(InstallmentContract.customer_id == customer.id).all()
    for con in contracts:
        db.query(InstallmentSchedule).filter(InstallmentSchedule.contract_id == con.id).delete()
        db.delete(con)
    
    db.delete(customer)
    db.commit()
    return {"message": "تم حذف العميل وعقوده بنجاح"}

@app.delete("/contracts/{contract_id}", tags=["العقود والأقساط"])
@app.delete("/contracts/{contract_id}/", tags=["العقود والأقساط"])
def delete_contract(contract_id: str, db: Session = Depends(get_db)):
    contract = db.query(InstallmentContract).filter(InstallmentContract.id == contract_id).first()
    if not contract:
        raise HTTPException(status_code=404, detail="العقد غير موجود")

    db.query(InstallmentSchedule).filter(InstallmentSchedule.contract_id == contract.id).delete()
    db.delete(contract)
    db.commit()
    return {"message": "تم حذف المنتج والعقد بنجاح"}

@app.post("/contracts", tags=["العقود والأقساط"])
@app.post("/contracts/", tags=["العقود والأقساط"])
def create_contract(contract: ContractCreate, db: Session = Depends(get_db)):
    created = create_installment_contract(db, contract)
    return {
        "id": str(created.id),
        "contract_number": created.contract_number,
        "product_name": getattr(created, 'product_name', 'سلعة عامة'),
        "customer_id": str(created.customer_id),
        "message": "Contract created successfully"
    }

@app.put("/contracts/{contract_id}", tags=["العقود والأقساط"])
@app.put("/contracts/{contract_id}/", tags=["العقود والأقساط"])
def update_contract(contract_id: str, req: ContractUpdateRequest, db: Session = Depends(get_db)):
    contract = db.query(InstallmentContract).filter(InstallmentContract.id == contract_id).first()
    if not contract:
        raise HTTPException(status_code=404, detail="العقد غير موجود")

    if req.product_name is not None:
        contract.product_name = req.product_name
    if req.total_cash_price is not None:
        contract.total_cash_price = req.total_cash_price
    if req.down_payment is not None:
        contract.down_payment = req.down_payment
    if req.interest_rate_percent is not None:
        contract.interest_rate_percent = req.interest_rate_percent
    if req.months_count is not None:
        contract.months_count = req.months_count
    if req.start_date is not None:
        contract.start_date = datetime.strptime(req.start_date, "%Y-%m-%d").date()

    months = contract.months_count if contract.months_count > 0 else 1
    financed = max(0.0, float(contract.total_cash_price) - float(contract.down_payment))
    total_interest = financed * (float(contract.interest_rate_percent) / 100.0) * (months / 12.0)
    total_contract = financed + total_interest
    monthly = total_contract / months

    contract.financed_amount = financed
    contract.total_contract_amount = total_contract
    contract.monthly_installment = monthly

    db.query(InstallmentSchedule).filter(InstallmentSchedule.contract_id == contract.id).delete()
    for i in range(1, months + 1):
        due = contract.start_date + relativedelta(months=i-1)
        schedule = InstallmentSchedule(
            contract_id=contract.id,
            installment_index=i,
            due_date=due,
            amount_due=monthly,
            amount_paid=0.0,
            status="pending"
        )
        db.add(schedule)

    db.commit()
    db.refresh(contract)
    return {"message": "تم تحديث جميع بيانات العقد وإعادة جدولة الأقساط بنجاح"}

@app.post("/installments/pay-month", tags=["التحصيل والسداد"])
@app.post("/installments/pay-month/", tags=["التحصيل والسداد"])
def pay_month_installments(req: MonthlyPaymentRequest, db: Session = Depends(get_db)):
    schedules = db.query(InstallmentSchedule).filter(InstallmentSchedule.id.in_(req.schedule_ids)).all()
    if not schedules:
        raise HTTPException(status_code=404, detail="لم يتم العثور على أقساط")
    
    now = datetime.now()
    for s in schedules:
        s.status = "paid"
        s.amount_paid = s.amount_due
        s.paid_at = now
    
    db.commit()
    return {"message": "تم سداد قسط الشهر الإجمالي بنجاح", "count": len(schedules)}