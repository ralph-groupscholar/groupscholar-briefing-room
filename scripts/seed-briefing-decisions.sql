create table if not exists briefing_room.decision_calls (
  id serial primary key,
  category text not null,
  title text not null,
  summary text not null,
  owner text not null,
  decision_by date,
  confidence int not null,
  coverage_gap boolean not null default false,
  escalation boolean not null default false,
  created_at timestamptz not null default now()
);

insert into briefing_room.decision_calls (
  category,
  title,
  summary,
  owner,
  decision_by,
  confidence,
  coverage_gap,
  escalation
)
values
  (
    'Priority call',
    'Re-sequence verification to unblock 18 scholars',
    'Move cohort 4 into an accelerated review lane and assign two temporary reviewers to clear the backlog in 72 hours.',
    'Program ops',
    '2026-02-09',
    86,
    false,
    false
  ),
  (
    'Enablement lane',
    'Launch timeline clarity kit for applicants',
    'Ship a portal banner + FAQ update to explain verification timing and cut "when will I hear back?" tickets by 35%.',
    'Scholar success',
    '2026-02-11',
    72,
    true,
    false
  ),
  (
    'Partner readiness',
    'Package three impact vignettes for renewals',
    'Lock visuals, quotes, and data points for Northwind Trust before the renewal call to boost confidence.',
    'Partnerships',
    '2026-02-13',
    78,
    false,
    true
  );
