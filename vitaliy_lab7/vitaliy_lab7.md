# Лабораторная работа №7. Проектирование логической модели базы данных для медицинских организаций

📌 **Обоснование (связь с ЛР1–ЛР6)**
Проектирование выполнено как естественное завершение цикла анализа и формализации требований:
- **ЛР1 (Бизнес-процессы)**: процессы госпитализации, амбулаторного приёма, лабораторной диагностики и кадрового учёта напрямую определили транзакционные сущности (`Hospitalization`, `MedicalVisit`, `LabTest`, `Employment`).
- **ЛР2 (Стейкхолдеры и границы)**: роли врачей, медсестёр, пациентов и лабораторий преобразованы в ограничения доступа и справочники (`StaffPosition`, `RoleType`, `StatusReference`).
- **ЛР3–ЛР4 (DFD)**: потоки данных («направление», «результат анализа», «статус койки») стали атрибутами связей и внешними ключами. Хранилища DFD отображены в виде таблиц.
- **ЛР5 (Модель TO-BE)**: сценарии расчёта выработки, поиска свободных коек и контроля совместительства диктовали необходимость составных индексов, уникальных ограничений и справочников статусов.
- **ЛР6 (Бизнес-правила)**: ограничения на совместительство, степени/звания, вредность условий труда и договоры с лабораториями формализованы через `CHECK`, `FK` и триггерные правила.

🔹 **Шаг 1. Выделение основных хранимых сущностей**
`MedicalInstitution`, `Building`, `Department`, `Ward`, `Bed`, `Cabinet`, `CabinetPurpose`, `Staff`, `StaffPosition`, `Specialty`, `Doctor`, `Employment`, `RoleType`, `Patient`, `Hospitalization`, `PolyclinicAssignment`, `MedicalVisit`, `Operation`, `Laboratory`, `LabProfile`, `LabTestType`, `LabTest`, `LabContract`, `StatusReference`.

🔹 **Шаг 2. Атрибуты, ключи, типы данных (абстрактно)**

| Сущность | Атрибуты | Ключ | Типы данных (абстрактно) |
|---|---|---|---|
| `MedicalInstitution` | id, name, type, parent_institution_id | PK: id | INT, VARCHAR(150), ENUM, INT(FK) |
| `Building` | id, institution_id, name | PK: id | INT, INT(FK), VARCHAR(100) |
| `Department` | id, building_id, name, focus_area | PK: id | INT, INT(FK), VARCHAR(100), VARCHAR(150) |
| `Ward` | id, department_id, number, bed_capacity | PK: id | INT, INT(FK), VARCHAR(20), INT |
| `Bed` | id, ward_id, number, is_occupied | PK: id | INT, INT(FK), VARCHAR(10), BOOL |
| `CabinetPurpose` | id, name, description | PK: id | INT, VARCHAR(100), TEXT |
| `Cabinet` | id, institution_id, number, purpose_id | PK: id | INT, INT(FK), VARCHAR(20), INT(FK) |
| `StaffPosition` | id, name, category, min_experience | PK: id | INT, VARCHAR(100), ENUM, INT |
| `Staff` | id, full_name, position_id, hire_date, contact | PK: id | INT, VARCHAR(200), INT(FK), DATE, VARCHAR(50) |
| `Specialty` | id, name, hazard_coef, extended_leave, allows_surgery | PK: id | INT, VARCHAR(100), DECIMAL, BOOL, BOOL |
| `Doctor` | id, staff_id, specialty_id, degree, title, experience_years | PK: id | INT, INT(FK,UNQ), INT(FK), ENUM, ENUM, INT |
| `RoleType` | id, code, name, description | PK: id | INT, VARCHAR(20), VARCHAR(50), TEXT |
| `Employment` | id, staff_id, institution_id, is_primary, role_type_id | PK: id | INT, INT(FK), INT(FK), BOOL, INT(FK) |
| `StatusReference` | id, entity_type, code, name, color | PK: id | INT, VARCHAR(30), VARCHAR(20), VARCHAR(50), VARCHAR(10) |
| `Patient` | id, full_name, birth_date, gender, primary_polyclinic_id | PK: id | INT, VARCHAR(200), DATE, ENUM, INT(FK) |
| `Hospitalization` | id, patient_id, department_id, bed_id, admission_date, discharge_date, status_id, current_temp, attending_doctor_id | PK: id | INT, INT(FK), INT(FK), INT(FK), DATE, DATE, INT(FK), DECIMAL, INT(FK) |
| `PolyclinicAssignment` | id, patient_id, doctor_id, institution_id, start_date, end_date | PK: id | INT, INT(FK), INT(FK), INT(FK), DATE, DATE |
| `MedicalVisit` | id, patient_id, doctor_id, cabinet_id, visit_date, diagnosis | PK: id | INT, INT(FK), INT(FK), INT(FK), DATE, TEXT |
| `Operation` | id, patient_id, doctor_id, institution_id, operation_date, outcome_status_id | PK: id | INT, INT(FK), INT(FK), INT(FK), DATE, INT(FK) |
| `Laboratory` | id, name, license_number | PK: id | INT, VARCHAR(150), VARCHAR(50) |
| `LabProfile` | id, name | PK: id | INT, VARCHAR(100) |
| `LabTestType` | id, name, profile_id, base_cost, complexity, turnaround_hours | PK: id | INT, VARCHAR(150), INT(FK), DECIMAL, INT, INT |
| `LabTest` | id, patient_id, lab_id, test_type_id, test_date, result, final_cost | PK: id | INT, INT(FK), INT(FK), INT(FK), DATE, TEXT, DECIMAL |
| `LabContract` | id, lab_id, institution_id, start_date, end_date, status_id | PK: id | INT, INT(FK), INT(FK), DATE, DATE, INT(FK) |

