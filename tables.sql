-- =====================================================
-- БАЗОВЫЕ ТАБЛИЦЫ (ОРИГИНАЛЬНЫЕ)
-- =====================================================

-- Последовательности
CREATE SEQUENCE IF NOT EXISTS academic_periods_id_seq;
CREATE SEQUENCE IF NOT EXISTS access_controls_id_seq;
CREATE SEQUENCE IF NOT EXISTS approval_processes_id_seq;
CREATE SEQUENCE IF NOT EXISTS attachments_id_seq;
CREATE SEQUENCE IF NOT EXISTS block_compensation_rules_id_seq;
CREATE SEQUENCE IF NOT EXISTS commission_delegations_id_seq;
CREATE SEQUENCE IF NOT EXISTS departments_id_seq;
CREATE SEQUENCE IF NOT EXISTS employee_kpi_plan_history_id_seq;
CREATE SEQUENCE IF NOT EXISTS employee_kpi_plans_id_seq;
CREATE SEQUENCE IF NOT EXISTS employee_kpi_results_id_seq;
CREATE SEQUENCE IF NOT EXISTS employee_plan_indicators_id_seq;
CREATE SEQUENCE IF NOT EXISTS employee_result_indicators_id_seq;
CREATE SEQUENCE IF NOT EXISTS employees_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_olympiad_participation_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_scopus_articles_id_seq;
CREATE SEQUENCE IF NOT EXISTS kpi_blocks_id_seq;
CREATE SEQUENCE IF NOT EXISTS kpi_indicators_id_seq;
CREATE SEQUENCE IF NOT EXISTS position_block_rules_id_seq;
CREATE SEQUENCE IF NOT EXISTS position_kpi_rules_id_seq;
CREATE SEQUENCE IF NOT EXISTS positions_id_seq;
CREATE SEQUENCE IF NOT EXISTS rejection_statistics_id_seq;
CREATE SEQUENCE IF NOT EXISTS user_roles_id_seq;
CREATE SEQUENCE IF NOT EXISTS users_id_seq;

-- Пользователи
CREATE TABLE public.users (
  id integer NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  username character varying NOT NULL UNIQUE,
  email character varying NOT NULL UNIQUE,
  first_name character varying NOT NULL,
  last_name character varying NOT NULL,
  middle_name character varying,
  password_hash character varying NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- Департаменты
CREATE TABLE public.departments (
  id integer NOT NULL DEFAULT nextval('departments_id_seq'::regclass),
  name character varying NOT NULL,
  code character varying UNIQUE,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT departments_pkey PRIMARY KEY (id)
);

-- Должности
CREATE TABLE public.positions (
  id integer NOT NULL DEFAULT nextval('positions_id_seq'::regclass),
  name character varying NOT NULL UNIQUE,
  code character varying UNIQUE,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT positions_pkey PRIMARY KEY (id)
);

-- Сотрудники
CREATE TABLE public.employees (
  id integer NOT NULL DEFAULT nextval('employees_id_seq'::regclass),
  user_id integer,
  employee_number character varying UNIQUE,
  department_id integer,
  position_id integer,
  hire_date date NOT NULL,
  is_mid_year_hire boolean DEFAULT false,
  mid_year_hire_date date,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT employees_pkey PRIMARY KEY (id),
  CONSTRAINT employees_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT employees_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id),
  CONSTRAINT employees_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id)
);

-- Академические периоды
CREATE TABLE public.academic_periods (
  id integer NOT NULL DEFAULT nextval('academic_periods_id_seq'::regclass),
  name character varying NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  is_active boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT academic_periods_pkey PRIMARY KEY (id)
);

-- Блоки KPI
CREATE TABLE public.kpi_blocks (
  id integer NOT NULL DEFAULT nextval('kpi_blocks_id_seq'::regclass),
  name character varying NOT NULL,
  code character varying UNIQUE,
  description text,
  is_survey_based boolean DEFAULT false,
  survey_threshold numeric,
  min_threshold numeric,
  evaluation_method character varying,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT kpi_blocks_pkey PRIMARY KEY (id)
);

-- Индикаторы KPI
CREATE TABLE public.kpi_indicators (
  id integer NOT NULL DEFAULT nextval('kpi_indicators_id_seq'::regclass),
  block_id integer,
  name character varying NOT NULL,
  code character varying,
  description text,
  indicator_type character varying,
  is_alternative boolean DEFAULT false, -- для альтернативных показателей
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT kpi_indicators_pkey PRIMARY KEY (id),
  CONSTRAINT kpi_indicators_block_id_fkey FOREIGN KEY (block_id) REFERENCES public.kpi_blocks(id)
);

-- Правила KPI для должностей
CREATE TABLE public.position_kpi_rules (
  id integer NOT NULL DEFAULT nextval('position_kpi_rules_id_seq'::regclass),
  position_id integer,
  academic_period_id integer,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT position_kpi_rules_pkey PRIMARY KEY (id),
  CONSTRAINT position_kpi_rules_academic_period_id_fkey FOREIGN KEY (academic_period_id) REFERENCES public.academic_periods(id),
  CONSTRAINT position_kpi_rules_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id)
);

-- Правила блоков для должностей
CREATE TABLE public.position_block_rules (
  id integer NOT NULL DEFAULT nextval('position_block_rules_id_seq'::regclass),
  position_rule_id integer,
  block_id integer,
  required_indicators_count integer NOT NULL,
  weight_percentage numeric NOT NULL,
  is_mandatory boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT position_block_rules_pkey PRIMARY KEY (id),
  CONSTRAINT position_block_rules_position_rule_id_fkey FOREIGN KEY (position_rule_id) REFERENCES public.position_kpi_rules(id),
  CONSTRAINT position_block_rules_block_id_fkey FOREIGN KEY (block_id) REFERENCES public.kpi_blocks(id)
);

