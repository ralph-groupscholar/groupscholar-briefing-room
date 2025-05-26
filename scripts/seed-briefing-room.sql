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

insert into briefing_room.signal_entries (title, summary, owner, urgency, target_date, source)
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
  );