🔹 **Шаг 3. Связи между сущностями и промежуточные таблицы**

| Связь | Тип | Обоснование |
|---|---|---|
| `MedicalInstitution` ↔ `Building` | 1 : M | Учреждение содержит корпуса. |
| `Building` ↔ `Department` | 1 : M | Корпус содержит отделения. |
| `Department` ↔ `Ward` | 1 : M | Отделение состоит из палат. |
| `Ward` ↔ `Bed` | 1 : M | Палата содержит койки. |
| `CabinetPurpose` ↔ `Cabinet` | 1 : M | Справочник целей кабинетов. |
| `MedicalInstitution` ↔ `Cabinet` | 1 : M | Учреждение владеет кабинетами. |
| `StaffPosition` ↔ `Staff` | 1 : M | Штатное расписание привязано к справочнику. |
| `Specialty` ↔ `Doctor` | 1 : M | Специализация определяет профиль врача. |
| `Staff` ↔ `Doctor` | 1 : 1 (0..1) | Врач является подвидом сотрудника. |
| `RoleType` ↔ `Employment` | 1 : M | Справочник типов занятости. |
| `Staff` ↔ `MedicalInstitution` (via `Employment`) | M : M | Учёт основного места и совместительства. |
| `StatusReference` ↔ `Hospitalization`/`Operation`/`LabContract` | 1 : M | Унифицированный справочник статусов с группировкой по `entity_type`. |
| `Patient` ↔ `Hospitalization` | 1 : M | История стационарного лечения. |
| `Bed` ↔ `Hospitalization` | 1 : M (активная) | Койка занята одним пациентом в момент времени. |
| `Department` ↔ `Hospitalization` | 1 : M | Привязка к отделению. |
| `Doctor` ↔ `Hospitalization` | 1 : M | Лечащий врач в стационаре. |
| `Patient` ↔ `Doctor` (via `PolyclinicAssignment`) | M : M | Амбулаторное наблюдение у нескольких врачей. |
| `Patient` ↔ `Doctor`/`Cabinet` (via `MedicalVisit`) | M : M | Факт посещения для расчёта выработки. |
| `Patient` ↔ `Operation` | 1 : M | История хирургических вмешательств. |
| `Doctor` ↔ `Operation` | 1 : M | Исполнитель операции (только если `Specialty.allows_surgery=TRUE`). |
| `Laboratory` ↔ `LabTestType` | 1 : M | Каталог видов исследований. |
| `LabProfile` ↔ `LabTestType` | 1 : M | Группировка анализов по профилям. |
| `Patient` ↔ `LabTest` | 1 : M | Результаты обследований пациента. |
| `Laboratory` ↔ `LabTest` | 1 : M | Факт проведения анализа в конкретной лаборатории. |

🔹 **Шаг 4. Ограничения и целостность (PK / FK, UNIQUE, NOT NULL, CHECK)**

| Ограничение | Поле/Таблица | Описание |
|---|---|---|
| PRIMARY KEY | Все `*_id` | Уникальная идентификация. |
| FOREIGN KEY | Все `*_id(FK)` | Ссылочная целостность. `ON DELETE RESTRICT` для справочников, `ON DELETE CASCADE` для журналов посещений/анализов. |
| NOT NULL | `name`, `hire_date`, `birth_date`, `admission_date`, `test_date`, `status_id` | Критичные данные. |
| UNIQUE | `Employment(staff_id, institution_id)`, `Doctor(staff_id)`, `Bed(number, ward_id)` | Исключает дублирование трудоустройства и номеров коек. |
| UNIQUE | `PolyclinicAssignment(patient_id, doctor_id, institution_id)` (при `end_date IS NULL`) | Одно активное наблюдение у врача в поликлинике. |
| UNIQUE | `LabTestType(name, profile_id)` | Запрет дублирования названий анализов в одном профиле. |
| CHECK / ENUM | `Patient.gender` | Значения строго `('Male','Female','Other')`. |
| CHECK | `Doctor.degree` ↔ `Doctor.title` | `Degree='Doctor' → Title IN ('None','Professor')`; `Degree='Candidate' → Title IN ('None','Docent')`. |
| CHECK | `Employment.role_type` ↔ `Doctor.title` | `role_type='Consulting'` разрешён только при `title IN ('Professor','Docent')`. |
| DEFAULT | `Bed.is_occupied = FALSE` | Автоматическое управление триггером при госпитализации/выписке. |