-- Планы KPI сотрудников
CREATE TABLE public.employee_kpi_plans (
  id integer NOT NULL DEFAULT nextval('employee_kpi_plans_id_seq'::regclass),
  employee_id integer,
  academic_period_id integer,
  version integer DEFAULT 1,
  parent_plan_id integer,
  status character varying DEFAULT 'draft'::character varying,
  is_current boolean DEFAULT true,
  is_change_request boolean DEFAULT false,
  change_reason text,
  submitted_at timestamp without time zone,
  approved_at timestamp without time zone,
  rejected_at timestamp without time zone,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT employee_kpi_plans_pkey PRIMARY KEY (id),
  CONSTRAINT employee_kpi_plans_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id),
  CONSTRAINT employee_kpi_plans_academic_period_id_fkey FOREIGN KEY (academic_period_id) REFERENCES public.academic_periods(id),
  CONSTRAINT employee_kpi_plans_parent_plan_id_fkey FOREIGN KEY (parent_plan_id) REFERENCES public.employee_kpi_plans(id)
);

-- Результаты KPI сотрудников
CREATE TABLE public.employee_kpi_results (
  id integer NOT NULL DEFAULT nextval('employee_kpi_results_id_seq'::regclass),
  employee_id integer,
  academic_period_id integer,
  plan_id integer,
  status character varying DEFAULT 'draft'::character varying,
  survey_result numeric,
  final_kpi_percentage numeric,
  submission_count integer DEFAULT 0,
  submitted_at timestamp without time zone,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT employee_kpi_results_pkey PRIMARY KEY (id),
  CONSTRAINT employee_kpi_results_academic_period_id_fkey FOREIGN KEY (academic_period_id) REFERENCES public.academic_periods(id),
  CONSTRAINT employee_kpi_results_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.employee_kpi_plans(id),
  CONSTRAINT employee_kpi_results_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id)
);

-- Индикаторы планов сотрудников
CREATE TABLE public.employee_plan_indicators (
  id integer NOT NULL DEFAULT nextval('employee_plan_indicators_id_seq'::regclass),
  plan_id integer,
  indicator_id integer,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT employee_plan_indicators_pkey PRIMARY KEY (id),
  CONSTRAINT employee_plan_indicators_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(id),
  CONSTRAINT employee_plan_indicators_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.employee_kpi_plans(id)
);

-- Индикаторы результатов сотрудников
CREATE TABLE public.employee_result_indicators (
  id integer NOT NULL DEFAULT nextval('employee_result_indicators_id_seq'::regclass),
  result_id integer,
  indicator_id integer,
  is_completed boolean DEFAULT false,
  completion_percentage numeric,
  notes text,
  achievement_details text,
  verification_status character varying,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT employee_result_indicators_pkey PRIMARY KEY (id),
  CONSTRAINT employee_result_indicators_result_id_fkey FOREIGN KEY (result_id) REFERENCES public.employee_kpi_results(id),
  CONSTRAINT employee_result_indicators_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(id)
);

-- =====================================================
-- СПРАВОЧНЫЕ ТАБЛИЦЫ (НОВЫЕ)
-- =====================================================

-- Последовательности для новых таблиц
CREATE SEQUENCE IF NOT EXISTS activity_types_id_seq;
CREATE SEQUENCE IF NOT EXISTS event_levels_id_seq;
CREATE SEQUENCE IF NOT EXISTS journal_quartiles_id_seq;
CREATE SEQUENCE IF NOT EXISTS publishing_houses_id_seq;
CREATE SEQUENCE IF NOT EXISTS media_outlets_id_seq;
CREATE SEQUENCE IF NOT EXISTS educational_platforms_id_seq;

-- Типы активности
CREATE TABLE public.activity_types (
  id integer NOT NULL DEFAULT nextval('activity_types_id_seq'::regclass),
  code character varying UNIQUE NOT NULL,
  name character varying NOT NULL,
  category character varying NOT NULL, -- 'scientific', 'educational', 'public', 'sports'
  description text,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT activity_types_pkey PRIMARY KEY (id)
);

-- Уровни мероприятий
CREATE TABLE public.event_levels (
  id integer NOT NULL DEFAULT nextval('event_levels_id_seq'::regclass),
  code character varying UNIQUE NOT NULL,
  name character varying NOT NULL,
  weight numeric DEFAULT 1.0,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT event_levels_pkey PRIMARY KEY (id)
);

-- Квартили журналов
CREATE TABLE public.journal_quartiles (
  id integer NOT NULL DEFAULT nextval('journal_quartiles_id_seq'::regclass),
  code character varying UNIQUE NOT NULL, -- Q1, Q2, Q3, Q4
  name character varying NOT NULL,
  min_percentile numeric,
  max_percentile numeric,
  weight numeric DEFAULT 1.0,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT journal_quartiles_pkey PRIMARY KEY (id)
);

-- Издательства
CREATE TABLE public.publishing_houses (
  id integer NOT NULL DEFAULT nextval('publishing_houses_id_seq'::regclass),
  name character varying NOT NULL,
  type character varying, -- 'international', 'university', 'national'
  is_prestigious boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT publishing_houses_pkey PRIMARY KEY (id)
);

