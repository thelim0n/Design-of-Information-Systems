CREATE TABLE CabinetPurpose (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE StaffPosition (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    category enum ('Medical', 'Support', 'Administrative') not null,
    min_experience INT DEFAULT 0 CHECK (min_experience >= 0)
);

CREATE TABLE RoleType (
    id SERIAL PRIMARY KEY,
    code ENUM ('Primary', 'Secondary', 'Consulting') not null UNIQUE,
    name VARCHAR(50) NOT NULL,
    description TEXT
);

CREATE TABLE StatusReference (
    id SERIAL PRIMARY KEY,
    entity_type ENUM ('Hospitalization', 'Operation', 'LabContract') not null,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(10) DEFAULT '#6b7280',
    UNIQUE (entity_type, code)
);

CREATE TABLE LabProfile (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE LabTestType (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    profile_id INT NOT NULL REFERENCES LabProfile(id) ON DELETE RESTRICT,
    base_cost DECIMAL(10,2) NOT NULL CHECK (base_cost >= 0),
    complexity INT DEFAULT 1 CHECK (complexity BETWEEN 1 AND 5),
    turnaround_hours INT DEFAULT 24 CHECK (turnaround_hours > 0),
    UNIQUE (name, profile_id)
);

CREATE TABLE MedicalInstitution (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    type ENUM ('Hospital', 'Polyclinic') NOT NULL,
    parent_institution_id INT REFERENCES MedicalInstitution(id) ON DELETE SET NULL,
    UNIQUE (name, type)
);

CREATE TABLE Building (
    id SERIAL PRIMARY KEY,
    institution_id INT NOT NULL REFERENCES MedicalInstitution(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    UNIQUE (institution_id, name)
);

CREATE TABLE Department (
    id SERIAL PRIMARY KEY,
    building_id INT NOT NULL REFERENCES Building(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    focus_area VARCHAR(150),
    UNIQUE (building_id, name)
);

CREATE TABLE Ward (
    id SERIAL PRIMARY KEY,
    department_id INT NOT NULL REFERENCES Department(id) ON DELETE CASCADE,
    number VARCHAR(20) NOT NULL,
    bed_capacity INT NOT NULL CHECK (bed_capacity > 0),
    UNIQUE (department_id, number)
);

CREATE TABLE Bed (
    id SERIAL PRIMARY KEY,
    ward_id INT NOT NULL REFERENCES Ward(id) ON DELETE CASCADE,
    number VARCHAR(10) NOT NULL,
    is_occupied BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (ward_id, number)
);

CREATE TABLE Cabinet (
    id SERIAL PRIMARY KEY,
    institution_id INT NOT NULL REFERENCES MedicalInstitution(id) ON DELETE CASCADE,
    number VARCHAR(20) NOT NULL,
    purpose_id INT NOT NULL REFERENCES CabinetPurpose(id) ON DELETE RESTRICT,
    UNIQUE (institution_id, number)
);

CREATE TABLE Specialty (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    hazard_coef DECIMAL(3,2) DEFAULT 1.00 CHECK (hazard_coef >= 1.00 AND hazard_coef <= 2.00),
    extended_leave BOOLEAN NOT NULL DEFAULT FALSE,
    allows_surgery BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE Staff (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    position_id INT NOT NULL REFERENCES StaffPosition(id) ON DELETE RESTRICT,
    hire_date DATE NOT NULL,
    contact VARCHAR(100),
    CHECK (hire_date <= CURRENT_DATE)
);

CREATE TABLE Doctor (
    id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL UNIQUE REFERENCES Staff(id) ON DELETE CASCADE,
    specialty_id INT NOT NULL REFERENCES Specialty(id) ON DELETE RESTRICT,
    degree ENUM ('None', 'Candidate', 'Doctor') NOT NULL DEFAULT 'None',
    title ENUM ('None', 'Docent', 'Professor') NOT NULL DEFAULT 'None',
    experience_years INT DEFAULT 0 CHECK (experience_years >= 0),
    
    -- Бизнес-правило: звание должно соответствовать степени
    CONSTRAINT check_degree_title_match CHECK (
        (degree = 'Doctor' AND title IN ('None', 'Professor')) OR
        (degree = 'Candidate' AND title IN ('None', 'Docent')) OR
        (degree = 'None' AND title = 'None')
    )
);

CREATE TABLE Employment (
    id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL REFERENCES Staff(id) ON DELETE CASCADE,
    institution_id INT NOT NULL REFERENCES MedicalInstitution(id) ON DELETE CASCADE,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    role_type_id INT NOT NULL REFERENCES RoleType(id) ON DELETE RESTRICT,
    
    -- Один сотрудник — одна запись в одном учреждении
    UNIQUE (staff_id, institution_id),
    
    -- Бизнес-правило: консультации только для профессоров/доцентов
    CONSTRAINT check_consulting_title CHECK (
        role_type_id != (SELECT id FROM RoleType WHERE code = 'Consulting') OR
        EXISTS (
            SELECT 1 FROM Doctor d 
            WHERE d.staff_id = Employment.staff_id 
            AND d.title IN ('Professor', 'Docent')
        )
    )
);

CREATE TABLE Patient (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    birth_date DATE NOT NULL,
    gender ENUM ('Male', 'Female', 'Other') NOT NULL,
    primary_polyclinic_id INT REFERENCES MedicalInstitution(id) ON DELETE SET NULL,
    CHECK (birth_date <= CURRENT_DATE)
);

CREATE TABLE Hospitalization (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES Patient(id) ON DELETE CASCADE,
    department_id INT NOT NULL REFERENCES Department(id) ON DELETE RESTRICT,
    bed_id INT NOT NULL REFERENCES Bed(id) ON DELETE RESTRICT,
    admission_date DATE NOT NULL DEFAULT current_timestamp,
    discharge_date DATE,
    status_id INT NOT NULL REFERENCES StatusReference(id) ON DELETE RESTRICT,
    current_temp DECIMAL(3,1) CHECK (current_temp BETWEEN 35.0 AND 42.0),
    attending_doctor_id INT REFERENCES Doctor(id) ON DELETE SET NULL,
    
    CHECK (admission_date <= CURRENT_DATE),
    CHECK (discharge_date IS NULL OR discharge_date >= admission_date)
);

CREATE TABLE PolyclinicAssignment (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES Patient(id) ON DELETE CASCADE,
    doctor_id INT NOT NULL REFERENCES Doctor(id) ON DELETE RESTRICT,
    institution_id INT NOT NULL REFERENCES MedicalInstitution(id) ON DELETE CASCADE,
    start_date DATE NOT NULL DEFAULT current_timestamp,
    end_date DATE,
    
    CHECK (start_date <= CURRENT_DATE),
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE MedicalVisit (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES Patient(id) ON DELETE CASCADE,
    doctor_id INT NOT NULL REFERENCES Doctor(id) ON DELETE RESTRICT,
    cabinet_id INT NOT NULL REFERENCES Cabinet(id) ON DELETE RESTRICT,
    visit_date DATE NOT NULL DEFAULT current_timestamp,
    diagnosis TEXT,
    
    CHECK (visit_date <= CURRENT_DATE)
);

CREATE TABLE Operation (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES Patient(id) ON DELETE CASCADE,
    doctor_id INT NOT NULL REFERENCES Doctor(id) ON DELETE RESTRICT,
    institution_id INT NOT NULL REFERENCES MedicalInstitution(id) ON DELETE CASCADE,
    operation_date DATE NOT NULL DEFAULT current_timestamp,
    outcome_status_id INT NOT NULL REFERENCES StatusReference(id) ON DELETE RESTRICT,
    
    CHECK (operation_date <= CURRENT_DATE),
    
    -- Операции только у хирургических специальностей
    CONSTRAINT check_surgery_specialty CHECK (
        EXISTS (
            SELECT 1 FROM Doctor d 
            JOIN Specialty s ON d.specialty_id = s.id
            WHERE d.id = Operation.doctor_id AND s.allows_surgery = TRUE
        )
    )
);

CREATE TABLE Laboratory (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    license_number VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE LabContract (
    id SERIAL PRIMARY KEY,
    lab_id INT NOT NULL REFERENCES Laboratory(id) ON DELETE CASCADE,
    institution_id INT NOT NULL REFERENCES MedicalInstitution(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE,
    status_id INT NOT NULL REFERENCES StatusReference(id) ON DELETE RESTRICT,
    
    CHECK (start_date <= CURRENT_DATE),
    CHECK (end_date IS NULL OR end_date >= start_date),
    UNIQUE (lab_id, institution_id)
);

CREATE TABLE LabTest (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES Patient(id) ON DELETE CASCADE,
    lab_id INT NOT NULL REFERENCES Laboratory(id) ON DELETE RESTRICT,
    test_type_id INT NOT NULL REFERENCES LabTestType(id) ON DELETE RESTRICT,
    test_date DATE NOT NULL DEFAULT current_timestamp,
    result TEXT,
    final_cost DECIMAL(10,2) CHECK (final_cost >= 0),
    
    CHECK (test_date <= CURRENT_DATE)
);

-- Запросы 1-5: фильтрация врачей
CREATE INDEX idx_doctor_specialty ON Doctor(specialty_id);
CREATE INDEX idx_doctor_degree_title ON Doctor(degree, title);
CREATE INDEX idx_employment_institution ON Employment(institution_id, is_primary);

-- Запрос 6: пациенты стационара
CREATE INDEX idx_hospitalization_department ON Hospitalization(department_id, status_id);
CREATE INDEX idx_hospitalization_bed ON Hospitalization(bed_id);

-- Запросы 7, 13: история лечения и операций
CREATE INDEX idx_hospitalization_patient_date ON Hospitalization(patient_id, admission_date);
CREATE INDEX idx_operation_doctor_date ON Operation(doctor_id, operation_date);

-- Запрос 8: амбулаторные пациенты
CREATE INDEX idx_polyclinic_assignment_doctor ON PolyclinicAssignment(doctor_id, end_date);

-- Запросы 9-10: учёт коек и кабинетов
CREATE INDEX idx_bed_occupied ON Bed(ward_id, is_occupied);
CREATE INDEX idx_medical_visit_cabinet_date ON MedicalVisit(cabinet_id, visit_date);

-- Запросы 11-12: выработка и загрузка врачей
CREATE INDEX idx_medical_visit_doctor_date ON MedicalVisit(doctor_id, visit_date);
CREATE INDEX idx_hospitalization_doctor_active ON Hospitalization(attending_doctor_id, status_id);

-- Запрос 14: загрузка лаборатории
CREATE INDEX idx_lab_test_lab_date ON LabTest(lab_id, test_date);