📌 **Пояснения к атрибутам (по запросу преподавателя)**
- `Specialty.hazard_coef` (DECIMAL): Коэффициент надбавки за вредные условия труда (например, `1.15` для рентгенологов). Применяется к базовой ставке при расчёте ЗП: `salary = base × hazard_coef`. Вынесен в справочник профиля, так как зависит от характера работы, а не от конкретного сотрудника.
- `Specialty.extended_leave` (BOOL): Флаг права на удлинённый отпуск (56 дней вместо 28). Активируется для профилей с повышенным риском или нагрузкой (рентгенология, неврология). Используется модулем HR при формировании графиков.
- `Doctor.title` (ENUM): Учёное звание (`None`, `Docent`, `Professor`). Зависит от степени (`degree`). Только обладатели званий могут работать в режиме консультации в нескольких учреждениях (правило совместительства).

📊 **Результат 1. ER-диаграмма**

![[lovepdf.pdf]]

📝 **Результат 2. Текстовое описание проектирования БД**

**1. Обоснование выбора сущностей и нормализации до 3НФ**
- **1НФ**: Все атрибуты атомарны. Должности, типы ролей, цели кабинетов и статусы вынесены в отдельные справочники. Стоимость анализа отделена от факта его проведения.
- **2НФ**: В ассоциативных таблицах (`Employment`, `Hospitalization`, `PolyclinicAssignment`, `LabTest`) все неключевые поля зависят от полного ключа. Например, `final_cost` в `LabTest` зависит от конкретной записи обследования, а `base_cost` вынесен в `LabTestType`.
- **3НФ**: Отсутствуют транзитивные зависимости. Характеристики профиля (`hazard_coef`, `allows_surgery`) хранятся только в `Specialty`. Зарплатные коэффициенты не дублируются в карточках врачей. Все расчётные метрики (выработка, загрузка) вычисляются динамически через `JOIN` и агрегаты.

**2. Обеспечение целостности и бизнес-правил**
- **Ссылочная целостность**: `FOREIGN KEY` связывают транзакционные таблицы со справочниками. Удаление активных договоров, занятых коек или текущих пациентов запрещено (`RESTRICT`).
- **Доменная целостность**: `ENUM` для пола, степеней, званий, типов учреждений. Справочники `StatusReference`, `RoleType`, `CabinetPurpose` централизуют управление доменами.
- **Сложные правила**: 
  - Совместительство контролируется через `Employment.is_primary` и `role_type_id`. Консультации разрешены только доцентам/профессорам.
  - Операции доступны только врачам со `Specialty.allows_surgery = TRUE` (контроль на уровне приложения/триггера).
  - Статусы коек обновляются автоматически при изменении `Hospitalization.discharge_date`.

**3. Поддержка функциональных требований (14 запросов)**
- **Запросы 1–5**: Фильтрация врачей через `JOIN Staff ↔ Doctor ↔ Specialty ↔ Employment ↔ MedicalInstitution`. Агрегация по `Operation.count` и `experience_years`.
- **Запрос 6**: Стационарные пациенты из `Hospitalization` с `JOIN` на `Bed`, `Department`, `Doctor`, `StatusReference`.
- **Запросы 7, 13**: История лечения и операций по датам и врачам (`Hospitalization`, `Operation`).
- **Запрос 8**: Амбулаторное наблюдение через `PolyclinicAssignment` с фильтрацией по профилю врача.
- **Запросы 9–10**: Учёт коек (`Ward + Bed WHERE is_occupied=FALSE`) и посещений (`MedicalVisit` GROUP BY `cabinet_id`).
- **Запросы 11–12**: Выработка = `COUNT(visit_id) / DATEDIFF`. Загрузка = `COUNT(Hospitalization) WHERE status='Active'`.
- **Запрос 14**: Загрузка лаборатории = `COUNT(LabTest) / период` с привязкой к `LabContract` и `MedicalInstitution`.

**4. Итог**
Логическая модель полностью соответствует 3НФ, устраняет избыточность, гарантирует целостность данных и поддерживает все 14 видов запросов. Схема готова к физической реализации, созданию индексов по FK, представлений для отчётности и ролевой модели доступа.