-- СМИ
CREATE TABLE public.media_outlets (
  id integer NOT NULL DEFAULT nextval('media_outlets_id_seq'::regclass),
  name character varying NOT NULL,
  type character varying, -- 'magazine', 'tv', 'online', 'newspaper'
  website character varying,
  is_recommended boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT media_outlets_pkey PRIMARY KEY (id)
);

-- Образовательные платформы
CREATE TABLE public.educational_platforms (
  id integer NOT NULL DEFAULT nextval('educational_platforms_id_seq'::regclass),
  name character varying NOT NULL,
  type character varying, -- 'national', 'international'
  website character varying,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT educational_platforms_pkey PRIMARY KEY (id)
);

-- =====================================================
-- СПЕЦИАЛИЗИРОВАННЫЕ ТАБЛИЦЫ ДЛЯ ИНДИКАТОРОВ (НОВЫЕ)
-- =====================================================

-- Последовательности
CREATE SEQUENCE IF NOT EXISTS indicator_media_publications_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_grants_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_mentoring_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_educational_materials_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_patents_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_conference_participation_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_committee_participation_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_sports_activities_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_teaching_quality_id_seq;
CREATE SEQUENCE IF NOT EXISTS indicator_acm_activities_id_seq;

-- Публикации в СМИ
CREATE TABLE public.indicator_media_publications (
  id integer NOT NULL DEFAULT nextval('indicator_media_publications_id_seq'::regclass),
  result_indicator_id integer,
  publication_type character varying NOT NULL, -- 'article', 'tv_appearance', 'online_platform', 'column'
  media_outlet_id integer,
  title character varying,
  publication_date date,
  url character varying,
  affiliation_mentioned boolean DEFAULT false,
  notes text,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_media_publications_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_media_publications_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id),
  CONSTRAINT indicator_media_publications_media_outlet_id_fkey FOREIGN KEY (media_outlet_id) REFERENCES public.media_outlets(id)
);

-- Гранты и финансирование
CREATE TABLE public.indicator_grants (
  id integer NOT NULL DEFAULT nextval('indicator_grants_id_seq'::regclass),
  result_indicator_id integer,
  grant_type character varying NOT NULL, -- 'research', 'innovation', 'media', 'commercialization', 'international'
  title character varying NOT NULL,
  amount numeric NOT NULL,
  currency character varying DEFAULT 'KZT',
  field_area character varying, -- 'engineering_tech', 'fundamental_social_humanities'
  role character varying NOT NULL, -- 'leader', 'participant'
  funding_source character varying,
  start_date date,
  end_date date,
  status character varying DEFAULT 'active', -- 'active', 'completed', 'cancelled'
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_grants_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_grants_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id)
);

-- Менторская деятельность
CREATE TABLE public.indicator_mentoring (
  id integer NOT NULL DEFAULT nextval('indicator_mentoring_id_seq'::regclass),
  result_indicator_id integer,
  activity_type character varying NOT NULL, -- 'aitu_challenge', 'hackathon', 'olympiad', 'nirs', 'media_festival'
  event_name character varying NOT NULL,
  event_level_id integer,
  team_count integer DEFAULT 1,
  result_description character varying, -- 'finalist', 'winner', 'participant', 'prize_place'
  event_date date,
  notes text,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_mentoring_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_mentoring_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id),
  CONSTRAINT indicator_mentoring_event_level_id_fkey FOREIGN KEY (event_level_id) REFERENCES public.event_levels(id)
);

-- Учебные материалы и курсы
CREATE TABLE public.indicator_educational_materials (
  id integer NOT NULL DEFAULT nextval('indicator_educational_materials_id_seq'::regclass),
  result_indicator_id integer,
  material_type character varying NOT NULL, -- 'textbook', 'manual', 'mooc', 'monograph'
  title character varying NOT NULL,
  platform_id integer,
  publishing_house_id integer,
  hours_duration numeric, -- для МООК
  pages_count integer, -- для печатных материалов
  circulation integer, -- тираж
  personal_contribution_pages numeric, -- личный вклад в печатных листах
  isbn character varying,
  approval_body character varying, -- 'aitu_council', 'umo_rums', 'ministry'
  status character varying DEFAULT 'draft', -- 'draft', 'published', 'approved'
  publication_date date,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_educational_materials_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_educational_materials_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id),
  CONSTRAINT indicator_educational_materials_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES public.educational_platforms(id),
  CONSTRAINT indicator_educational_materials_publishing_house_id_fkey FOREIGN KEY (publishing_house_id) REFERENCES public.publishing_houses(id)
);

-- Патенты и интеллектуальная собственность
CREATE TABLE public.indicator_patents (
  id integer NOT NULL DEFAULT nextval('indicator_patents_id_seq'::regclass),
  result_indicator_id integer,
  patent_type character varying NOT NULL, -- 'patent', 'utility_model', 'industrial_design'
  title character varying NOT NULL,
  registration_number character varying,
  registration_date date,
  inventors text, -- список изобретателей
  owner character varying DEFAULT 'AITU', -- правообладатель
  status character varying DEFAULT 'pending', -- 'pending', 'granted', 'expired'
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_patents_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_patents_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id)
);

-- Участие в конференциях и рецензирование
CREATE TABLE public.indicator_conference_participation (
  id integer NOT NULL DEFAULT nextval('indicator_conference_participation_id_seq'::regclass),
  result_indicator_id integer,
  participation_type character varying NOT NULL, -- 'reviewer', 'organizer', 'speaker'
  event_name character varying NOT NULL,
  event_type character varying, -- 'conference', 'journal', 'seminar', 'workshop'
  role character varying,
  indexing_databases text, -- IEEE, Scopus, WoS и т.д.
  event_date date,
  is_aitu_affiliated boolean DEFAULT false,
  notes text,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_conference_participation_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_conference_participation_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id)
);

