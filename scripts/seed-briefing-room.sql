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

create table if not exists briefing_room.partner_updates (
  id serial primary key,
  partner_name text not null,
  status text not null,
  readiness_score int not null,
  renewal_date date,
  risk_level text not null,
  owner text not null,
  next_step text not null,
  summary text not null,
  updated_at timestamptz not null default now()
);

create table if not exists briefing_room.momentum_updates (
  id serial primary key,
  lane text not null,
  headline text not null,
  summary text not null,
  owner text not null,
  metric text not null,
  delta text not null,
  trend text not null,
  updated_at timestamptz not null default now()
);

create table if not exists briefing_room.escalation_watch (
  id serial primary key,
  category text not null,
  issue text not null,
  impact text not null,
  owner text not null,
  status text not null,
  eta date,
  severity text not null,
  created_at timestamptz not null default now()
);

create table if not exists briefing_room.action_items (
  id serial primary key,
  title text not null,
  summary text not null,
  owner text not null,
  status text not null,
  priority int not null default 2,
  lane text not null,
  due_date date,
  created_at timestamptz not null default now()
);

create table if not exists briefing_room.resource_requests (
  id serial primary key,
  request_type text not null,
  title text not null,
  justification text not null,
  owner text not null,
  status text not null,
  priority int not null default 2,
  needed_by date,
  impact text not null,
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

with new_actions (title, summary, owner, status, priority, lane, due_date) as (
  values
    (
      'Finalize scholarship timeline FAQ',
      'Align on a single verification window and update the FAQ + portal copy with the confirmed dates.',
      'Scholar success',
      'In progress',
      3,
      'Scholar comms',
      '2026-02-10'
    ),
    (
      'Lock partner renewal story pack',
      'Package three impact vignettes, a one-page metric recap, and the updated deck for Northwind Trust.',
      'Partnerships',
      'Blocked',
      4,
      'Renewal prep',
      '2026-02-12'
    ),
    (
      'Resolve award variance narrative',
      'Draft the variance explanation and confirm the updated figures with finance before the executive summary.',
      'Finance',
      'Queued',
      2,
      'Budget review',
      '2026-02-09'
    ),
    (
      'Schedule reviewer recalibration',
      'Book a 30-minute anchor session and distribute the shared scoring guidance to the Round 2 team.',
      'Program ops',
      'Queued',
      2,
      'Review readiness',
      '2026-02-11'
    ),
    (
      'Prepare cohort 3 outreach sweep',
      'Send the next reminder wave to scholars still missing verification documents, with SMS fallback.',
      'Support pod 2',
      'In progress',
      3,
      'Cohort outreach',
      '2026-02-08'
    ),
    (
      'Confirm ambassador incentive approval',
      'Finalize legal review and confirm incentive language before scaling the referral sprint.',
      'Growth',
      'Blocked',
      4,
      'Growth experiments',
      '2026-02-13'
    )
)
insert into briefing_room.action_items (title, summary, owner, status, priority, lane, due_date)
select new_actions.title,
       new_actions.summary,
       new_actions.owner,
       new_actions.status,
       new_actions.priority,
       new_actions.lane,
       new_actions.due_date::date
from new_actions
where not exists (
  select 1
  from briefing_room.action_items
  where action_items.title = new_actions.title
);

with new_requests (
  request_type,
  title,
  justification,
  owner,
  status,
  priority,
  needed_by,
  impact
) as (
  values
    (
      'Staffing',
      'Add two temp reviewers for Round 2',
      'Reviewer availability dropped by 18%. Temporary coverage prevents decision delays.',
      'Program ops',
      'Pending',
      4,
      '2026-02-12',
      'Keeps decisions on schedule for 120 scholars.'
    ),
    (
      'Product',
      'Portal timeline progress widget',
      'Scholar feedback shows verification timing confusion. Widget reduces inbound tickets.',
      'Scholar success',
      'In review',
      3,
      '2026-02-15',
      'Reduces support load and improves scholar confidence.'
    ),
    (
      'Partnerships',
      'Design sprint for renewal impact story',
      'Northwind renewal call requires refreshed visuals and a story arc.',
      'Partnerships',
      'Approved',
      3,
      '2026-02-18',
      'Boosts renewal confidence and accelerates signature timing.'
    ),
    (
      'Data',
      'Retention dashboard refresh',
      'Harborlight wants updated retention stats. Need refreshed survey ingestion.',
      'Data',
      'Pending',
      4,
      '2026-02-14',
      'Unlocks renewal reporting and risk mitigation messaging.'
    ),
    (
      'Finance',
      'Award variance reconciliation',
      'Late donor adjustments require a new variance narrative and corrected ledger.',
      'Finance',
      'Fulfilled',
      2,
      '2026-02-09',
      'Clears the exec brief for approval.'
    )
)
insert into briefing_room.resource_requests (
  request_type,
  title,
  justification,
  owner,
  status,
  priority,
  needed_by,
  impact
)
select new_requests.request_type,
       new_requests.title,
       new_requests.justification,
       new_requests.owner,
       new_requests.status,
       new_requests.priority,
       new_requests.needed_by::date,
       new_requests.impact
from new_requests
where not exists (
  select 1
  from briefing_room.resource_requests
  where resource_requests.title = new_requests.title
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

with new_updates (
  partner_name,
  status,
  readiness_score,
  renewal_date,
  risk_level,
  owner,
  next_step,
  summary
) as (
  values
    (
      'Northwind Trust',
      'Deck review',
      82,
      '2026-03-05',
      'Medium',
      'Partnerships',
      'Send final impact vignette set',
      'Impact story arc ready; waiting on refreshed outcome slide before renewal call.'
    ),
    (
      'Harborlight Foundation',
      'Data pull',
      74,
      '2026-02-26',
      'High',
      'Data',
      'Confirm scholar retention stats',
      'Retention snapshot pending due to late survey data. Needs an interim estimate.'
    ),
    (
      'Juniper Giving Circle',
      'Stakeholder sync',
      88,
      '2026-04-12',
      'Low',
      'Partnerships',
      'Align renewal narrative lane',
      'Renewal call scheduled; focus is on scholar spotlight and new regional expansion.'
    ),
    (
      'Marigold Education Fund',
      'Budget alignment',
      67,
      '2026-03-18',
      'High',
      'Finance',
      'Share funding delta breakdown',
      'Budget delta needs explanation and timeline for corrective disbursement.'
    ),
    (
      'Cedar Grove Partners',
      'Warm-up outreach',
      91,
      '2026-05-01',
      'Low',
      'Leadership',
      'Draft exec thank-you note',
      'Early signals are positive; prep an executive thank-you note with new outcomes.'
    )
)
insert into briefing_room.partner_updates (
  partner_name,
  status,
  readiness_score,
  renewal_date,
  risk_level,
  owner,
  next_step,
  summary
)
select new_updates.partner_name,
       new_updates.status,
       new_updates.readiness_score,
       new_updates.renewal_date::date,
       new_updates.risk_level,
       new_updates.owner,
       new_updates.next_step,
       new_updates.summary
from new_updates
where not exists (
  select 1
  from briefing_room.partner_updates
  where partner_updates.partner_name = new_updates.partner_name
);

with new_momentum (
  lane,
  headline,
  summary,
  owner,
  metric,
  delta,
  trend
) as (
  values
    (
      'Applications',
      'Midwest surge lifting weekly intake',
      'Chicago + Detroit referrals drove a 12% week-over-week lift. Replicate outreach kit for St. Louis by Tuesday.',
      'Growth',
      '1,482 applications',
      '+12%',
      'Up'
    ),
    (
      'Verification',
      'Backlog clearing faster than forecast',
      'Support pod 2 cleared 7 cases and reduced the queue to 11. Hold the second touch cadence through Thursday.',
      'Scholar success',
      '78% verified',
      '+6%',
      'Up'
    ),
    (
      'Funding',
      'Award variance still above target',
      'Late donor adjustments left a 4% variance. Finance is preparing a correction note for leadership.',
      'Finance',
      '4% variance',
      '-2%',
      'Down'
    ),
    (
      'Engagement',
      'Scholar response rate leveling off',
      'SMS response is holding steady after the last reminder sequence. Consider a new subject line test.',
      'Comms',
      '61% response rate',
      '0%',
      'Flat'
    ),
    (
      'Partner readiness',
      'Renewal deck readiness climbing',
      'Northwind impact deck is 90% complete; waiting on final vignette design.',
      'Partnerships',
      '90% ready',
      '+8%',
      'Up'
    )
)
insert into briefing_room.momentum_updates (
  lane,
  headline,
  summary,
  owner,
  metric,
  delta,
  trend
)
select new_momentum.lane,
       new_momentum.headline,
       new_momentum.summary,
       new_momentum.owner,
       new_momentum.metric,
       new_momentum.delta,
       new_momentum.trend
from new_momentum
where not exists (
  select 1
  from briefing_room.momentum_updates
  where momentum_updates.headline = new_momentum.headline
);

with new_escalations (
  category,
  issue,
  impact,
  owner,
  status,
  eta,
  severity
) as (
  values
    (
      'Compliance',
      'Consent forms missing for 12 scholars',
      'Awards cannot be released until guardian consent is verified for the remaining cases.',
      'Scholar success',
      'Open',
      '2026-02-10',
      'Critical'
    ),
    (
      'Finance',
      'Budget variance approval needed',
      'Leadership sign-off required to reallocate 4% of unused grant funds to cover award overage.',
      'Finance',
      'Pending',
      '2026-02-12',
      'High'
    ),
    (
      'Partnerships',
      'Northwind renewal narrative gap',
      'Renewal deck missing the Q4 outcomes vignette; partner may delay signature without it.',
      'Partnerships',
      'Open',
      '2026-02-11',
      'High'
    ),
    (
      'Operations',
      'Reviewer staffing shortfall',
      'Two reviewers are out this week; coverage gap could delay Round 2 decisions.',
      'Program ops',
      'Pending',
      '2026-02-13',
      'Moderate'
    ),
    (
      'Product',
      'Portal verification banner regression',
      'New progress banner is not rendering for Android users; support tickets rising.',
      'Product',
      'Resolved',
      '2026-02-08',
      'Moderate'
    )
)
insert into briefing_room.escalation_watch (
  category,
  issue,
  impact,
  owner,
  status,
  eta,
  severity
)
select new_escalations.category,
       new_escalations.issue,
       new_escalations.impact,
       new_escalations.owner,
       new_escalations.status,
       new_escalations.eta::date,
       new_escalations.severity
from new_escalations
where not exists (
  select 1
  from briefing_room.escalation_watch
  where escalation_watch.issue = new_escalations.issue
);
