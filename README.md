# API для генерации отчетов на основе данных

Данный проект представляет собой API, предназначенный для обработки запросов, содержащих личные данные пользователя, информацию о его образовании, трудовой деятельности, военной службе и достижениях. Он позволяет генерировать отчеты на основе полученных данных.

## Эндпоинт API

### `POST /generate/report/tz`

Этот метод обрабатывает POST-запросы с JSON-данными, которые содержат различные личные и профессиональные данные. API принимает массив объектов с параметрами, которые будут использованы для генерации отчетов.

#### Параметры запроса

- **tz** — массив объектов, каждый объект содержит личную информацию о человеке и его изображения в формате base64.

Каждый объект в массиве `tz` должен содержать следующие параметры:

- **photo** — изображение в формате base64.
- **fullName** — полное имя.
- **previous_fullName** — предыдущее полное имя (если имеется).
- **date_of_birth** — дата рождения (в формате `ДД.ММ.ГГГГ`).
- **place_of_birth** — место рождения.
- **nationality** — национальность.
- **address** — адрес проживания.
- **citizenship** — гражданство.
- **IIN** — индивидуальный идентификационный номер.
- **phone_number** — номер телефона.
- **marital_status** — семейное положение (например, "женат", "замужем").
- **national_id_number** — номер удостоверения личности.
- **national_id_date_of_provision** — дата выдачи удостоверения личности.
- **national_id_expiration_date** — срок действия удостоверения личности.
- **national_id_issuing_authority** — орган, выдавший удостоверение личности.
- **birth_certificate_id** — идентификатор свидетельства о рождении.
- **birth_certificate_parents_mom** — имя матери в свидетельстве о рождении.
- **birth_certificate_parents_dad** — имя отца в свидетельстве о рождении.
- **birth_certificate_number** — номер свидетельства о рождении.
- **birth_certificate_date_of_provision** — дата выдачи свидетельства о рождении.
- **birth_certificate_issuing_authority** — орган, выдавший свидетельство о рождении.
- **education_degree** — образовательная степень (например, "бакалавр", "магистр").
- **education_name_of_the_place** — наименование учебного заведения.
- **education_date_of_enrollment** — дата зачисления в учебное заведение.
- **education_graduation_date** — дата окончания учебного заведения.
- **education_qualification_degree** — степень квалификации (например, "специалист", "магистр").
- **education_qualification** — квалификация.
- **education_gpa** — средний балл (GPA).
- **labor_activity_date_of_admission_and_termination** — дата поступления и увольнения с работы.
- **labor_activity_name** — название организации.
- **labor_activity_position** — должность.
- **army_audit_fitness_category** — категория годности к службе в армии.
- **army_audit_status** — статус в армии.
- **army_audit_military_specialty** — военная специальность.
- **army_audit_place_of_service** — место службы в армии.
- **army_audit_personal_number** — личный номер в армии.
- **achievement_name** — наименование достижения.
- **achievement_file_type** — тип файла достижения (например, "PDF", "JPEG").
- **photo_relative** — изображение родственника в формате base64.

#### Пример запроса

```json
{
  "tz": [
    {
      "photo": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQIAJQAlAAD/...",
      "fullName": "Төлепбергенов Нұрсылтан Бейбітұлы",
      "previous_fullName": "Төлепбергенов Нұрсылтан Бейбітұлы",
      "date_of_birth": "08.08.1991",
      "place_of_birth": "г. Астана",
      "nationality": "Казах",
      "address": "г Астана Есильский район ул.Сауран 42/1 кв.56",
      "citizenship": "Республика Казахстан",
      "IIN": "910808351156",
      "phone_number": "8-701-555-26-86",
      "marital_status": "женат",
      "national_id_number": "041104104",
      "national_id_date_of_provision": "03.05.2016",
      "national_id_expiration_date": "02.05.2026",
      "national_id_issuing_authority": "Министерство внутренних дел РК",
      "birth_certificate_id": "Arystanbek A. ",
      "birth_certificate_parents_mom": "Arystanbek A. K. ",
      "birth_certificate_parents_dad": "Arystanbek A. K. ",
      "birth_certificate_number": "Arystanbek A. K. ",
      "birth_certificate_date_of_provision": "Arystanbek A. K. ",
      "birth_certificate_issuing_authority": "Arystanbek A. K. ",
      "education_degree": "Arystanbek A. K. ",
      "education_name_of_the_place": "Arystanbek A. K. ",
      "education_date_of_enrollment": "Arystanbek A. K. ",
      "education_graduation_date": "Arystanbek A. K. ",
      "education_qualification_degree": "Arystanbek A. K. ",
      "education_qualification": "Arystanbek A. K. ",
      "education_gpa": "Arystanbek A. K. ",
      "labor_activity_date_of_admission_and_termination": "Arystanbek A. K. ",
      "labor_activity_name": "Arystanbek A. K. ",
      "labor_activity_position": "Arystanbek A. K. ",
      "army_audit_fitness_category": "Limited duty",
      "army_audit_status": "Reserve",
      "army_audit_military_specialty": "Combat Medic",
      "army_audit_place_of_service": "Regional Command HQ",
      "army_audit_personal_number": "KZ987654321",
      "achievement_name": "Arystanbek A. K. ",
      "achievement_file_type": "Arystanbek A. K. ",
      "photo_relative": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQIAJQAlAAD/..."
    }
  ]
}