-- Участие в комитетах и рабочих группах
CREATE TABLE public.indicator_committee_participation (
  id integer NOT NULL DEFAULT nextval('indicator_committee_participation_id_seq'::regclass),
  result_indicator_id integer,
  committee_type character varying NOT NULL, -- 'academic_committee', 'working_group', 'council', 'republican_commission'
  committee_name character varying NOT NULL,
  role character varying,
  level character varying, -- 'university', 'republican', 'international'
  start_date date,
  end_date date,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_committee_participation_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_committee_participation_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id)
);

-- Спортивная деятельность
CREATE TABLE public.indicator_sports_activities (
  id integer NOT NULL DEFAULT nextval('indicator_sports_activities_id_seq'::regclass),
  result_indicator_id integer,
  activity_type character varying NOT NULL, -- 'team_training', 'competition_organization', 'section_management'
  sport_type character varying, -- вид спорта
  event_name character varying,
  event_level_id integer,
  participants_count integer,
  result_description character varying,
  event_date date,
  frequency character varying, -- для секций - регулярность встреч
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_sports_activities_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_sports_activities_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id),
  CONSTRAINT indicator_sports_activities_event_level_id_fkey FOREIGN KEY (event_level_id) REFERENCES public.event_levels(id)
);

-- Качество преподавания
CREATE TABLE public.indicator_teaching_quality (
  id integer NOT NULL DEFAULT nextval('indicator_teaching_quality_id_seq'::regclass),
  result_indicator_id integer,
  survey_type character varying NOT NULL, -- 'student_survey', 'peer_evaluation', 'director_assessment'
  score numeric NOT NULL,
  max_score numeric DEFAULT 100,
  period_start date,
  period_end date,
  evaluator_role character varying,
  notes text,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_teaching_quality_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_teaching_quality_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id)
);

-- ACM деятельность (для тренеров)
CREATE TABLE public.indicator_acm_activities (
  id integer NOT NULL DEFAULT nextval('indicator_acm_activities_id_seq'::regclass),
  result_indicator_id integer,
  activity_type character varying NOT NULL, -- 'team_selection', 'competition_organization', 'training', 'school_work'
  event_name character varying,
  teams_count integer,
  participants_count integer,
  competition_level character varying, -- 'quarter_final', 'semi_final', 'final'
  result_description character varying,
  event_date date,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_acm_activities_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_acm_activities_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id)
);

-- =====================================================
-- РАСШИРЕНИЕ ОРИГИНАЛЬНЫХ ТАБЛИЦ
-- =====================================================

-- Статьи в Scopus (расширение оригинальной таблицы)
CREATE TABLE public.indicator_scopus_articles (
  id integer NOT NULL DEFAULT nextval('indicator_scopus_articles_id_seq'::regclass),
  result_indicator_id integer,
  article_title character varying NOT NULL,
  journal_name character varying,
  publication_date date,
  scopus_id character varying,
  wos_id character varying, -- Web of Science ID
  doi character varying,
  quartile_id integer, -- связь с таблицей квартилей
  database_source character varying, -- 'scopus', 'wos', 'both'
  authors text,
  affiliation_correct boolean DEFAULT false,
  status character varying DEFAULT 'accepted', -- 'accepted', 'published', 'in_press'
  citation_count integer DEFAULT 0,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_scopus_articles_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_scopus_articles_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id),
  CONSTRAINT indicator_scopus_articles_quartile_id_fkey FOREIGN KEY (quartile_id) REFERENCES public.journal_quartiles(id)
);

-- Участие в олимпиадах (расширение оригинальной таблицы)
CREATE TABLE public.indicator_olympiad_participation (
  id integer NOT NULL DEFAULT nextval('indicator_olympiad_participation_id_seq'::regclass),
  result_indicator_id integer,
  olympiad_name character varying NOT NULL,
  level_id integer,
  participation_date date,
  role character varying, -- 'organizer', 'judge', 'mentor', 'participant'
  participants_count integer,
  result_description text,
  certificate_number character varying,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT indicator_olympiad_participation_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_olympiad_participation_result_indicator_id_fkey FOREIGN KEY (result_indicator_id) REFERENCES public.employee_result_indicators(id),
  CONSTRAINT indicator_olympiad_participation_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.event_levels(id)
);

-- =====================================================
-- ОСТАЛЬНЫЕ ОРИГИНАЛЬНЫЕ ТАБЛИЦЫ
-- =====================================================

CREATE TABLE public.user_roles (
  id integer NOT NULL DEFAULT nextval('user_roles_id_seq'::regclass),
  user_id integer,
  role_type character varying NOT NULL,
  department_id integer,
  position_id integer,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_roles_pkey PRIMARY KEY (id),
  CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT user_roles_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id),
  CONSTRAINT user_roles_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id)
);

CREATE TABLE public.access_controls (
  id integer NOT NULL DEFAULT nextval('access_controls_id_seq'::regclass),
  academic_period_id integer,
  access_type character varying NOT NULL,
  is_open boolean DEFAULT false,
  opened_by integer,
  opened_at timestamp without time zone,
  closed_by integer,
  closed_at timestamp without time zone,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT access_controls_pkey PRIMARY KEY (id),
  CONSTRAINT access_controls_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES public.users(id),
  CONSTRAINT access_controls_opened_by_fkey FOREIGN KEY (opened_by) REFERENCES public.users(id),
  CONSTRAINT access_controls_academic_period_id_fkey FOREIGN KEY (academic_period_id) REFERENCES public.academic_periods(id)
);

