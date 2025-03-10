from typing import Annotated, List, Union

from fastapi import Depends, FastAPI, HTTPException, Query
from sqlmodel import Field, Relationship, Session, SQLModel, create_engine, select

class Diagnosis(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str
    patient_id: int = Field(default=None, foreign_key="patient.id")
    patient: "Patient" = Relationship(back_populates="diagnoses")

class Patient(SQLModel, table=True):
    id: Union[int, None] = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    age: Union[int, None] = Field(default=None, index=True)
    ssn: str
    diagnoses: List[Diagnosis] = Relationship(back_populates="patient")

sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"

connect_args = {"check_same_thread": False}
engine = create_engine(sqlite_url, connect_args=connect_args)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def recreate_db_and_tables():
    SQLModel.metadata.drop_all(engine)
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session

SessionDep = Annotated[Session, Depends(get_session)]

app = FastAPI()

@app.on_event("startup")
def on_startup():
    #recreate_db_and_tables()
    create_db_and_tables()

@app.post("/patients/", response_model=Patient)
def create_patient(patient: Patient, session: SessionDep) -> Patient:
    session.add(patient)
    session.commit()
    session.refresh(patient)
    return patient

@app.get("/patients/", response_model=List[Patient])
def read_patients(
    session: SessionDep,
    offset: int = 0,
    limit: Annotated[int, Query(le=100)] = 100,
) -> List[Patient]:
    patients = session.exec(select(Patient).offset(offset).limit(limit)).all()
    return patients

@app.get("/patients/{patient_id}", response_model=Patient)
def read_patient(patient_id: int, session: SessionDep) -> Patient:
    patient = session.get(Patient, patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient

@app.delete("/patients/{patient_id}", response_model=dict)
def delete_patient(patient_id: int, session: SessionDep):
    patient = session.get(Patient, patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # Check for related diagnoses
    diagnoses = session.exec(select(Diagnosis).where(Diagnosis.patient_id == patient_id)).all()
    if diagnoses:
        for diagnosis in diagnoses:
            session.delete(diagnosis)
    
    session.delete(patient)
    session.commit()
    return {"ok": True}

@app.put("/patients/{patient_id}", response_model=Patient)
def update_patient(patient_id: int, patient: Patient, session: SessionDep) -> Patient:
    db_patient = session.get(Patient, patient_id)
    if not db_patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    db_patient.name = patient.name
    db_patient.age = patient.age
    db_patient.ssn = patient.ssn
    session.commit()
    session.refresh(db_patient)
    return db_patient

@app.post("/patients/{patient_id}/diagnoses/", response_model=Diagnosis)
def create_diagnosis(patient_id: int, diagnosis: Diagnosis, session: SessionDep) -> Diagnosis:
    patient = session.get(Patient, patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    diagnosis.patient_id = patient_id
    session.add(diagnosis)
    session.commit()
    session.refresh(diagnosis)
    return diagnosis

@app.get("/patients/{patient_id}/diagnoses/", response_model=List[Diagnosis])
def read_diagnoses(patient_id: int, session: SessionDep) -> List[Diagnosis]:
    diagnoses = session.exec(select(Diagnosis).where(Diagnosis.patient_id == patient_id)).all()
    return diagnoses

@app.delete("/patients/{patient_id}/diagnoses/{diagnosis_id}", response_model=Diagnosis)
def delete_diagnosis(patient_id: int, diagnosis_id: int, session: SessionDep) -> Diagnosis:
    diagnosis = session.get(Diagnosis, diagnosis_id)
    if not diagnosis or diagnosis.patient_id != patient_id:
        raise HTTPException(status_code=404, detail="Diagnosis not found for this patient")
    session.delete(diagnosis)
    session.commit()
    return diagnosis
