-- Index the nullable created_by foreign key used for admin attribution lookups.
create index if not exists commercial_brands_created_by_idx
  on public.commercial_brands(created_by);