CREATE TABLE public.approval_processes (
  id integer NOT NULL DEFAULT nextval('approval_processes_id_seq'::regclass),
  entity_type character varying NOT NULL,
  entity_id integer NOT NULL,
  academic_period_id integer,
  approver_role character varying NOT NULL,
  approver_id integer,
  status character varying NOT NULL,
  comments text,
  step_order integer DEFAULT 1,
  processed_at timestamp without time zone,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT approval_processes_pkey PRIMARY KEY (id),
  CONSTRAINT approval_processes_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id),
  CONSTRAINT approval_processes_academic_period_id_fkey FOREIGN KEY (academic_period_id) REFERENCES public.academic_periods(id)
);

CREATE TABLE public.attachments (
  id integer NOT NULL DEFAULT nextval('attachments_id_seq'::regclass),
  entity_type character varying NOT NULL,
  entity_id integer NOT NULL,
  file_name character varying NOT NULL,
  file_path character varying NOT NULL,
  file_size bigint,
  mime_type character varying,
  uploaded_by integer,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT attachments_pkey PRIMARY KEY (id),
  CONSTRAINT attachments_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id)
);

CREATE TABLE public.block_compensation_rules (
  id integer NOT NULL DEFAULT nextval('block_compensation_rules_id_seq'::regclass),
  position_id integer,
  source_block_id integer,
  target_block_id integer,
  compensation_type character varying NOT NULL,
  min_percentage numeric,
  compensation_percentage numeric,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT block_compensation_rules_pkey PRIMARY KEY (id),
  CONSTRAINT block_compensation_rules_source_block_id_fkey FOREIGN KEY (source_block_id) REFERENCES public.kpi_blocks(id),
  CONSTRAINT block_compensation_rules_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id),
  CONSTRAINT block_compensation_rules_target_block_id_fkey FOREIGN KEY (target_block_id) REFERENCES public.kpi_blocks(id)
);

