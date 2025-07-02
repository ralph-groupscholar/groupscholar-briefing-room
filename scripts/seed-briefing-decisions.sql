create table if not exists briefing_room.decision_calls (
  id serial primary key,
  title text not null,
  summary text not null,
  owner text not null,
  confidence text not null,
  decision_by date,
  status text not null,
  created_at timestamptz not null default now()
);

insert into briefing_room.decision_calls (
  title,
  summary,
  owner,
  confidence,
  decision_by,
  status
)
select *
from (
  values
    (
      'Re-sequence verification to unblock 18 scholars',
      'Move cohort 4 into an accelerated review lane and assign two temporary reviewers to clear the backlog in 72 hours.',
      'Program ops',
      'High',
      '2026-02-09'::date,
      'Priority'
    ),
    (
      'Launch timeline clarity kit for applicants',
      'Ship a portal banner + FAQ update to explain verification timing and cut "when will I hear back?" tickets by 35%.',
      'Scholar success',
      'Medium',
      '2026-02-11'::date,
      'Pending'
    ),
    (
      'Package three impact vignettes for renewals',
      'Lock visuals, quotes, and data points for Northwind Trust before the renewal call to boost confidence.',
      'Partnerships',
      'High',
      '2026-02-13'::date,
      'Escalated'
    )
) as seed(title, summary, owner, confidence, decision_by, status)
where not exists (
  select 1
  from briefing_room.decision_calls existing
  where existing.title = seed.title
);
