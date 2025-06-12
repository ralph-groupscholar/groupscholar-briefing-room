create schema if not exists briefing_room;

create table if not exists briefing_room.signal_entries (
  id serial primary key,
  title text not null,
  summary text not null,
  owner text not null,
  urgency text not null,
  target_date date,
  source text,
  created_at timestamptz not null default now()
);

create table if not exists briefing_room.decision_calls (
  id serial primary key,
  title text not null,
  summary text not null,
  owner text not null,
  lane text not null,
  decision_by date,
  confidence text,
  created_at timestamptz not null default now()
);

alter table briefing_room.decision_calls
  add column if not exists lane text,
  add column if not exists decision_by date,
  add column if not exists confidence text;

create table if not exists briefing_room.decision_metrics (
  id serial primary key,
  label text not null,
  value text not null,
  detail text not null,
  position int not null default 1
);

create table if not exists briefing_room.field_notes (
  id serial primary key,
  category text not null,
  headline text not null,
  summary text not null,
  source text not null,
  owner text not null,
  priority int not null default 2,
  spotlight boolean not null default false,
  created_at timestamptz not null default now()
);

with new_signals (title, summary, owner, urgency, target_date, source) as (
  values
    (
      'Verification backlog cleared 40%',
      'Support pod 2 cleared 7 of 18 missing guardian document cases. Remaining 11 need a second touch by Wednesday.',
      'Support pod 2',
      'High',
      '2026-02-11',
      'Zendesk queue'
    ),
    (
      'Ambassador referral sprint gaining lift',
      'Chicago cohort referrals are up 9% after the first 48 hours. Replicate incentive copy to Atlanta and Detroit.',
      'Growth',
      'Medium',
      '2026-02-12',
      'Ambassador slack'
    ),
    (
      'Northwind Trust renewal prep ready',
      'Story vignettes and impact metrics compiled; needs final design polish before Friday call.',
      'Partnerships',
      'Medium',
      '2026-02-13',
      'Partner sync'
    ),
    (
      'Cohort 3 funding variance',
      'Finance flagged a 4% variance in award allocations after late donor adjustments. Draft explanation for exec brief.',
      'Finance',
      'High',
      '2026-02-10',
      'Finance dashboard'
    ),
    (
      'Scholar portal timeline card ready',
      'UX shipped the new timeline banner. QA signoff needed before pushing to production.',
      'Scholar success',
      'Low',
      '2026-02-09',
      'Product board'
    ),
    (
      'Reviewer calibration session booked',
      '30-minute anchor session scheduled to align scoring after Round 2 gaps.',
      'Program ops',
      'Medium',
      '2026-02-10',
      'Reviewer sync'
    )
)
insert into briefing_room.signal_entries (title, summary, owner, urgency, target_date, source)
select new_signals.title,
       new_signals.summary,
       new_signals.owner,
       new_signals.urgency,
       new_signals.target_date::date,
       new_signals.source
from new_signals
where not exists (
  select 1
  from briefing_room.signal_entries
  where signal_entries.title = new_signals.title
);

with new_calls (title, summary, owner, lane, decision_by, confidence) as (
  values
    (
      'Re-sequence verification to unblock 18 scholars',
      'Move cohort 4 into an accelerated review lane and assign two temporary reviewers to clear the backlog in 72 hours.',
      'Program ops',
      'Priority call',
      '2026-02-08',
      'High'
    ),
    (
      'Launch timeline clarity kit for applicants',
      'Ship a portal banner + FAQ update to explain verification timing and cut "when will I hear back?" tickets by 35%.',
      'Scholar success',
      'Enablement lane',
      '2026-02-11',
      'Medium'
    ),
    (
      'Package three impact vignettes for renewals',
      'Lock visuals, quotes, and data points for Northwind Trust before the renewal call to boost confidence.',
      'Partnerships',
      'Partner readiness',
      '2026-02-13',
      'High'
    )
)
insert into briefing_room.decision_calls (title, summary, owner, lane, decision_by, confidence)
select new_calls.title,
       new_calls.summary,
       new_calls.owner,
       new_calls.lane,
       new_calls.decision_by::date,
       new_calls.confidence
from new_calls
where not exists (
  select 1
  from briefing_room.decision_calls
  where decision_calls.title = new_calls.title
);

with new_metrics (label, value, detail, position) as (
  values
    ('Decision confidence', 'High', '9/12 signals verified this week', 1),
    ('Coverage gaps', '2', 'Need reviewer feedback + funder pulse', 2),
    ('Escalations', '1', 'Legal review on ambassador incentives', 3)
)
insert into briefing_room.decision_metrics (label, value, detail, position)
select new_metrics.label,
       new_metrics.value,
       new_metrics.detail,
       new_metrics.position
from new_metrics
where not exists (
  select 1
  from briefing_room.decision_metrics
  where decision_metrics.label = new_metrics.label
);

with new_notes (category, headline, summary, source, owner, priority, spotlight) as (
  values
    (
      'Scholar voice',
      'Timeline clarity still the #1 friction point',
      'Scholars want one definitive date range for verification. Add a simple progress bar to the portal and include it in SMS updates.',
      '14 interviews',
      'Scholar success',
      4,
      true
    ),
    (
      'Reviewer sentiment',
      'Calibration gaps widening after Round 2',
      'Two reviewers are scoring 22% higher than median. Schedule a 30-minute anchor review and lock shared scoring notes.',
      'Rubric audit',
      'Program ops',
      3,
      false
    ),
    (
      'Partner whisper',
      'Renewal hinges on impact storytelling',
      'Partners want the story arc earlier in the brief. Move the vignette into the exec recap and add a data callout.',
      'Partner syncs',
      'Partnerships',
      3,
      false
    ),
    (
      'Momentum cue',
      'Ambassadors want clearer weekly asks',
      'Ship a one-page playbook with social copy, event timing, and incentive FAQ by Wednesday to lift referrals.',
      'Ambassador check-in',
      'Growth',
      2,
      false
    )
)
insert into briefing_room.field_notes (category, headline, summary, source, owner, priority, spotlight)
select new_notes.category,
       new_notes.headline,
       new_notes.summary,
       new_notes.source,
       new_notes.owner,
       new_notes.priority,
       new_notes.spotlight
from new_notes
where not exists (
  select 1
  from briefing_room.field_notes
  where field_notes.headline = new_notes.headline
);