CREATE TABLE public.commission_delegations (
  id integer NOT NULL DEFAULT nextval('commission_delegations_id_seq'::regclass),
  delegator_id integer,
  delegate_id integer,
  employee_result_id integer,
  academic_period_id integer,
  delegation_note text,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT commission_delegations_pkey PRIMARY KEY (id),
  CONSTRAINT commission_delegations_delegate_id_fkey FOREIGN KEY (delegate_id) REFERENCES public.users(id),
  CONSTRAINT commission_delegations_academic_period_id_fkey FOREIGN KEY (academic_period_id) REFERENCES public.academic_periods(id),
  CONSTRAINT commission_delegations_delegator_id_fkey FOREIGN KEY (delegator_id) REFERENCES public.users(id),
   CONSTRAINT commission_delegations_employee_result_id_fkey FOREIGN KEY (employee_result_id) REFERENCES public.employee_kpi_results(id)
  );

  CREATE TABLE public.employee_kpi_plan_history (
   id integer NOT NULL DEFAULT nextval('employee_kpi_plan_history_id_seq'::regclass),
   plan_id integer,
   action character varying NOT NULL,
   previous_status character varying,
   new_status character varying,
   action_by integer,
   comments text,
   created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
   CONSTRAINT employee_kpi_plan_history_pkey PRIMARY KEY (id),
   CONSTRAINT employee_kpi_plan_history_action_by_fkey FOREIGN KEY (action_by) REFERENCES public.users(id),
   CONSTRAINT employee_kpi_plan_history_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.employee_kpi_plans(id)
  );

  CREATE TABLE public.rejection_statistics (
   id integer NOT NULL DEFAULT nextval('rejection_statistics_id_seq'::regclass),
   employee_id integer,
   academic_period_id integer,
   entity_type character varying NOT NULL,
   approver_role character varying NOT NULL,
   rejection_count integer DEFAULT 0,
   revision_count integer DEFAULT 0,
   created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
   CONSTRAINT rejection_statistics_pkey PRIMARY KEY (id),
   CONSTRAINT rejection_statistics_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id),
   CONSTRAINT rejection_statistics_academic_period_id_fkey FOREIGN KEY (academic_period_id) REFERENCES public.academic_periods(id)
  );

  -- =====================================================
  -- ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ ПРОИЗВОДИТЕЛЬНОСТИ
  -- =====================================================

  -- Основные индексы
  CREATE INDEX IF NOT EXISTS idx_employees_user_id ON public.employees(user_id);
  CREATE INDEX IF NOT EXISTS idx_employees_department_id ON public.employees(department_id);
  CREATE INDEX IF NOT EXISTS idx_employees_position_id ON public.employees(position_id);
  CREATE INDEX IF NOT EXISTS idx_employee_kpi_plans_employee_id ON public.employee_kpi_plans(employee_id);
  CREATE INDEX IF NOT EXISTS idx_employee_kpi_plans_academic_period_id ON public.employee_kpi_plans(academic_period_id);
  CREATE INDEX IF NOT EXISTS idx_employee_kpi_results_employee_id ON public.employee_kpi_results(employee_id);
  CREATE INDEX IF NOT EXISTS idx_employee_kpi_results_academic_period_id ON public.employee_kpi_results(academic_period_id);
  CREATE INDEX IF NOT EXISTS idx_employee_result_indicators_result_id ON public.employee_result_indicators(result_id);
  CREATE INDEX IF NOT EXISTS idx_employee_result_indicators_indicator_id ON public.employee_result_indicators(indicator_id);

  -- Индексы для новых таблиц
  CREATE INDEX IF NOT EXISTS idx_indicator_media_publications_result_indicator_id ON public.indicator_media_publications(result_indicator_id);
  CREATE INDEX IF NOT EXISTS idx_indicator_grants_result_indicator_id ON public.indicator_grants(result_indicator_id);
  CREATE INDEX IF NOT EXISTS idx_indicator_mentoring_result_indicator_id ON public.indicator_mentoring(result_indicator_id);
  CREATE INDEX IF NOT EXISTS idx_indicator_educational_materials_result_indicator_id ON public.indicator_educational_materials(result_indicator_id);
  CREATE INDEX IF NOT EXISTS idx_indicator_patents_result_indicator_id ON public.indicator_patents(result_indicator_id);
  CREATE INDEX IF NOT EXISTS idx_indicator_scopus_articles_result_indicator_id ON public.indicator_scopus_articles(result_indicator_id);

  -- =====================================================
  -- БАЗОВЫЕ ДАННЫЕ ДЛЯ СПРАВОЧНИКОВ
  -- =====================================================

  -- Типы активности
  INSERT INTO public.activity_types (code, name, category, description) VALUES
  ('SCOPUS_ARTICLE', 'Статья в Scopus', 'scientific', 'Публикация статьи в журнале, индексируемом Scopus'),
  ('WOS_ARTICLE', 'Статья в Web of Science', 'scientific', 'Публикация статьи в журнале, индексируемом Web of Science'),
  ('MEDIA_COLUMN', 'Постоянная колонка в медиа', 'public', 'Ведение постоянной колонки в медиа издании'),
  ('GRANT_LEADERSHIP', 'Руководство грантом', 'scientific', 'Руководство научным или инновационным проектом'),
  ('MOOC_DEVELOPMENT', 'Разработка МООК', 'educational', 'Создание массового открытого онлайн курса'),
  ('PATENT', 'Получение патента', 'scientific', 'Регистрация объекта интеллектуальной собственности'),
  ('PHD_SUPERVISION', 'Руководство PhD', 'educational', 'Научное руководство докторантом'),
  ('MENTORING', 'Менторство', 'public', 'Менторская деятельность над проектами студентов'),
  ('COMMITTEE_PARTICIPATION', 'Участие в комитетах', 'public', 'Работа в различных комитетах и рабочих группах'),
  ('TEACHING_QUALITY', 'Качество преподавания', 'educational', 'Оценка качества преподавательской деятельности');

  -- Уровни мероприятий
  INSERT INTO public.event_levels (code, name, weight) VALUES
  ('UNIVERSITY', 'Университетский', 1.0),
  ('CITY', 'Городской', 1.2),
  ('REGIONAL', 'Региональный', 1.5),
  ('REPUBLICAN', 'Республиканский', 2.0),
  ('INTERNATIONAL', 'Международный', 3.0);

  -- Квартили журналов
  INSERT INTO public.journal_quartiles (code, name, min_percentile, max_percentile, weight) VALUES
  ('Q1', 'Q1 (Top 25%)', 75.0, 100.0, 4.0),
  ('Q2', 'Q2 (25-50%)', 50.0, 75.0, 3.0),
  ('Q3', 'Q3 (50-75%)', 25.0, 50.0, 2.0),
  ('Q4', 'Q4 (Bottom 25%)', 0.0, 25.0, 1.0);

  -- Престижные издательства
  INSERT INTO public.publishing_houses (name, type, is_prestigious) VALUES
  ('Elsevier', 'international', true),
  ('Springer Nature', 'international', true),
  ('Wiley', 'international', true),
  ('Taylor & Francis', 'international', true),
  ('Oxford University Press', 'international', true),
  ('Cambridge University Press', 'international', true),
  ('MIT Press', 'international', true),
  ('Harvard University Press', 'international', true),
  ('Princeton University Press', 'international', true),
  ('Stanford University Press', 'international', true),
  ('Routledge', 'international', true),
  ('Sage Publications', 'international', true),
  ('Palgrave Macmillan', 'international', true),
  ('McGraw Hill', 'international', true),
  ('Pearson', 'international', true);

  -- Рекомендованные медиа издания
  INSERT INTO public.media_outlets (name, type, website, is_recommended) VALUES
  ('Жас Өнер', 'magazine', null, true),
  ('Евразийская наука и искусство', 'magazine', null, true),
  ('Vosmerka.kz', 'online', 'https://vosmerka.kz', true),
  ('Brod.kz', 'online', 'https://brod.kz', true),
  ('The Steppe', 'online', 'https://the-steppe.com', true);

  -- Образовательные платформы
  INSERT INTO public.educational_platforms (name, type, website) VALUES
  ('Bilim Land', 'national', 'https://bilimland.kz'),
  ('Open KazNU', 'national', 'https://open.kaznu.kz'),
  ('Ашық университет', 'national', 'https://open.kz'),
  ('AITU Learn', 'university', 'https://learn.astanait.edu.kz'),
  ('Coursera', 'international', 'https://coursera.org'),
  ('EdX', 'international', 'https://edx.org'),
  ('Udacity', 'international', 'https://udacity.com'),
  ('FutureLearn', 'international', 'https://futurelearn.com');

  -- Должности согласно документу
  INSERT INTO public.positions (name, code) VALUES
  ('Профессор', 'PROFESSOR'),
  ('Ассоциированный профессор', 'ASSOCIATE_PROFESSOR'),
  ('Ассистент профессор', 'ASSISTANT_PROFESSOR'),
  ('Сеньор-лектор', 'SENIOR_LECTURER'),
  ('Преподаватель', 'LECTURER'),
  ('Главный ACM тренер', 'HEAD_ACM_TRAINER'),
  ('ACM тренер', 'ACM_TRAINER'),
  ('Преподаватель физкультуры', 'PE_TEACHER'),
  ('Старший преподаватель физкультуры', 'SENIOR_PE_TEACHER');

  -- Основные блоки KPI
  INSERT INTO public.kpi_blocks (name, code, description, is_survey_based, survey_threshold) VALUES
  ('Научно-инновационная и методическая работа', 'SCIENTIFIC_WORK', 'Блок показателей научной и методической деятельности', false, null),
  ('Общественная (университетская) деятельность', 'PUBLIC_ACTIVITY', 'Блок показателей общественной и университетской деятельности', false, null),
  ('Качество преподавания', 'TEACHING_QUALITY', 'Блок показателей качества преподавательской деятельности', true, 80.0),
  ('Методическая и организационная работа', 'METHODICAL_WORK', 'Блок методической и организационной работы', false, null),
  ('ACM деятельность', 'ACM_ACTIVITY', 'Блок показателей деятельности ACM тренеров', false, null),
  ('Спортивная деятельность', 'SPORTS_ACTIVITY', 'Блок показателей спортивной деятельности', false, null);

  -- =====================================================
  -- КОММЕНТАРИИ К ТАБЛИЦАМ
  -- =====================================================

  COMMENT ON TABLE public.kpi_blocks IS 'Блоки KPI с различными категориями показателей';
  COMMENT ON TABLE public.kpi_indicators IS 'Конкретные индикаторы внутри блоков KPI';
  COMMENT ON TABLE public.employee_kpi_plans IS 'Планы KPI сотрудников на академический период';
  COMMENT ON TABLE public.employee_kpi_results IS 'Результаты выполнения KPI сотрудниками';
  COMMENT ON TABLE public.employee_result_indicators IS 'Связь результатов с конкретными индикаторами';

  COMMENT ON TABLE public.indicator_scopus_articles IS 'Детализация статей в Scopus/WoS для научных индикаторов';
  COMMENT ON TABLE public.indicator_media_publications IS 'Детализация публикаций в СМИ';
  COMMENT ON TABLE public.indicator_grants IS 'Детализация грантов и привлеченного финансирования';
  COMMENT ON TABLE public.indicator_mentoring IS 'Детализация менторской деятельности';
  COMMENT ON TABLE public.indicator_educational_materials IS 'Детализация учебных материалов и курсов';
  COMMENT ON TABLE public.indicator_patents IS 'Детализация патентов и интеллектуальной собственности';
  COMMENT ON TABLE public.indicator_teaching_quality IS 'Детализация оценок качества преподавания';
  COMMENT ON TABLE public.indicator_acm_activities IS 'Детализация деятельности ACM тренеров';
  COMMENT ON TABLE public.indicator_sports_activities IS 'Детализация спортивной деятельности';

  -- =====================================================
  -- ПРЕДСТАВЛЕНИЯ ДЛЯ УДОБСТВА РАБОТЫ С ДАННЫМИ
  -- =====================================================

  -- Представление для полной информации о сотрудниках
  CREATE OR REPLACE VIEW v_employees_full AS
  SELECT
     e.id,
     e.employee_number,
     u.first_name,
     u.last_name,
     u.middle_name,
     u.email,
     d.name as department_name,
     p.name as position_name,
     e.hire_date,
     e.is_active
  FROM public.employees e
  JOIN public.users u ON e.user_id = u.id
  LEFT JOIN public.departments d ON e.department_id = d.id
  LEFT JOIN public.positions p ON e.position_id = p.id;

  -- Представление для текущих результатов KPI
  CREATE OR REPLACE VIEW v_current_kpi_results AS
  SELECT
     ekr.id,
     e.employee_number,
     u.first_name || ' ' || u.last_name as employee_name,
     ap.name as academic_period,
     p.name as position_name,
     ekr.status,
     ekr.final_kpi_percentage,
     ekr.survey_result,
     ekr.submitted_at
  FROM public.employee_kpi_results ekr
  JOIN public.employees e ON ekr.employee_id = e.id
  JOIN public.users u ON e.user_id = u.id
  JOIN public.academic_periods ap ON ekr.academic_period_id = ap.id
  LEFT JOIN public.positions p ON e.position_id = p.id
  WHERE ap.is_active = true;

  -- Представление для статистики по индикаторам
  CREATE OR REPLACE VIEW v_indicator_statistics AS
  SELECT
     kb.name as block_name,
     ki.name as indicator_name,
     COUNT(eri.id) as total_submissions,
     COUNT(CASE WHEN eri.is_completed = true THEN 1 END) as completed_count,
     ROUND(AVG(eri.completion_percentage), 2) as avg_completion_percentage
  FROM public.kpi_indicators ki
  JOIN public.kpi_blocks kb ON ki.block_id = kb.id
  LEFT JOIN public.employee_result_indicators eri ON ki.id = eri.indicator_id
  WHERE ki.is_active = true
  GROUP BY kb.id, kb.name, ki.id, ki.name
  ORDER BY kb.name, ki.name;

  -- =====================================================
  -- ФУНКЦИИ ДЛЯ РАСЧЕТА KPI
  -- =====================================================

  -- Функция для расчета процента выполнения блока KPI
  CREATE OR REPLACE FUNCTION calculate_block_completion(
     p_employee_id integer,
     p_academic_period_id integer,
     p_block_id integer
  ) RETURNS numeric AS $$
  DECLARE
     v_total_indicators integer;
     v_completed_indicators integer;
     v_completion_percentage numeric;
  BEGIN
     -- Подсчет общего количества индикаторов в блоке для данного сотрудника
     SELECT COUNT(eri.id) INTO v_total_indicators
     FROM employee_result_indicators eri
     JOIN employee_kpi_results ekr ON eri.result_id = ekr.id
     JOIN kpi_indicators ki ON eri.indicator_id = ki.id
     WHERE ekr.employee_id = p_employee_id
       AND ekr.academic_period_id = p_academic_period_id
       AND ki.block_id = p_block_id;

     -- Подсчет завершенных индикаторов
     SELECT COUNT(eri.id) INTO v_completed_indicators
     FROM employee_result_indicators eri
     JOIN employee_kpi_results ekr ON eri.result_id = ekr.id
     JOIN kpi_indicators ki ON eri.indicator_id = ki.id
     WHERE ekr.employee_id = p_employee_id
       AND ekr.academic_period_id = p_academic_period_id
       AND ki.block_id = p_block_id
       AND eri.is_completed = true;

     -- Расчет процента выполнения
     IF v_total_indicators > 0 THEN
         v_completion_percentage := (v_completed_indicators::numeric / v_total_indicators::numeric) * 100;
     ELSE
         v_completion_percentage := 0;
     END IF;

     RETURN ROUND(v_completion_percentage, 2);
  END;
  $$ LANGUAGE plpgsql;

  -- Функция для получения итогового KPI сотрудника
  CREATE OR REPLACE FUNCTION calculate_final_kpi(
     p_employee_id integer,
     p_academic_period_id integer
  ) RETURNS numeric AS $$
  DECLARE
     v_final_kpi numeric := 0;
     v_block_record RECORD;
     v_block_completion numeric;
     v_block_weight numeric;
  BEGIN
     -- Получение всех блоков для позиции сотрудника
     FOR v_block_record IN
         SELECT kb.id as block_id, pbr.weight_percentage
         FROM kpi_blocks kb
         JOIN position_block_rules pbr ON kb.id = pbr.block_id
         JOIN position_kpi_rules pkr ON pbr.position_rule_id = pkr.id
         JOIN employees e ON pkr.position_id = e.position_id
         WHERE e.id = p_employee_id
           AND pkr.academic_period_id = p_academic_period_id
           AND pkr.is_active = true
     LOOP
         -- Расчет выполнения блока
         v_block_completion := calculate_block_completion(p_employee_id, p_academic_period_id, v_block_record.block_id);
         v_block_weight := v_block_record.weight_percentage / 100.0;

         -- Добавление к итоговому KPI
         v_final_kpi := v_final_kpi + (v_block_completion * v_block_weight);
     END LOOP;

     RETURN ROUND(v_final_kpi, 2);
  END;
  $$ LANGUAGE plpgsql;

  -- =====================================================
  -- ТРИГГЕРЫ ДЛЯ АВТОМАТИЧЕСКОГО ОБНОВЛЕНИЯ
  -- =====================================================

  -- Триггер для автоматического обновления итогового KPI при изменении результатов индикаторов
  CREATE OR REPLACE FUNCTION update_final_kpi_trigger()
  RETURNS TRIGGER AS $$
  DECLARE
     v_employee_id integer;
     v_academic_period_id integer;
     v_final_kpi numeric;
  BEGIN
     -- Получение ID сотрудника и академического периода
     SELECT ekr.employee_id, ekr.academic_period_id
     INTO v_employee_id, v_academic_period_id
     FROM employee_kpi_results ekr
     WHERE ekr.id = COALESCE(NEW.result_id, OLD.result_id);

     -- Расчет итогового KPI
     v_final_kpi := calculate_final_kpi(v_employee_id, v_academic_period_id);

     -- Обновление итогового KPI в таблице результатов
     UPDATE employee_kpi_results
     SET final_kpi_percentage = v_final_kpi
     WHERE employee_id = v_employee_id
       AND academic_period_id = v_academic_period_id;

     RETURN COALESCE(NEW, OLD);
  END;
  $$ LANGUAGE plpgsql;

  -- Создание триггера
  DROP TRIGGER IF EXISTS trg_update_final_kpi ON employee_result_indicators;
  CREATE TRIGGER trg_update_final_kpi
     AFTER INSERT OR UPDATE OR DELETE ON employee_result_indicators
     FOR EACH ROW
     EXECUTE FUNCTION update_final_kpi_trigger();

  -- =====================================================
  -- ПРАВА ДОСТУПА (ОПЦИОНАЛЬНО)
  -- =====================================================

  -- Создание ролей для разных типов пользователей
  -- CREATE ROLE kpi_admin;
  -- CREATE ROLE kpi_manager;
  -- CREATE ROLE kpi_employee;

  -- Предоставление прав доступа
  -- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kpi_admin;
  -- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO kpi_manager;
  -- GRANT SELECT ON ALL TABLES IN SCHEMA public TO kpi_employee;

  -- =====================================================
  -- ЗАВЕРШЕНИЕ СКРИПТА
  -- =====================================================

  -- Обновление статистики для оптимизатора запросов
  ANALYZE;

  -- Сообщение о завершении
  DO $$
  BEGIN
     RAISE NOTICE 'База данных KPI успешно создана и настроена!';
     RAISE NOTICE 'Создано таблиц: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public');
     RAISE NOTICE 'Создано представлений: %', (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public');
     RAISE NOTICE 'Создано функций: %', (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION');
  END $$;