# JIB Moroccan Culinary Knowledge Library

## Purpose

This is a small, curated, code-owned reference library used by JIB AI Manager to tell the image model what a named Moroccan dish actually looks like. It is not a general-purpose recipe scraper and does not copy proprietary recipe text or image collections.

## Current profiles

The implementation lives in `apps/admin/lib/ai/moroccan-dishes.ts` and currently defines visual profiles and exclusions for:

- Moroccan/French tacos sandwich
- Moroccan tajine
- Moroccan couscous
- Moroccan pastilla
- Moroccan harira
- Moroccan rfissa
- Marrakech tanjia
- Msemen/rghaif
- Chebakia
- Zaalouk
- Bissara
- Briouats
- Maakouda
- Seffa

Each profile includes Arabic/French/English aliases, a positive visual definition and explicit exclusions to prevent common regional-dish substitutions.

## Prompt safety and accuracy

- Match both the product title and its supplied description.
- Put the dish-specific definition before generic photography instructions so it is not truncated first.
- Use only the ingredients and preparation details supplied by the merchant.
- For tajine, show the prepared food inside a recognizable Moroccan tagine vessel; do not substitute a room, chef, cook, or preparation scene.
- For Moroccan/French tacos, show a sealed, pressed, toasted rectangular tortilla sandwich, never Mexican open-shell tacos.
- Keep every generated image as a draft until human approval.
- A successful model response does not mean the dish is visually correct; rejected images must remain unpublished.

## Free-source and licensing policy

The initial profiles are concise editorial descriptions written for JIB. Future enrichment may use public/free sources only after checking each source's license and commercial-use terms.

Approved source candidates, subject to per-dataset review:

- Wikidata structured facts under CC0.
- USDA FoodData Central nutrient data under CC0 where relevant.
- Open Food Facts product/ingredient data under ODbL, preserving attribution and database obligations.
- Wikimedia Commons images only when the individual file license permits JIB's intended commercial reuse, with creator, source, license and attribution retained.

Do not bulk-copy recipes, scrape sites that prohibit it, or assume that an open-source software license also licenses the content hosted by that software. Do not use an image unless its individual rights are recorded. Prefer merchant-owned photos and human-reviewed original generated images.

## Cost policy

- Do not add a paid AI provider, paid vision API, paid dataset, subscription, or billing upgrade.
- Keep Cloudflare Workers AI on the existing Free plan and stop generation when the free daily allocation is exhausted.
- Open data does not mean unlimited free hosting or API access; cache only where the source terms permit it and respect rate limits.
